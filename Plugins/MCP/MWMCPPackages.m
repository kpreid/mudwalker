/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWMCPPackages.h"

#import "MWMCP.h"
#import "MWMCProtocolFilter.h"
#import "MWMCPMessage.h"
#import "MWRemoteTextHolder.h"
#import "MWMCPMappingWinController.h"
#import <MWAppKit/MWGraphView.h>
#import <MWAppKit/MWURLLaunchRequest.h>

// fixme: inappropriate dependency
#import "MWConnectionDocument.h"
#import "MWOutputWinController.h"

@implementation MWMCP_mcp

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"2.1"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"2.1"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", nil]; }

- (BOOL)participatesInVersionNegotiation { return NO; }

- (void)handleMessage_:(NSDictionary *)args {
  MWMCPVersion *theirMin = [MWMCPVersion versionWithString:[args objectForKey:@"version"]],
               *theirMax = [MWMCPVersion versionWithString:[args objectForKey:@"to"]],
               *ourMin = [[self class] minVersion],
               *ourMax = [[self class] maxVersion];
  
  if ([theirMin compare:ourMax] != NSOrderedAscending && [theirMax compare:ourMin] != NSOrderedDescending) {
    // we'll need to compute version to use if we support multiple protocol versions
  
    [[self owningFilter] setTrueAuthKey:[NSString stringWithFormat:@"%lu", random()]];
    
    // NOTE: this doesn't go through the normal send path because it would, depending on order of operations, either discard the message because MCP support is not yet active or include the authkey as the second word
    {
      MWMCPMessage *msg = [MWMCPMessage messageWithName:@"mcp" arguments:[NSDictionary dictionaryWithObjectsAndKeys:
        [[self owningFilter] trueAuthKey], @"authentication-key",
        [[[self class] minVersion] description], @"version",
        [[[self class] maxVersion] description], @"to",
        nil
      ]];
      NSArray *lines = [msg linesForSendingWithAuthenticationKey:nil];
      NSAssert([lines count] == 1, @"#$#mcp message failed to be generated as single line");
      [[self owningFilter] send:[MWLineString lineStringWithString:[lines objectAtIndex:0] role:nil] toLinkFor:@"outward"];
    }
    
    [[[self owningFilter] addPackage:[MWMCP_mcp_negotiate class]] startPackage];
  } else {
    [[self owningFilter] linkableErrorMessage:[NSString stringWithFormat:@"mcp protocol: no common version: our %@-%@ their %@-%@", ourMin, ourMax, theirMin, theirMax]];
  }
}

@end

@implementation MWMCP_mcp_negotiate

// always present

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"2.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"2.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"can", @"end", nil]; }

- (BOOL)participatesInVersionNegotiation { return NO; }

- (void)startPackage {
  NSEnumerator *packageNameE = [[MWMCProtocolFilter packageRegistry] keyEnumerator];
  NSString *packageName;
  
  while ((packageName = [packageNameE nextObject])) {
    Class packageClass = [[MWMCProtocolFilter packageRegistry] objectForKey:packageName];
    
    if ([packageName isEqual:@"mcp"])
      continue;
      
    [self sendMCPMessage:@"mcp-negotiate-can" args:[NSDictionary dictionaryWithObjectsAndKeys:
      packageName, @"package",
      [[packageClass minVersion] description], @"max-version",
      [[packageClass maxVersion] description], @"min-version", 
      nil
    ]];
  }
  
  [self sendMCPMessage:@"mcp-negotiate-end" args:nil];
}

- (void)handleMessage_can:(NSDictionary *)args {
  NSString *packageName = [args objectForKey:@"package"];
  Class myPackageClass = [[MWMCProtocolFilter packageRegistry] objectForKey:packageName];
  
  if (!packageName) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"mcp-negotiate-can without 'package' key\n"]];
    return;
  }
  
  {
    MWMCPVersion *theirMin = [MWMCPVersion versionWithString:[args objectForKey:@"min-version"]];
    MWMCPVersion *theirMax = [MWMCPVersion versionWithString:[args objectForKey:@"max-version"]];
    MWMCPVersion *ourMin = [myPackageClass minVersion];
    MWMCPVersion *ourMax = [myPackageClass maxVersion];
    MWMCPVersion *useVers = nil;
    
    if (!myPackageClass) {
      [[self owningFilter] linkableTraceMessage:[NSString stringWithFormat:@"mcp-negotiate: unsupported package '%@'\n", packageName]];
      return;
    }
    
    useVers = [MWMCPVersion bestVersionInRangeAMin:theirMin aMax:theirMax bMin:ourMin bMax:ourMax];
    
    if (useVers) {
      [[self owningFilter] linkableTraceMessage:[NSString stringWithFormat:@"mcp-negotiate: negotiated %@ v%@\n", packageName, useVers]];
      [[self owningFilter] addPackage:[myPackageClass classForPackageVersion:useVers]];
    } else {
      [[self owningFilter] linkableErrorMessage:[NSString stringWithFormat:@"mcp-negotiate: no common version: %@ (our %@-%@ their %@-%@)\n", packageName, ourMin, ourMax, theirMin, theirMax]];
    }
  }
}

