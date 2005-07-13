/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTCPConnection.h"

#import "LookupHandler.h"
#import "MWToken.h"
#import "MWUtilities.h"
#import "MWConfigPath.h"
#import "MWConfigTree.h"
#import "MWBSDSocketConnection.h"
#import "MWCFSocketConnection.h"

@interface MWTCPConnection (Private)

- (void)setHostName:(NSString *)name;
- (NSString *)hostName;
- (void)setHostPort:(unsigned int)port;
- (unsigned int)hostPost;

@end

@implementation MWTCPConnection

// --- Instances ---

- (id)init {
  if (!(self = [super init])) return nil;
  
  if ([self isMemberOfClass:[MWTCPConnection class]]) {
    id replacement = [[MWCFSocketConnection allocWithZone:[self zone]] init];
    [self release];
    return replacement;
  }
      
  return self;
}
- (void)dealloc {
  [self stopLookup];
  [scheme autorelease]; scheme = nil;
  [hostName autorelease]; hostName = nil;
  [super dealloc];
}

// --- Linkage ---

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if (![link isEqual:@"inward"]) return NO;

  if ([obj isKindOfClass:[MWToken class]]) {
    if ([obj isEqual:MWTokenOpenConnection]) {
      [self openConnection];
    } else if ([obj isEqual:MWTokenCloseConnection]) {
      [self closeConnectionOrCancelReconnect];
    } else if ([obj isEqual:MWTokenPingSend]) {
      [self send:MWTokenPingCant toLinkFor:@"inward"];
    } else {
      return NO;
    }
    return YES;
  } else if (![obj respondsToSelector:@selector(bytes)]) {
    return NO;
  }
  [self sendData:(NSData *)obj];
  return YES;
}

- (id)lpConnectionDescription:(NSString *)link { return [NSString stringWithFormat:@"%@:%u", hostName, hostPort]; }

- (void)sendData:(NSData *)d {
  [NSException raise:NSInternalInconsistencyException format:@"-[MWTCPConnection sendData:] not overriden in %@", self];
}

// --- Configuration ---

- (void)configChanged:(NSNotification *)notif {
  NSURL *url;
  [super configChanged:notif];
  
  url = [[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]];

  [self setHostName:[url host]];
  [self setHostPort:[[url port] unsignedIntValue]];
  
  if (scheme) {
    if (![scheme isEqual:[url scheme]]) {
      // We're making an assumption here: If we get reconfigured with a different scheme, then the filter chain is probably not applicable to the new scheme.
      [self unlinkAll];
    }
  } else {
    scheme = [[url scheme] retain];
  }
}

// --- Interfacing with LookupHandler ---

- (void)startLookup {
  // Executables in a framework get stuck in the resources dir...
  //NSString *lookupTool = [[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"LookupHandler"];
  NSString *lookupTool = [[NSBundle bundleForClass:[self class]] pathForResource:@"LookupHandler" ofType:nil];
  
  if (!hostName) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"-[MWTCPConnection startLookup] called but no hostname was set" userInfo:nil] raise];
  
  if (!lookupTool) [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"-[MWTCPConnection startLookup]: couldn't find lookup tool" userInfo:nil] raise];
  
  if (lookupTask) [self stopLookup];
  lookupTask = [[NSTask alloc] init];
  lookupPipe = [[NSPipe pipe] retain];
  
  [lookupTask setLaunchPath:lookupTool];
  [lookupTask setArguments:[NSArray arrayWithObject:hostName]];
  [lookupTask setStandardOutput:lookupPipe];
  
  [[NSNotificationCenter defaultCenter] addObserver:self 
    selector:@selector(lookupTaskCompleted:) 
    name:NSTaskDidTerminateNotification 
    object:lookupTask];

  [lookupTask launch];
  [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"DNSLookup%@"), hostName]];
}

- (void)stopLookup {
  if (lookupTask) {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
      name:NSTaskDidTerminateNotification 
      object:lookupTask];
    [lookupTask terminate];
    [lookupTask release];
    lookupTask = nil;
  }
  [lookupPipe release];
  lookupPipe = nil;
}

- (void)lookupTaskCompleted:(NSNotification *)notif {
  int status = [[notif object] terminationStatus];
  if (!lookupTask || !lookupPipe) return;

  switch (status) {
    case LHOkay: {
      NSFileHandle *fh = [lookupPipe fileHandleForReading];
      NSData *ip = [fh readDataToEndOfFile];
      hostIP = *((unsigned long *)[ip bytes]);
      [self openConnection];
      break;
    }
    case LHNotFound: case LHCallError: case LHRemoteError: case LHLocalError:
      [self localMessage:[NSString stringWithFormat:
        MWLocalizedStringHere(@"DNSLookup%@Error%@"),
        hostName,
        (status == LHNotFound
          ? MWLocalizedStringHere(@"domain name unknown")
          : MWLocalizedStringHere(@"internal DNS lookup error")
        )
      ]];
      [self closeConnection];
      [self connectionAttemptFailed];
      break;
    default:
      break;
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:self 
    name:NSTaskDidTerminateNotification 
    object:lookupTask];
  [lookupPipe release];
  lookupPipe = nil;
  [lookupTask release];
  lookupTask = nil;
}

// --- Accessors ---

- (void)setHostName:(NSString *)name {
  [name retain];
  [hostName release];
  hostName = name;
  [self stopLookup]; // so we don't cache an old IP
  hostIP = 0;
}
- (NSString *)hostName { return hostName; }

- (void)setHostPort:(unsigned int)port {
  hostPort = port;
}
- (unsigned int)hostPost { return hostPort; }

- (NSString *)linkableUserDescription { return [NSString stringWithFormat:@"%@:%u #%u", hostName, hostPort, [self smallID]]; }

@end
