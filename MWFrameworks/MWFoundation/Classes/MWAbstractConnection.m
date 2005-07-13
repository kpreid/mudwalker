/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWAbstractConnection.h"

#import "MWUtilities.h"
#import "MWConfigTree.h"
#import "MWConfigPath.h"
#import "MWConstants.h"
#import "MWToken.h"

@implementation MWAbstractConnection

+ (NSArray *)runLoopModesToReceiveIn {
  return [NSArray arrayWithObjects:
    NSDefaultRunLoopMode,
    @"NSModalPanelRunLoopMode",
    @"NSEventTrackingRunLoopMode",
    nil
  ];
}

- (void)dealloc {
  [self closeConnection];
  [reconnectTimer invalidate];
  [reconnectTimer release];
  [super dealloc];
}

- (void)reconnectLater {
  NSNumber *delay = [[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Reconnect", @"Delay", nil]];
  NSNumber *exp = [[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Reconnect", @"DelayExponentMinusOne", nil]];
  if (!delay)
    delay = [NSNumber numberWithFloat:10.0];
  if (!exp)
    exp = [NSNumber numberWithFloat:0.0];
    
  const float t = [delay floatValue] * pow([exp floatValue] + 1.0, failedConnects - 1);
  
  if (reconnectTimer)
    [reconnectTimer release];
  reconnectTimer = [[NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(reconnectTimer:) userInfo:nil repeats:NO] retain];
  
  [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"WillReconnectAfter%f"), t]];
}

- (void)reconnectTimer:(NSTimer *)timer {
  [self openConnection];
  [reconnectTimer invalidate];
  [reconnectTimer autorelease];
  reconnectTimer = nil;
}

- (void)connectionOpened {
  failedConnects = 0;
  [self send:MWTokenConnectionOpened toLinkFor:@"inward"];
}

- (void)connectionLost {
  [self send:MWTokenConnectionClosed toLinkFor:@"inward"];
  if ([[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Reconnect", @"OnConnectionLost", nil]] boolValue])
    [self reconnectLater];
}

- (void)connectionEOF {
  [self send:MWTokenConnectionClosed toLinkFor:@"inward"];
  if ([[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Reconnect", @"OnEOF", nil]] boolValue])
    [self reconnectLater];
}

- (void)connectionAttemptFailed {
  failedConnects++;
  if ([[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Reconnect", @"OnFailedConnect", nil]] boolValue])
    [self reconnectLater];
}

- (void)closeConnectionOrCancelReconnect {
  if ([self connectionStatus] != MWConnectionClosedStatus) {
    [self closeConnection];
    [self connectionEOF];
  }
  if (reconnectTimer) {
    [self localIzedMessage:@"ReconnectCancelled"];
    [reconnectTimer invalidate];
    [reconnectTimer release];
    reconnectTimer = nil;
  }
}

// --- Linkage ---

- (NSSet *)linkNames { return [NSSet setWithObject:@"inward"]; }

- (NSSet *)linksRequired { return [NSSet setWithObject:@"inward"]; }

- (void)unlinkAll {
  [super unlinkAll];
  [self closeConnectionOrCancelReconnect];
}

- (id)lpClosableConnection:(NSString *)link {
  MWConnectionStatus status = [self connectionStatus];
  return (reconnectTimer || status == MWConnectionOpenedStatus || status == MWConnectionOpeningStatus) ? self : nil;
}

- (id)lpUsefulConnection:(NSString *)link {
  MWConnectionStatus status = [self connectionStatus];
  return (status == MWConnectionOpenedStatus || status == MWConnectionOpeningStatus) ? self : nil;
}

// --- Subclass methods ---

- (void)openConnection {
  [NSException raise:NSInternalInconsistencyException format:@"-[MWAbstractConnection openConnection] not overriden in %@", self];
}
- (void)closeConnection {}
- (MWConnectionStatus)connectionStatus {
  return MWConnectionClosedStatus;
}

@end