- (void)handleMessage_end:(NSDictionary *)args {
  if (gotNegotiateEnd) {
    [[self owningFilter] linkableErrorMessage:@"Duplicate mcp-negotiate-end message"];
  } else {
    NSEnumerator *packE = [[[self owningFilter] mcpPackages] objectEnumerator];
    MWMCPPackage *package;
    while ((package = [packE nextObject])) {
      if (![package participatesInVersionNegotiation])
        continue;
      [package startPackage];
    }
    gotNegotiateEnd = YES;
  }
}

@end

@implementation MWMCP_mcp_cord

- (id)init {
  if (!(self = [super init])) return nil;

  openCords = [[NSMutableSet alloc] init];
  cordTypeRegistry = [[NSMutableDictionary alloc] init];

  return self;  
}

- (void)dealloc {
  [openCords autorelease]; openCords = nil;
  [cordTypeRegistry autorelease]; cordTypeRegistry = nil;
  [super dealloc];
}

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"open", @"", @"closed", nil]; }

- (void)handleMessage_open:(NSDictionary *)args {
  NSString *cordID    = [args objectForKey:@"_id"];
  NSString *cordType  = [args objectForKey:@"_type"];
  Class    class      = [cordTypeRegistry objectForKey:cordType];
  id<MWLinkable>handler= [[[class alloc] init] autorelease];
  
  if (!class) {
    [[self owningFilter] linkableErrorMessage:[NSString stringWithFormat:@"No class registered to handle MCP cord type '%@'\n", cordType]];
    return;
  }
  if (!handler) {
    [[self owningFilter] linkableErrorMessage:[NSString stringWithFormat:@"Could not create cord handler object of class '%@'\n", [class description]]];
    return;
  }
  
  [handler setConfig:[[self owningFilter] config]];
  
  [openCords addObject:cordID];
  [[self owningFilter] link:cordID to:@"outward" of:handler];
  [[self owningFilter] send:MWTokenConnectionOpened toLinkFor:cordID];
}

- (void)handleMessage_:(NSDictionary *)args {
  [[self owningFilter] send:[MWMCPMessage messageWithName:[args objectForKey:@"_message"] arguments:args] toLinkFor:[args objectForKey:@"_id"]];
}

- (void)handleMessage_closed:(NSDictionary *)args {
  NSString *cordID = [args objectForKey:@"_id"];
  [[self owningFilter] unlink:cordID];
  [openCords removeObject:cordID];
}

- (void)owningFilterDroppedPackage {
  NSEnumerator *cordE = [[[openCords copy] autorelease] objectEnumerator];
  NSString *cord;
    
  while ((cord = [cordE nextObject])) {
    [[self owningFilter] unlink:cord];
  }
  [super owningFilterDroppedPackage];
}

- (NSSet *)openCords { return openCords; }

- (void)cordLinkWasClosed:(NSString *)linkName {
  [self sendMCPMessage:@"mcp-cord-closed" args:[NSDictionary dictionaryWithObject:linkName forKey:@"_id"]];
  [openCords removeObject:linkName];
}

- (void)registerCordType:(NSString *)type handlerClass:(Class)class {
  [cordTypeRegistry setObject:class forKey:type];
}


@end

@implementation MWMCP_dns_com_awns_displayurl

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", nil]; }

- (void)handleMessage_:(NSDictionary *)args {
  NSURL *const url = [NSURL URLWithString:[args objectForKey:@"url"]];

  if ([[[[self owningFilter] config] objectAtPath:[MWConfigPath pathWithComponent:@"ConfirmServerURLOpenRequests"]] intValue])
    [[MWURLLaunchRequest requestWindowWithURL:url] showWindow:nil];
  else
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end

@implementation MWMCP_dns_com_awns_jtext

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet set]; }

