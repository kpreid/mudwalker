/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This is a concrete subclass of MWTCPConnection. Implements communication over one or two NSFileHandles (i.e., file descriptors). Can be used with sockets, though not recommended.
\*/

#import "MWAbstractConnection.h"

#import <Foundation/NSFileHandle.h>

@interface MWNSFileHandleConnection : MWAbstractConnection {
  NSFileHandle *readHandle, *writeHandle;
}

- (NSFileHandle *)readHandle;
- (NSFileHandle *)writeHandle;
- (void)setReadHandle:(NSFileHandle *)newVal;
- (void)setWriteHandle:(NSFileHandle *)newVal;

@end
