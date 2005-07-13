/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTCPConnection.h"

enum MWBSDSocketState {
  MWSockDisconnected,
  MWSockLookup,
  MWSockConnecting,
  MWSockConnected,
};

@interface MWBSDSocketConnection : MWTCPConnection {
 @private
  enum MWBSDSocketState state;
  int sock;
  NSTimer *sockPollTimer;
  // Using a NSArray for a queue probably isn't very efficient, but there's usually only one or two items. Items are added to the beginning of the array and removed from the end.
  NSMutableArray *writeQueue;
}

@end