@end

@implementation MWMCP_dns_com_awns_ping

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", @"reply", nil]; }

- (void)handleMessage_:(NSDictionary *)args {
  [self sendMCPMessage:@"dns-com-awns-ping-reply" args:args];
}

- (void)handleMessage_reply:(NSDictionary *)args {
  [[self owningFilter] send:MWTokenPingBack toLinkFor:@"inward"];
}

@end

@implementation MWMCP_dns_com_awns_rehash 

- (id)init {
  if (!(self = [super init])) return nil;

  rehashSet = [[NSMutableSet alloc] init];

  return self;  
}

- (void)dealloc {
  [rehashSet autorelease]; rehashSet = nil;
  [super dealloc];
}

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"commands", @"add", @"remove", nil]; }

- (void)startPackage {
  [self sendMCPMessage:@"dns-com-awns-rehash-getcommands" args:nil];
}

- (void)handleMessage_commands:(NSDictionary *)args {
  [rehashSet setSet:[NSSet setWithArray:[[args objectForKey:@"list"] componentsSeparatedByString:@" "]]];
}

- (void)handleMessage_add:(NSDictionary *)args {
  [rehashSet unionSet:[NSSet setWithArray:[[args objectForKey:@"list"] componentsSeparatedByString:@" "]]];
}

- (void)handleMessage_remove:(NSDictionary *)args {
  [rehashSet minusSet:[NSSet setWithArray:[[args objectForKey:@"list"] componentsSeparatedByString:@" "]]];
}

- (NSSet *)rehashSet { return rehashSet; }

@end

@implementation MWMCProtocolFilter (MWMCP_dns_com_awns_rehash)

- (id)lpCompletionSet:(NSString *)link {
  return [[[self mcpPackages] objectForKey:@"dns-com-awns-rehash"] rehashSet];
}

@end

@implementation MWMCP_dns_com_awns_serverinfo

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", nil]; }

- (void)startPackage {
  [self sendMCPMessage:@"dns-com-awns-serverinfo-get" args:nil];
}

- (void)handleMessage_:(NSDictionary *)args {
  MWConfigTree *const config = [(MWConnectionDocument *)[[self owningFilter] probe:@selector(lpDocument:) ofLinkFor:@"inward"] configLocalStore];
  
  if (config) {
    MWConfigPath *path;
    NSString *str;
    NSURL *url;
    
    [config addDirectoryAtPath:[MWConfigPath pathWithComponent:@"ServerInfo"] recurse:YES insertIndex:-1];
    
    path = [MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil];
    if ((str = [args objectForKey:@"home_url"]) && [str length] && (url = [NSURL URLWithString:str]) && ![config objectAtPath:path]) {
      [config setObject:url atPath:path];
    }
    
    path = [MWConfigPath pathWithComponents:@"ServerInfo", @"HelpWebSite", nil];
    if ((str = [args objectForKey:@"help_url"]) && [str length] && (url = [NSURL URLWithString:str]) && ![config objectAtPath:path]) {
      [config setObject:url atPath:path];
    }
    // FIXME: undo action name
  }    
}

@end


@implementation MWMCP_dns_com_awns_status

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", nil]; }

- (void)handleMessage_:(NSDictionary *)args {
  [[self owningFilter] send:[MWLineString lineStringWithString:[args objectForKey:@"text"] role:MWStatusRole] toLinkFor:@"inward"];
}

@end

@implementation MWMCP_dns_com_awns_timezone

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"", nil]; }

- (void)startPackage {
  [self sendMCPMessage:@"dns-com-awns-timezone" args:[NSDictionary dictionaryWithObject:[[NSTimeZone defaultTimeZone] abbreviation] forKey:@"timezone"]];
}

@end

@implementation MWMCP_dns_com_awns_visual

+ (IBAction)genericOpenMapWindow:(id)sender {
  // FIXME: this WILL break
  [[[NSApp mainWindow] windowController] send:[MWToken token:@"MWMCP_dns_com_awns_visual_openMapWindow"] toLinkFor:@"outward"];
}

+ (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
   if ([item action] == @selector(genericOpenMapWindow)) {
     MWOutputWinController *const mwc = [[NSApp mainWindow] windowController];
     return mwc && [mwc respondsToSelector:@selector(links)] && !![[mwc links] objectForKey:@"outward"];
   } else {
     return YES;
   }
}

