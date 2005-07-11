/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import "MWConcreteLinkable.h"

typedef enum MWConnectionStatus {
  MWConnectionClosedStatus,
  MWConnectionOpeningStatus,
  MWConnectionOpenedStatus,
  MWConnectionClosingStatus,
} MWConnectionStatus;

@interface MWAbstractConnection : MWConcreteLinkable {
  int failedConnects;
  MWConnectionStatus externalStatus;
  NSTimer *reconnectTimer;
  void *MWAbstractConnection_future;
}

+ (NSArray *)runLoopModesToReceiveIn;
/* If applicable, connections should add any run loop sources to these modes. */

- (void)closeConnectionOrCancelReconnect;
/* makes sure that the connection is not, and will not become, connected. will call -connectionEOF if appropriate. */

- (void)connectionOpened;
- (void)connectionLost;
- (void)connectionEOF;
- (void)connectionAttemptFailed;
/* subclasses should call these methods as appropriate. if EOF cannot be distinguished from Lost, call EOF. */

- (void)openConnection;
/* Implement this to cause the connection to eventually reach MWConnectionOpenedStatus. */
- (void)closeConnection;
/* Implement this to remove any association with external entities. Will be called upon deallocation. Do *not* call -connectionLost or -connectionEOF. */

- (MWConnectionStatus)connectionStatus;
/* Implement this to return appropriate status value. */

@end
