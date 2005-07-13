/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <MudWalker/MudWalker.h>
#include <stdlib.h>
#include <unistd.h>

@interface MWDistributionController : NSObject {
}
@end

@implementation MWDistributionController
@end

int MWBGMain(int argc, const char *argv[]) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  MWDistributionController *dc = [[MWDistributionController alloc] init];
  NSConnection *theConnection = [NSConnection defaultConnection];

  //daemon(0, 0);

  [[MWRegistry defaultRegistry] loadPlugins];

  [theConnection setRootObject:dc];
  [theConnection setDelegate:dc];
  if (![theConnection registerName:@"MWBackground"]) {
     NSLog(@"Name registration failed");
     exit(EXIT_FAILURE);
  }

  [theConnection performSelector:@selector(invalidate) withObject:nil afterDelay:3.0];
  
  printf("Entering run loop\n");
  [[NSRunLoop currentRunLoop] run];
  
  [pool release];
  return 0;
}