- (id)init {
  if (!(self = [super init])) return nil;

  topoCache = [[NSMutableDictionary alloc] init];
  extentRect = NSMakeRect(0, 0, 1, 1);

  return self;  
}

- (void)dealloc {
  [topoCache autorelease]; topoCache = nil;
  [location autorelease]; location = nil;
  [selfID autorelease]; selfID = nil;
  [wc autorelease]; wc = nil;
  [super dealloc];
}

- (void)owningFilterDroppedPackage {
  [[wc window] performClose:nil];
}

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; } // fixme: there's a 1.1

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"location", @"users", @"topology", @"self", nil]; }

- (void)startPackage {
  [self sendMCPMessage:@"dns-com-awns-visual-getself" args:nil];
  [self sendMCPMessage:@"dns-com-awns-visual-getlocation" args:nil];
}

- (BOOL)visualIsActive {
  return (wc && [[wc window] isVisible]) || [[[[self owningFilter] config] objectAtPath:[MWConfigPath pathWithComponent:@"MCPMapWindowEnabled"]] intValue];
}

- (void)visualEnsureFetchedVicinity:(NSString *)newLoc {
  if (![[[topoCache objectForKey:newLoc] objectForKey:@"gotNeighbors"] intValue]) {
    [self sendMCPMessage:@"dns-com-awns-visual-gettopology" args:[NSDictionary dictionaryWithObjectsAndKeys:
      newLoc, @"location",
      @"2", @"distance",
      nil
    ]];

    if (![topoCache objectForKey:newLoc]) [topoCache setObject:[NSMutableDictionary dictionary] forKey:newLoc];
    [[topoCache objectForKey:newLoc] setObject:[NSNumber numberWithInt:1] forKey:@"gotNeighbors"];
  } else {
    [self visualLayoutNodes:[NSSet setWithArray:[[[topoCache objectForKey:newLoc] objectForKey:@"exits"] allValues]]];
    [self visualLayoutNodes:[NSSet setWithObject:newLoc]];
  }
}

- (void)visualOpenWindow {
  if (!wc) wc = [[MWMCPMappingWinController alloc] initWithOwner:self];

  [self visualEnsureFetchedVicinity:location];
  
  [[wc graph] reloadData];
  [wc centerHere:nil];
  
  [[wc window] orderFront:nil];
}

- (void)visualStartAutolayout {
  if (!autolayoutTimer) {
    autolayoutTimer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(autoRelayoutTimer:) userInfo:nil repeats:YES] retain];
  }
}

- (void)autoRelayoutTimer:(NSTimer *)timer {
  if (![self visualIsActive]) {
    [autolayoutTimer invalidate]; 
    [autolayoutTimer release];
    autolayoutTimer = nil;
    return;
  }
  [self visualLayoutAllNodes];
}

- (NSPoint)uniPreferredOffsetBetweenNode:(NSString *)node andNode:(NSString *)adjacentNode {
  static NSDictionary *exitOffsets;
  
  if (!exitOffsets) exitOffsets = [[NSDictionary alloc] initWithObjectsAndKeys:
    [NSValue valueWithPoint:NSMakePoint(  0, -80)], @"n",
    [NSValue valueWithPoint:NSMakePoint( 80, -80)], @"ne",
    [NSValue valueWithPoint:NSMakePoint( 80,   0)], @"e",
    [NSValue valueWithPoint:NSMakePoint( 80,  80)], @"se",
    [NSValue valueWithPoint:NSMakePoint(  0,  80)], @"s",
    [NSValue valueWithPoint:NSMakePoint(-80,  80)], @"sw",
    [NSValue valueWithPoint:NSMakePoint(-80,   0)], @"w",
    [NSValue valueWithPoint:NSMakePoint(-80, -80)], @"nw",
    [NSValue valueWithPoint:NSMakePoint( 40, -40)], @"u",
    [NSValue valueWithPoint:NSMakePoint(-40,  40)], @"d",
    nil
  ];
  
  NSPoint p = NSMakePoint(0, 0);
  int n = 0;
  NSDictionary *const nodeDict = [topoCache objectForKey:node];

  MWenumerate ([[nodeDict objectForKey:@"exits"] keyEnumerator], NSString *, exit) {
    if ([[[nodeDict objectForKey:@"exits"] objectForKey:exit] isEqualToString:adjacentNode]) {
      NSPoint eoff = [exitOffsets objectForKey:exit] ? [[exitOffsets objectForKey:exit] pointValue] : NSMakePoint(0, 0);
        
      p = NSMakePoint(p.x + eoff.x, p.y + eoff.y);
      n++;
    }
  }
  
  if (n) {
    p.x /= n;
    p.y /= n;
  }
  
  return p;
}

