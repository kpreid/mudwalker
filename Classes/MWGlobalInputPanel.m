/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWGlobalInputPanel.h"

@implementation MWGlobalInputPanel

- (IBAction)performClose:(id)sender {
  [[NSApp mainWindow] performClose:sender];
}
- (IBAction)performMiniaturize:(id)sender {
  [[NSApp mainWindow] performMiniaturize:sender];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
  if ([menuItem action] == @selector(performClose:)) {
    return YES;
  } else if ([menuItem action] == @selector(performMiniaturize:)) {
    return YES;
  } else {
    return [super validateMenuItem:menuItem];
  }
}

@end
