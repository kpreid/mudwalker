/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWNSFileHandleConnection.h"

#import <Foundation/Foundation.h>
#import "MWToken.h"
#import "MWUtilities.h"

@implementation MWNSFileHandleConnection

- (void)dealloc {
  if (readHandle)
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:readHandle];
  [readHandle autorelease]; readHandle = nil;
  [writeHandle autorelease]; writeHandle = nil;
  [super dealloc];
}

// --- Linkage ---

- (void)sendData:(NSData *)d {
  NS_DURING
    [writeHandle writeData:d];
  NS_HANDLER
    // should do what here?
    [localException raise];
  NS_ENDHANDLER
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if (![link isEqual:@"inward"]) return NO;

  if ([obj isKindOfClass:[MWToken class]]) {
    if ([obj isEqual:MWTokenPingSend]) {
      [self openConnection];
    } else if ([obj isEqual:MWTokenCloseConnection]) {
      [self closeConnectionOrCancelReconnect];
    } else {
      return NO;
    }
    return YES;
  } else if (![obj isKindOfClass:[NSData class]]) {
    [NSException raise:NSInvalidArgumentException format:@"MWNSFileHandleConnection was given an object that isn't NSData: %@", [obj description]];
  }
  [self sendData:(NSData *)obj];
  return YES;
}

// --- Connection ---

- (void)openConnection {}
- (void)closeConnection {
  [self setReadHandle:nil];
  [self setWriteHandle:nil];
}

- (MWConnectionStatus)connectionStatus {
  if (readHandle || writeHandle) {
    return MWConnectionOpenedStatus;
  } else {
    return MWConnectionClosedStatus;
  }
}

- (void)readHandleData:(NSNotification *)notif {
  NSData *theData = [[notif userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if (theData && [theData length]) [self send:theData toLinkFor:@"inward"];
  [readHandle readInBackgroundAndNotifyForModes:[[self class] runLoopModesToReceiveIn]];
}

- (NSFileHandle *)readHandle { return readHandle; }
- (NSFileHandle *)writeHandle { return writeHandle; }
- (void)setReadHandle:(NSFileHandle *)newVal {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:readHandle];
  [readHandle autorelease];
  readHandle = [newVal retain];
  if (readHandle) {
    [readHandle readInBackgroundAndNotifyForModes:[[self class] runLoopModesToReceiveIn]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readHandleData:) name:NSFileHandleReadCompletionNotification object:readHandle];
  }
}
- (void)setWriteHandle:(NSFileHandle *)newVal {
  [writeHandle autorelease];
  writeHandle = [newVal retain];
}

@end