- (NSPoint)preferredOffsetBetweenNode:(NSString *)node andNode:(NSString *)adjacentNode {
  NSPoint a = [self uniPreferredOffsetBetweenNode:node andNode:adjacentNode];
  NSPoint b = [self uniPreferredOffsetBetweenNode:adjacentNode andNode:node];
  return NSMakePoint((a.x - b.x) / 2, (a.y - b.y) / 2);
}

- (void)visualLayoutAllNodes {
  extentRect = NSMakeRect(0, 0, 1, 1);
  [self visualLayoutNodes:[NSSet setWithArray:[topoCache allKeys]]];
}

- (void)visualLayoutNodes:(NSSet *)nodes {
  if (![self visualIsActive]) return;

  int repeat;
  for (repeat = 0; repeat < 5; repeat++) {
  
    float change = 0;
    
    [wc beginRepositioning];
  
    MWenumerate ([nodes objectEnumerator], NSString *, touched) {
      NSMutableDictionary *const touchedDict = [topoCache objectForKey:touched];
      NSPoint p = NSMakePoint(0, 0);
      int n = 0;
      NSDictionary *const exits = [touchedDict objectForKey:@"exits"];

      NSValue *const curPosV = [[topoCache objectForKey:touched] objectForKey:@"position"];
      if (curPosV) {
        NSPoint const curPos = [curPosV pointValue];
        p = NSMakePoint(p.x + curPos.x, p.y + curPos.y);
        n++;
      }
      
      MWenumerate ([exits keyEnumerator], NSString *, exit) {
        NSString *adjID = [exits objectForKey:exit];
        NSValue *adjPosV = [[topoCache objectForKey:adjID] objectForKey:@"position"];
      
        if (adjPosV) {
          NSPoint adjPos = [adjPosV pointValue];
          NSPoint const eoff = [self preferredOffsetBetweenNode:touched andNode:adjID];
          
          p = NSMakePoint(p.x + adjPos.x - eoff.x, p.y + adjPos.y - eoff.y);
          n++;
        }
      }
      
      if (n) {
        p.x /= n;
        p.y /= n;
      
        extentRect = NSUnionRect(extentRect, NSMakeRect(p.x - 150, p.y - 50, 300, 100));
        
        {
          NSPoint const oldp = [[[topoCache objectForKey:touched] objectForKey:@"position"] pointValue];
          change += fabs(p.x - oldp.x) + fabs(p.y - oldp.y);
        }
        
        [touchedDict setObject:[NSValue valueWithPoint:p] forKey:@"postLayoutPosition"];
      }
    }
  
    { MWenumerate ([nodes objectEnumerator], NSString *, touched) {
      NSMutableDictionary *const touchedDict = [topoCache objectForKey:touched];
      id const postLayoutPosition = [touchedDict objectForKey:@"postLayoutPosition"];
      
      if (postLayoutPosition) {
        [touchedDict setObject:postLayoutPosition forKey:@"position"];
      
        [touchedDict removeObjectForKey:@"postLayoutPosition"];
      }
    }}
    
    [wc endRepositioning];
    
    change /= [nodes count];
    //NSLog(@"%g", change);
  
    if (change < 4.0 && change >= autolayoutLastChange) {
      [autolayoutTimer invalidate]; 
      [autolayoutTimer release];
      autolayoutTimer = nil;
    }
  
    autolayoutLastChange = change;
  }

  [[wc graph] reloadData];
}

- (BOOL)handleOutgoing:(id)obj alreadyHandled:(BOOL)already {
  if ([obj isEqual:[MWToken token:@"MWMCP_dns_com_awns_visual_openMapWindow"]]) {
    [self visualOpenWindow];
    return YES;
  } else {
    return NO;
  }
}

- (void)handleMessage_location:(NSDictionary *)args {
  NSString *newLoc = [args objectForKey:@"id"];
  
  [location autorelease];
  location = [newLoc retain];
  
  if ([self visualIsActive]) {
    [self visualOpenWindow];
  }
}

