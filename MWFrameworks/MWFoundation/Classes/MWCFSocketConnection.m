/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCFSocketConnection.h"

#import <Foundation/Foundation.h>

#import <CoreFoundation/CFSocket.h>
#include <sys/socket.h> // socket definitions
#include <netinet/in.h> // TCP/IP definitions
#include <arpa/inet.h> // inet_ntoa()

#import <AppKit/NSApplication.h> // for additional run loop mode names
#import "MWUtilities.h"

@implementation MWCFSocketConnection

// --- Instances --- 

- (void)dealloc {
  if (cfsock) CFRelease(cfsock);
  [connectWriteQueue release]; connectWriteQueue = nil;
  [super dealloc];
}

// --- Linkage ---

- (void)sendData:(NSData *)d {
  if (connectWriteQueue) {
    [connectWriteQueue addObject:d];
  } else if (cfsock && CFSocketIsValid(cfsock)) {
    if (CFSocketSendData(cfsock, NULL, (CFDataRef)d, 5)) {
      [self localMessage:MWLocalizedStringHere(@"TCPWriteError")];
      // FIXME: um, is the connection broken now??
    }
  }
}

// --- Connecting, IO ---

static void socketCallbackFunction(CFSocketRef cfSocket, CFSocketCallBackType cfType, CFDataRef cfAddress, const void *cfData, void *cfInfo);

- (void)openConnection {
  if (cfsock) return;
  
  if (!hostIP) {
    [self startLookup];
  } else {
    CFSocketContext context = {0, self, NULL, NULL, NULL};
    CFRunLoopSourceRef rls;
    struct sockaddr_in address;

    address.sin_addr.s_addr = hostIP;
    address.sin_port = htons(hostPort);
    address.sin_family = AF_INET;

    [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnecting%s%i"), inet_ntoa(address.sin_addr), hostPort]];
    
    if (!( cfsock = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketDataCallBack | kCFSocketConnectCallBack, socketCallbackFunction, &context) )) { // obj return
      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPInitError%@"), MWLocalizedStringHere(@"CFSocketCreate() failed")]];
      [self connectionAttemptFailed];
      return;
    }
    
    if ( CFSocketConnectToAddress(cfsock, (CFDataRef)[NSData dataWithBytes:&address length:sizeof address], -1) ) { // error return
      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnectError%@"), MWLocalizedStringHere(@"CFSocketConnectToAddress() failed")]];
      CFRelease(cfsock);
      cfsock = NULL;
      [self connectionAttemptFailed];
      return;
    }
    
    if (!( rls = CFSocketCreateRunLoopSource(NULL, cfsock, 0) )) { // obj return 
      [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnectError%@"), MWLocalizedStringHere(@"CFSocketCreateRunLoopSource() failed")]];
      CFRelease(cfsock);
      cfsock = NULL;
      [self connectionAttemptFailed];
      return;
    } else {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopCommonModes);
      CFRelease(rls);
      /* Invalidating a CFSocket automatically removes its run loop source from all run loops. -- Douglas Davidson @ omnigroup macosx-dev */
    }
    
    connectWriteQueue = [[NSMutableArray allocWithZone:[self zone]] init];
  }
}

- (void)closeConnection {
  if (cfsock) {
    CFSocketInvalidate(cfsock);
    CFRelease(cfsock); cfsock = NULL;
  }
  [connectWriteQueue release]; connectWriteQueue = nil;
}

- (MWConnectionStatus)connectionStatus {
  if (cfsock && CFSocketIsValid(cfsock)) {
    if (!connectWriteQueue) {
      return MWConnectionOpenedStatus;
    } else {
      return MWConnectionOpeningStatus;
    }
  } else {
    return MWConnectionClosedStatus;
  }
}

static void socketCallbackFunction(CFSocketRef cfsock, CFSocketCallBackType cbType, CFDataRef cbAddress, const void *cbData, void *cbInfo) {
  MWCFSocketConnection *const self = (MWCFSocketConnection *)cbInfo;
  switch (cbType) {
    case kCFSocketDataCallBack:
      if (CFDataGetLength(cbData) == 0) {
        [self closeConnection];
        [self connectionEOF];
      }
      [self send:(NSData *)cbData toLinkFor:@"inward"];
      break;
    case kCFSocketConnectCallBack:
      if (cbData) {
        [self localMessage:[NSString stringWithFormat:MWLocalizedStringHere(@"TCPConnectError%@"), [NSString stringWithCString:strerror(*(int32_t *)cbData)]]];
        [self closeConnection];
        [self connectionAttemptFailed];
      } else {
        NSEnumerator *wqE = [self->connectWriteQueue objectEnumerator];
        NSData *d;
        [self->connectWriteQueue release]; self->connectWriteQueue = nil;
        while ((d = [wqE nextObject])) [self sendData:d];
      
        [self connectionOpened];
      }
      break;
    default:
      [self linkableErrorMessage:[NSString stringWithFormat:@"socketCallbackFunction got unknown CFSocketCallBackType %i", cbType]];
      break;
  }
}

@end
