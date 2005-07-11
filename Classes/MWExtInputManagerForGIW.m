/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWExtInputManagerForGIW.h"
#import "MWAppDelegate.h"
#import "MWGlobalInputWinController.h"

@implementation MWExtInputManagerForGIW

- (id)init {
  if (!(self = [super init])) return nil;
  
  active = 1;
  history = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:@"", nil];
  
  return self;
}

- (void)dealloc {
  [inputPrompt autorelease]; inputPrompt = nil;
  [history autorelease]; history = nil;
  [super dealloc];
}

- (id <MWExtInputClient>)target { return target; }
- (void)setTarget:(id <MWExtInputClient>)newVal { target = newVal; }

// FIXME: should only talk to the GIW if our client is main, but we don't have any official way to tell if that's the case

- (NSAttributedString *)inputPrompt { return inputPrompt; }
- (void)setInputPrompt:(NSAttributedString *)newVal {
  [inputPrompt autorelease];
  inputPrompt = [newVal retain];
  [[(MWAppDelegate *)[NSApp delegate] globalInputWinController] updatePromptString:nil];
}

- (void)makeKey {
  if (active)
    [(MWAppDelegate *)[NSApp delegate] showTextInput:self];
}

- (BOOL)isActive { return active; }
- (void)setActive:(BOOL)newVal {
  active = newVal;
  if (active)
    [(MWAppDelegate *)[NSApp delegate] showTextInput:self];
  else
    [[(MWAppDelegate *)[NSApp delegate] globalInputWinController] considerMainWindow];
}

// --- GIW-specific methods ---

- (NSMutableArray *)mutableHistory { return history; }

- (unsigned)historyIndex { return historyIndex; }
- (void)setHistoryIndex:(unsigned)newVal { historyIndex = newVal; }

@end