- (void)handleMessage_users:(NSDictionary *)args {
  //NSLog(@"visual users: %@", args);
}

- (void)handleMessage_topology:(NSDictionary *)args {
  if (![self visualIsActive]) return;

  NSEnumerator
    *idE = [[args objectForKey:@"id"] objectEnumerator],
    *nameE = [[args objectForKey:@"name"] objectEnumerator],
    *exitsE = [[args objectForKey:@"exit"] objectEnumerator];
  NSString *rid, *name, *exits;
  
  NSMutableSet *touchedRooms = [NSMutableSet set];

  // Create or update room records with name/exits info
  while ((rid = [idE nextObject]) && (name = [nameE nextObject]) && (exits = [exitsE nextObject])) {
    NSEnumerator *exitWordE = [[exits componentsSeparatedByString:@" "] objectEnumerator];
    NSString *exitName, *exitDest;
    NSMutableDictionary *exits = [NSMutableDictionary dictionary];
    
    [touchedRooms addObject:rid];
    
    while ((exitName = [exitWordE nextObject]) && (exitDest = [exitWordE nextObject])) {
      [exits setObject:exitDest forKey:exitName];
    }
  
    if (![topoCache objectForKey:rid]) [topoCache setObject:[NSMutableDictionary dictionary] forKey:rid];
  
    [[topoCache objectForKey:rid] setObject:name forKey:@"name"];
    [[topoCache objectForKey:rid] setObject:exits forKey:@"exits"];
    
    if (!hasSeededPosition) {
      // bootstrap the positioning algorithm, because no room can otherwise be positioned except in relation to an already positioned one
      [[topoCache objectForKey:rid] setObject:[NSValue valueWithPoint:NSMakePoint(0, 0)] forKey:@"position"];
      hasSeededPosition = YES;    
    }
  }
  [self visualStartAutolayout];

  //NSLog(@"visual topology: %@", args);
}
- (void)handleMessage_self:(NSDictionary *)args {
  //NSLog(@"visual self: %@", args);
  [selfID autorelease];
  selfID = [[args objectForKey:@"id"] retain];
}

- (void)clearMap {
  [topoCache removeAllObjects];
  extentRect = NSMakeRect(0, 0, 1, 1);
  hasSeededPosition = NO;
  [[wc graph] reloadData];
}
- (NSMutableDictionary *)topoCache { return topoCache; }
- (NSRect)extentRect { return extentRect; }
- (NSString *)playerLocation { return location; }

@end

@implementation MWMCP_dns_org_cubik_prompt

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"is", nil]; }

- (void)handleMessage_is:(NSDictionary *)args {
  [[self owningFilter] send:[MWLineString lineStringWithString:[args objectForKey:@"prompt"] role:MWPromptRole] toLinkFor:@"inward"];
}

@end

@implementation MWMCP_dns_org_mud_moo_simpleedit

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet setWithObjects:@"content", nil]; }

- (void)handleMessage_content:(NSDictionary *)args {
  id th = [[[MWRemoteTextHolder alloc] init] autorelease];
  [th setTitle:[args objectForKey:@"name"]];
  [th setString:[[args objectForKey:@"content"] componentsJoinedByString:@"\n"]];
  [[th metadata] setDictionary:args];
  [th setDelegate:self];
  [th openView];
}

- (void)remoteTextHolderShouldSave:(MWRemoteTextHolder *)th {
  NSMutableDictionary *args = [[th metadata] mutableCopy];
  NSMutableString *content = [[th string] mutableCopy];
  [args setObject:[content componentsSeparatedByLineTerminators] forKey:@"content"];
  [args removeObjectForKey:@"name"];
  //NSLog(@">>%@<<, >>%@<<", content, args);
  [self sendMCPMessage:@"dns-org-mud-moo-simpleedit-set" args:args];
  [th hasBeenSaved];
}

@end

#import "MWTWinInterface.h"

@implementation MWMCP_dns_com_att_research_twin_window

+ (MWMCPVersion *)minVersion { return [MWMCPVersion versionWithString:@"1.0"]; }
+ (MWMCPVersion *)maxVersion { return [MWMCPVersion versionWithString:@"1.0"]; }

- (NSSet *)incomingMessages { return [NSSet set]; }

- (void)startPackage {
  [[[[self owningFilter] mcpPackages] objectForKey:@"mcp-cord"] registerCordType:@"dns-com-att-research-twin-window" handlerClass:[MWTWinInterface class]];
}

@end







