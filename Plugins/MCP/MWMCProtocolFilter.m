/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWMCProtocolFilter.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWConfigPane.h>
#import "MWMCP.h"
#import "MWMCPMessage.h"
#import "MWMCPPackage.h"
#import "MWMCPPackages.h"
#import "MWMCPConfigPane.h"
#import "MWRemoteTextHolder.h"

static NSString *MCPLineOOB = @"#$#";
static NSString *MCPLineInitiate = @"#$#mcp ";
static NSString *MCPLineEscaped = @"#$\"";

// In the package registry, keys are package names and objects are package classes
static NSMutableDictionary *packageRegistry;

@interface MWMCProtocolFilter (Private)

+ (void)registerBuiltinPackages;

@end

static NSCharacterSet *identChars, *alphaChars, *simpleChars, *spaceChars;

@implementation MWMCProtocolFilter

+ (void)initialize {
  if (!identChars) {
    identChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"] retain];
    alphaChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"] retain];
    simpleChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-~`!@#$%^&()=+{}[]|';?/><.,"] retain];
    spaceChars = [[NSCharacterSet characterSetWithCharactersInString:@" "] retain];

    packageRegistry = [[NSMutableDictionary alloc] init];
  
    [self registerBuiltinPackages];
  }
}

+ (void)registerBuiltinPackages {
  [self registerPackage:[MWMCP_mcp class]];
  [self registerPackage:[MWMCP_mcp_negotiate class]];
  [self registerPackage:[MWMCP_mcp_cord class]];
  [self registerPackage:[MWMCP_dns_com_awns_displayurl class]];
  [self registerPackage:[MWMCP_dns_com_awns_jtext class]];
  [self registerPackage:[MWMCP_dns_com_awns_ping class]];
  [self registerPackage:[MWMCP_dns_com_awns_rehash class]];
  [self registerPackage:[MWMCP_dns_com_awns_serverinfo class]];
  [self registerPackage:[MWMCP_dns_com_awns_status class]];
  [self registerPackage:[MWMCP_dns_com_awns_timezone class]];
  [self registerPackage:[MWMCP_dns_com_awns_visual class]];
  [self registerPackage:[MWMCP_dns_org_cubik_prompt class]];
  [self registerPackage:[MWMCP_dns_org_mud_moo_simpleedit class]];
  [self registerPackage:[MWMCP_dns_com_att_research_twin_window class]];
}

// --- Plugin principal class ---

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  // this is a filter plugin. we should register our filter class for inclusion but there's no API for that yet. FIXME
  [[MWRegistry defaultRegistry] registerCapability:@"MWRemoteTextHolder" qualifiers:nil handler:[MWRemoteTextHolder class]];

  MWConfigTree *dc = [[MWRegistry defaultRegistry] defaultConfig];
  [dc setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponent:@"MCPEnabled"]];
  [dc setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponent:@"MCPMapWindowEnabled"]];
  [dc setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponent:@"ConfirmServerURLOpenRequests"]];

  [registry registerUserInterfaceCommand:MWLocalizedStringHere(@"MWMCPMappingWindowOpen") context:@"global" handler:[MWMCP_dns_com_awns_visual class] performSelector:@selector(genericOpenMapWindow:)];

  if ([registry respondsToSelector:@selector(registerPreferencePane:forScope:)])
    [registry registerPreferencePane:[MWMCPConfigPane class] forScope:MWConfigScopeAll];
}

// --- MCP registry ---

+ (void)registerPackage:(Class)package {
  [packageRegistry setObject:package forKey:[package packageName]];
}

+ (NSMutableDictionary *)packageRegistry { return packageRegistry; }

// --- Instances ---

- (MWMCProtocolFilter *)init {
  if (!(self = (MWMCProtocolFilter *)[super init])) return nil;

  packages = [[NSMutableDictionary alloc] init];
  messages = [[NSMutableDictionary alloc] init];
  multilineMessageState = [[NSMutableDictionary alloc] init];

  return self;
}

- (void)dealloc {
  NSEnumerator *packE = [packages objectEnumerator];
  MWMCPPackage *pack;
  while ((pack = [packE nextObject])) {
    [pack owningFilterDroppedPackage];
  }

  [trueAuthKey autorelease]; trueAuthKey = nil;
  [packages autorelease]; packages = nil;
  [messages autorelease]; messages = nil;
  [multilineMessageState autorelease]; multilineMessageState = nil;
  [super dealloc];
}

- (BOOL)mcpIsActive {
  return !!trueAuthKey; // NOTE: this will need to be changed if the notion of MCP-without-auth-key is supported
}

- (void)processMCPMessage:(NSString *)msg args:(NSDictionary *)args {
  if ([msg isEqualToString:@"mcp"]) {
    [self addPackage:[MWMCP_mcp class]]; // explicitly not started. we'll use startPackage for the MCP *server* hook.
  }
  
  {
    MWMCPPackage *package = [messages objectForKey:msg];
    
    [self linkableTraceMessage:[NSString stringWithFormat:@"Recv: '%@' %@\n", msg, args]];
    if (package) {
      [package handleIncomingMessage:[MWMCPMessage messageWithName:msg arguments:args]];
    } else {
      [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown MCP message '%@'\n", msg]];
    }
  }
}

- (void)sendMCPMessage:(NSString *)name args:(NSDictionary *)args {
  [self sendMCPMessage:[MWMCPMessage messageWithName:name arguments:args]];
}
- (void)sendMCPMessage:(MWMCPMessage *)msg {
  if ([self mcpIsActive]) {
    NSArray *lines = [msg linesForSendingWithAuthenticationKey:trueAuthKey];
    NSEnumerator *lineE = [lines objectEnumerator];
    NSString *line;
    while ((line = [lineE nextObject])) {
      [self linkableTraceMessage:[NSString stringWithFormat:@"Send: %@\n", line]];
      [self send:[MWLineString lineStringWithString:line role:nil] toLinkFor:@"outward"];
    }
  } else {
    [self linkableErrorMessage:[NSString stringWithFormat:@"Attempted to send MCP message %@ but MCP support has not been indicated by the peer\n", msg]];
  }
}

- (void)processOOBLine:(NSString *)str {
  NSScanner *scan = [NSScanner scannerWithString:str];
  [scan mwSetCharactersToBeSkippedToEmptySet];
  
  // Relevant sections of the MCP grammar are referenced in comments.

  if ([scan scanString:@"*" intoString:nil]) {
    // <message-continue>
    NSString *dataTag = nil, *multiKey = nil, *multiValue = nil;

    if (!(
       [scan scanCharactersFromSet:spaceChars intoString:nil]
    && [scan scanCharactersFromSet:simpleChars intoString:&dataTag]
    && [scan scanCharactersFromSet:spaceChars intoString:nil]
    && [scan scanCharactersFromSet:simpleChars intoString:&multiKey]
    && [scan scanString:@": " intoString:nil]
    )) goto MALFORMED;
    multiKey = [multiKey lowercaseString];
    multiValue = [str substringFromIndex:[scan scanLocation]];
    
    { NSDictionary *msgInfo = [multilineMessageState objectForKey:dataTag];
      NSMutableArray *multiBuffer = [[msgInfo objectForKey:@"args"] objectForKey:multiKey];
      if (!msgInfo) {
        [self linkableTraceMessage:[NSString stringWithFormat:@"Multiline message continue with unrecognized data-tag '%@'\n", dataTag]];
        return;
      }
      if (!multiBuffer) {
        [self linkableTraceMessage:[NSString stringWithFormat:@"Multiline message continue with unrecognized keyword '%@'\n", multiKey]];
        return;
      }
      if (![multiBuffer isKindOfClass:[NSMutableArray class]]) {
        [self linkableTraceMessage:[NSString stringWithFormat:@"Multiline message continue with non-multiline keyword '%@'\n", multiKey]];
        return;
      }
      [multiBuffer addObject:multiValue];
    }
  } else if ([scan scanString:@":" intoString:nil]) {
    // <message-end>
    NSString *dataTag = nil;
    NSDictionary *msgInfo;

    if (!(
       [scan scanCharactersFromSet:spaceChars intoString:nil]
    && [scan scanCharactersFromSet:simpleChars intoString:&dataTag]
    && [scan isAtEnd]
    )) goto MALFORMED;
    
    if ((msgInfo = [multilineMessageState objectForKey:dataTag])) {
      [[msgInfo objectForKey:@"args"] removeObjectForKey:@"_data-tag"];
      [self processMCPMessage:[msgInfo objectForKey:@"name"] args:[msgInfo objectForKey:@"args"]];
    } else {
      [self linkableTraceMessage:[NSString stringWithFormat:@"Multiline message end with unrecognized data-tag '%@'\n", dataTag]];
    }
  } else {
    // <message-start>
    NSString *message_name = nil, *auth_key = nil;
    NSMutableDictionary *msgDict = [NSMutableDictionary dictionary];
    BOOL hasMultiline = NO;
    if (!(
       [scan scanCharactersFromSet:identChars intoString:&message_name] 
    && [alphaChars characterIsMember:[message_name characterAtIndex:0]]
    )) goto MALFORMED;
    
    message_name = [message_name lowercaseString];
    
    if (![message_name isEqual:@"mcp"] && !(
       [scan scanCharactersFromSet:spaceChars intoString:NULL]
    && [scan scanCharactersFromSet:simpleChars intoString:&auth_key]
    )) goto MALFORMED; // dependent on mcp-with-auth-key
    
    while (![scan isAtEnd]) {
      NSString *key = nil; NSString *value = nil; BOOL multiline;
      if (!(
         [scan scanCharactersFromSet:spaceChars intoString:NULL]
      && [scan scanCharactersFromSet:identChars intoString:&key]
      )) goto MALFORMED;
      key = [key lowercaseString];
      
      if ([msgDict objectForKey:key])
        // malformed - duplicate keys
        goto MALFORMED;
      
      if ((multiline = [scan scanString:@"*" intoString:nil])) hasMultiline = YES;
      if (!(
         [scan scanString:@":" intoString:NULL]
      && [scan scanCharactersFromSet:spaceChars intoString:NULL]
      )) goto MALFORMED;
      if ([scan scanString:@"\"" intoString:NULL]) {
        // <quoted-string>
        if (![scan mwScanBackslashEscapedStringUpToCharacter:'"' intoString:&value]) goto MALFORMED;
        [scan scanString:@"\"" intoString:NULL]; // can't fail
      } else {
        // <unquoted-string>
        if (![scan scanCharactersFromSet:simpleChars intoString:&value]) goto MALFORMED;
      }
      
      // it is said that some implementations provide the anticipated number of lines as the otherwise unused single-line-value field
      [msgDict setObject:(multiline ? [NSMutableArray arrayWithCapacity:[value intValue]] : value) forKey:key];
    }
    // end of parsing
    
    if (![auth_key isEqual:trueAuthKey] && ![message_name isEqual:@"mcp"]) {
      [self linkableTraceMessage:[NSString stringWithFormat:@"Invalid authentication key %@\n", auth_key]];
      return;
    }
    
    if (hasMultiline) {
      NSString *dataTag = [msgDict objectForKey:@"_data-tag"];
      if (!dataTag) {
        [self linkableTraceMessage:[NSString stringWithFormat:@"Multiline message with no _data-tag key\n"]];
        return;
      }
      [multilineMessageState setObject:[NSDictionary dictionaryWithObjectsAndKeys:
        message_name, @"name",
        msgDict, @"args",
        nil
      ] forKey:dataTag];
    } else {
      [self processMCPMessage:message_name args:msgDict];
    }
  }
  return;
  
  MALFORMED:
  [self linkableTraceMessage:[NSString stringWithFormat:@"** / %@\n", str]];
  [self linkableTraceMessage:[NSString stringWithFormat:[NSString stringWithFormat:@"** | %%%ui\n", [scan scanLocation] - 1], 0]];
  [self linkableTraceMessage:[NSString stringWithFormat:@"** \\ Malformed MCP message at character %u\n", [scan scanLocation]]];
}

// --- Linkage ---

- (void)resetConnectionState {
  { NSEnumerator *packE = [packages objectEnumerator];
    MWMCPPackage *pack;
    while ((pack = [packE nextObject])) {
      [pack owningFilterDroppedPackage];
    }
  }

  [self setTrueAuthKey:nil];
  [packages removeAllObjects];
  [messages removeAllObjects];
  [multilineMessageState removeAllObjects];
}

- (NSSet *)linkNames {
  // CORD HOOK
  NSMutableSet *linkNames = [NSMutableSet setWithSet:[super linkNames]];
  if ([packages objectForKey:@"mcp-cord"])
    [linkNames unionSet:[[packages objectForKey:@"mcp-cord"] openCords]];
  return linkNames;
}

- (void)unregisterLinkFor:(NSString *)linkName {
  [super unregisterLinkFor:linkName];
  // CORD HOOK
  if ([[[packages objectForKey:@"mcp-cord"] openCords] containsObject:linkName])
    [[packages objectForKey:@"mcp-cord"] cordLinkWasClosed:linkName];
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    BOOL isAttr = NO, isLS = NO;
  
    if ((isLS = [obj isKindOfClass:[MWLineString class]]) || (isAttr = [obj isKindOfClass:[NSAttributedString class]]) || [obj isKindOfClass:[NSString class]]) {
      NSString *toTest = (isAttr || isLS) ? [obj string] : obj;
      if (!isLS) [self linkableErrorMessage:@"Warning: MWMCProtocolFilter received NS[Attributed]String from outward, not currently correctly supported."];
      if ([toTest hasPrefix:MCPLineOOB] && ([self mcpIsActive] || ([toTest hasPrefix:MCPLineInitiate] && [[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"MCPEnabled"]] intValue]))) {
        [self processOOBLine:[toTest substringFromIndex:[MCPLineOOB length]]];
      } else if ([toTest hasPrefix:MCPLineEscaped] && [self mcpIsActive]) {
        if (isAttr)
          [self send:[obj attributedSubstringFromRange:MWMakeABRange([MCPLineEscaped length], [(NSAttributedString *)obj length])] toLinkFor:@"inward"];
        else if (isLS)
          [self send:[MWLineString lineStringWithString:[toTest substringFromIndex:[MCPLineEscaped length]] role:[obj role]] toLinkFor:@"inward"];
        else
          [self send:[obj substringFromIndex:[MCPLineEscaped length]] toLinkFor:@"inward"];
      } else {
        [self send:obj toLinkFor:@"inward"];
      }
      
    } else if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenConnectionClosed]) {
        // NOTE: possible reentrancy issue here?
        [self resetConnectionState];
        [self send:obj toLinkFor:@"inward"];
      } else {
        [self send:obj toLinkFor:@"inward"];
      }
    } else {
      [self send:obj toLinkFor:@"inward"];
    }
    return YES;
  } else if ([link isEqual:@"inward"]) {
    BOOL isAttr;
    NSString *role = nil;
    if ([obj isKindOfClass:[MWLineString class]]) {
      role = [obj role];
      obj = [obj attributedString];
    }
    if ((isAttr = [obj isKindOfClass:[NSAttributedString class]]) || [obj isKindOfClass:[NSString class]]) {
      NSString *toTest = isAttr ? [obj string] : obj;
      if (([toTest hasPrefix:MCPLineOOB] || [toTest hasPrefix:MCPLineEscaped]) && [self mcpIsActive]) {
        if (isAttr) {
          NSMutableAttributedString *s = [[[NSMutableAttributedString alloc] initWithString:MCPLineEscaped attributes:[(NSAttributedString *)obj attributesAtIndex:0 effectiveRange:NULL]] autorelease];
          [s appendAttributedString:obj];
          [self send:[MWLineString lineStringWithAttributedString:s role:role] toLinkFor:@"outward"];
        } else {
          [self send:[MWLineString lineStringWithString:[MCPLineEscaped stringByAppendingString:obj] role:role] toLinkFor:@"outward"];
        }
      } else {
        if (isAttr) [self send:[MWLineString lineStringWithAttributedString:obj role:role] toLinkFor:@"outward"];
               else [self send:[MWLineString lineStringWithString:obj role:role] toLinkFor:@"outward"];
      }
    } else if ([obj isKindOfClass:[MWMCPMessage class]]) {
      [self sendMCPMessage:obj];
      
    } else if ([obj isKindOfClass:[MWToken class]]) {
      // PING HOOK
      // FIXME: use new generic hook mechanism below instead of this special case, but first write a unit test
      if ([obj isEqual:MWTokenPingSend] && [[self mcpPackages] objectForKey:@"dns-com-awns-ping"]) {
        static unsigned int pingSerial;
        [self sendMCPMessage:@"dns-com-awns-ping" args:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%u", pingSerial] forKey:@"id"]];
      } else {
        BOOL handled = NO;
        MWenumerate([packages objectEnumerator], MWMCPPackage *, package) {
          if ([package handleOutgoing:obj alreadyHandled:handled])
            handled = YES;
        }
        if (!handled) {
          [self send:obj toLinkFor:@"outward"];
        }
      }
    } else {
      [self send:obj toLinkFor:@"outward"];
    }
    return YES;
  } else if ([[[packages objectForKey:@"mcp-cord"] openCords] containsObject:link]) {
    // CORD HOOK
    NSMutableDictionary *mcpArgs = [NSMutableDictionary dictionaryWithDictionary:obj];
    [mcpArgs setObject:link forKey:@"_id"];
    [mcpArgs setObject:[(MWMCPMessage *)obj messageName] forKey:@"_message"];
    [self sendMCPMessage:@"mcp-cord" args:mcpArgs];
    return YES;
  } else {
    return NO;
  }
}

// --- Packages ---

- (MWMCPPackage *)addPackage:(Class)packageClass {
  MWMCPPackage *pack = [[[packageClass alloc] initWithFilter:self] autorelease];
  NSString *packageName = [pack packageName];
  NSEnumerator *msgE = [[pack incomingMessages] objectEnumerator];
  NSString *msg;
  
  [packages setObject:pack forKey:packageName];
  
  while ((msg = [msgE nextObject])) {
    NSString *fullName = [msg length] ? [NSString stringWithFormat:@"%@-%@", packageName, msg] : packageName;
    MWMCPPackage *prevPack = [messages objectForKey:fullName];
    
    if (prevPack && ![[prevPack packageName] isEqual:packageName])
      // NOTE: doesn't warn if replacing a package with itself (possibly different version)
      // fixme: when replacing a package with itself ought to have a way for state to be passed to the new package
      [self linkableErrorMessage:[NSString stringWithFormat:@"Conflict: package %@ has claimed message %@ previously handled by package %@\n", pack, fullName, prevPack]];
    
    [messages setObject:pack forKey:fullName];
  }
  return pack;
}

// --- Accessors ---

- (NSDictionary *)mcpPackages { return packages; }
- (NSString *)trueAuthKey { return trueAuthKey; }

- (void)setTrueAuthKey:(NSString *)key {
  [trueAuthKey autorelease];
  trueAuthKey = [key retain];
}

@end