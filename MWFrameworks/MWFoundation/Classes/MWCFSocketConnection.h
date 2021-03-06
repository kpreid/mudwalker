/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This is a concrete subclass of MWTCPConnection. Implements TCP communication using the CoreFoundation CFSocket object.
\*/

#import "MWTCPConnection.h"

#import <CoreFoundation/CFSocket.h>

@interface MWCFSocketConnection : MWTCPConnection {
  CFSocketRef cfsock;
  NSMutableArray *connectWriteQueue;
}

@end
