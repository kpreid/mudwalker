/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWApplication.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

#import "MWAppDelegate.h"

@implementation MWApplication

- (void)terminate:(id)sender {
  switch ([[self delegate] applicationMWPresaveHook:self]) {
    case NSTerminateNow: [super terminate:sender]; break;
    // hmmmm...
    case NSTerminateCancel: [self replyToApplicationShouldTerminate:NO]; break;
    case NSTerminateLater: break;
  }
}

- (void)replyToApplicationMWPresaveHook:(BOOL)should {
  if (should)
    [super terminate:nil];
  else
    // hmmmm...
    [self replyToApplicationShouldTerminate:NO];
}

- (void)sendEvent:(NSEvent *)anEvent {
  NSWindowController <MWExtInputClient> *wc = [[self mainWindow] windowController];
  id <MWConfigSupplier> config = nil;

  if (
       [anEvent type] == NSKeyDown
    && [wc conformsToProtocol:@protocol(MWExtInputClient)]

    && [wc respondsToSelector:@selector(config)]
    && (config = [(id)wc config])
    && [config isDirectoryAtPath:[MWConfigPath pathWithComponents:@"KeyCommands", MWEventToStringCode(anEvent), nil]]

    && [wc extInputManager]
    && [[wc extInputManager] isActive]
    && ![(MWAppDelegate *)[self delegate] disabledKeyMacros]
    /* whew */
  ) {
    [wc inputClientReceive:anEvent];
  } else {
    [super sendEvent:anEvent];
  }
}

@end
