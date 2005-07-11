/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTerminalPane.h"

#import <MudWalker/MudWalker.h>
#import "MWExtInput.h"

@implementation MWTerminalPane

- (void)mainViewDidLoad {
}

- (NSString *)title {
  return [delegate terminalPaneBaseTitle:self];
}

- (NSString *)summaryTitle {
  return [delegate terminalPaneBaseTitle:self];
}

- (void)setInputPrompt:(NSAttributedString *)prompt {
  [[delegate terminalPaneExtInputManager:self] setInputPrompt:prompt];
}

- (NSSet *)linksRequired { return [NSSet setWithObject:@"outward"]; }

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  return YES;
}

- (id <MWTerminalPaneDelegate>)delegate { return delegate; }
- (void)setDelegate:(id <MWTerminalPaneDelegate>)newVal {
  delegate = newVal;
}

@end
