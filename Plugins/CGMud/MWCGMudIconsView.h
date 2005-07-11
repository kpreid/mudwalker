/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@interface MWCGMudIconsView : NSView {
  NSMutableArray *iconOrdering;
  NSMutableDictionary *iconImages;
  NSMutableDictionary *iconStates;
}

- (void)addIcon:(id)iconID image:(NSImage *)img;
- (void)removeIcon:(id)iconID;
- (void)removeAllIcons;

@end
