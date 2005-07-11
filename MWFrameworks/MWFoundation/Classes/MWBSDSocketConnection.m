/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWBSDSocketConnection.h"

#import <Foundation/Foundation.h>
#import "MWToken.h"
#import "MWUtilities.h"

#include <netinet/in.h> // TCP/IP definitions
#include <arpa/inet.h> // inet_ntoa()
#include <sys/socket.h> // socket definitions
#include <stdio.h>  // read() write()
#include <fcntl.h>  // fcntl() and constants
#include <unistd.h> // close()
#include <sys/time.h> // struct timeval

#define READBUFSIZE 1024
#define READMAXCHUNKS 10

#define POLLTIME 0.1

@implementation MWBSDSocketConnection

// --- Instances ---

- (id)init {
  if (!(self = [super init])) return nil;
  
  sock = -1;
  state = MWSockDisconnected;
  writeQueue = [[NSMutableArray allocWithZone:[self zone]] init];
      
  return self;
}

- (void)dealloc {
  [writeQueue release]; writeQueue = nil;
  [super dealloc];
}

// --- Linkage ---

- (void)sendData:(NSData *)d {
  [writeQueue insertObject:d atIndex:0];
}

// --- Connecting, IO ---

void socketCallbackFunction(CFSocketRef cfSocket, CFSocketCallBackType cfType, CFDataRef cfAddress, const void *cfData, void *cfInfo);


- (void)openConnection {
  //printf("begin connectSocket, state is %i\n", state);
  switch (state) {
    case MWSockConnected: case MWSockConnecting:
      // don't need to do anything
      break;
      
    case MWSockLookup: {
      struct sockaddr_in my_address;
    
      if (!hostIP) break; // still looking up
      // the lookup was finished
      
      if ((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1) {
        [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPInitError%@"), [NSString stringWithCString:strerror(errno)]]];
        sock = -1;
        state = MWSockDisconnected;
        [self connectionAttemptFailed];
        return;
      }
      fcntl(sock, F_SETFL, fcntl(sock, F_GETFL, 0) | O_NONBLOCK);

      my_address.sin_addr.s_addr = hostIP;
      my_address.sin_port = htons(hostPort);
      my_address.sin_family = AF_INET;

      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnecting%s%i"), inet_ntoa(my_address.sin_addr), hostPort]];
      
      if (connect(sock, (struct sockaddr *)&my_address, sizeof(my_address)) == -1 && errno != EINPROGRESS) {
        [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnectError%@"), [NSString stringWithCString:strerror(errno)]]];
        [self closeConnection];
        [self connectionAttemptFailed];
        return;
      }
     
      sockPollTimer = [[NSTimer timerWithTimeInterval:POLLTIME
        target:self
        selector:@selector(pollSocket:)
        userInfo:nil
        repeats:YES] retain];
      [[NSRunLoop currentRunLoop] addTimer:sockPollTimer forMode:NSDefaultRunLoopMode];
      [[NSRunLoop currentRunLoop] addTimer:sockPollTimer forMode:@"NSModalPanelRunLoopMode"];
      [[NSRunLoop currentRunLoop] addTimer:sockPollTimer forMode:@"NSEventTrackingRunLoopMode"];
      
      state = MWSockConnecting;
      
      break;
    }
    
    case MWSockDisconnected:
      state = MWSockLookup;
      [self startLookup];
      break;
      
    default:
      [self linkableErrorMessage:[NSString stringWithFormat:@"weird state for MWSocketConnection: %i", state]];
      break;
  }
}

- (void)closeConnection {
  if (!(state == MWSockConnected || state == MWSockConnecting)) return;
  if (sock >= 0) {
    close(sock); // errors not worth reporting
    sock = -1;
  }
  if (sockPollTimer) {
    [sockPollTimer invalidate];
    [sockPollTimer release];
    sockPollTimer = nil;
  }
  state = MWSockDisconnected;
}

- (MWConnectionStatus)connectionStatus {
  switch (state) {
    default:
    case MWSockDisconnected: return MWConnectionClosedStatus;
    case MWSockLookup:
    case MWSockConnecting: return MWConnectionOpeningStatus;
    case MWSockConnected: return MWConnectionOpenedStatus;
  }
}

- (void)flushWriteQueue {
  while ([writeQueue count]) {
    NSData *data = [[[writeQueue lastObject] retain] autorelease];
    unsigned dataLength = [data length];
    ssize_t amountWritten;

    if (sock < 0 || state != MWSockConnected) return;

    //printf("flushWriteQueue, sock %i, queue %i, item %s\n", sock, [writeQueue count], [[data description] cString]);

    
    amountWritten = write(sock, [data bytes], dataLength);
    if (amountWritten < 0) {
      if (errno == EWOULDBLOCK || errno == EAGAIN) return;
      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPWriteError%@"), [NSString stringWithCString:strerror(errno)]]];
      [self closeConnection];
      [self connectionLost];
    } else if (amountWritten >= dataLength) {
      // write succeeded and we can write another
      [writeQueue removeLastObject];
    } else if (amountWritten == 0) {
      // no data was written - leave queue alone
    } else {
      // not all the data was written, replace queue item with partial one
      [writeQueue removeLastObject];
      [writeQueue addObject:[data subdataWithRange: NSMakeRange(amountWritten, dataLength - amountWritten)]];
    }
  }
} 

- (void)pollSocket:(NSTimer *)timer {
  unsigned char buf[READBUFSIZE];
  ssize_t amountRead;
  unsigned chunksRead;
  BOOL initial = NO;
  
  if (state == MWSockConnecting) {
    fd_set testset;
    struct timeval immediately = {0, 0};
    FD_ZERO(&testset);
    FD_SET(sock, &testset);
    if (select(sock + 1, NULL, &testset, NULL, &immediately) > 0) {
      state = MWSockConnected;
      initial = YES;
    } else {
      return;
    }
  }
  
  // in order to avoid using a large buffer or polling extremely often, we read repeatedly until no more data is received.
  for (chunksRead = 0; chunksRead < READMAXCHUNKS; chunksRead++) {
    amountRead = read(sock, buf, READBUFSIZE);
    
    if (initial && (amountRead > 0 || errno == EWOULDBLOCK || errno == EAGAIN)) 
      [self connectionOpened];
    
    if (amountRead == 0) {
      [self closeConnection];
      [self connectionEOF];
      return;
    } else if (amountRead < 0) {
      if (errno == EWOULDBLOCK || errno == EAGAIN) break;
      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(initial ? @"TCPConnectError%@" : @"TCPReadError%@"), [NSString stringWithCString:strerror(errno)]]];
      [self closeConnection];
      [self connectionAttemptFailed];
      return;
    } else /* (amountRead > 0) */ {
      NSData *d = [NSData dataWithBytes:buf length:amountRead];
      
      //printf("socket receive %s\n", [[d description] cString]);
      [self send:d toLinkFor:@"inward"];
    }
  }
  
  [self flushWriteQueue];
}

@end
