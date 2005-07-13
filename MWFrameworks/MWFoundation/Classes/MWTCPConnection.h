/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWAbstractConnection.h"

@interface MWTCPConnection : MWAbstractConnection {
  NSString *scheme;
  NSString *hostName;
  unsigned int hostPort;
  unsigned long hostIP; // filled in by lookup on hostName
 
  NSTask *lookupTask;
  NSPipe *lookupPipe;
}

- (void)sendData:(NSData *)d;
/* Subclass must override */

- (void)startLookup;
- (void)stopLookup;

@end
