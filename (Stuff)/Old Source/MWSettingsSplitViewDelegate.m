/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWSettingsSplitViewDelegate.h"

@implementation MWSettingsSplitViewDelegate

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset {
  NSSize size = [[[sender subviews] objectAtIndex:offset+1] mwMinimumSize];
  //printf("constrainMax: :%f :%i (%f)\n", proposedMax, offset, size.width);
  return proposedMax - ([sender isVertical] ? size.width : size.height);
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset {
  NSSize size = [[[sender subviews] objectAtIndex:offset] mwMinimumSize];
  //printf("constrainMin: :%f :%i\n", proposedMin, offset);
  return proposedMin + ([sender isVertical] ? size.width : size.height);
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
  NSSize curSize = [sender frame].size;
  //FIXME: this is a quick implementation that works for the places where this is used
  NSSize diffSize = NSMakeSize(curSize.width - oldSize.width, curSize.height - oldSize.height);
  NSView *freeSubview = [[sender subviews] objectAtIndex:0];
  NSView *limitSubview = [[sender subviews] objectAtIndex:1];
  NSRect oldFreeFrame = [freeSubview frame];
  NSRect oldLimitFrame = [limitSubview frame];
  [freeSubview setFrame:NSMakeRect(oldFreeFrame.origin.x, oldFreeFrame.origin.y, oldFreeFrame.size.width + diffSize.width, oldFreeFrame.size.height + diffSize.height)];
  [limitSubview setFrame:NSMakeRect(oldLimitFrame.origin.x + diffSize.width, oldLimitFrame.origin.y, oldLimitFrame.size.width, oldLimitFrame.size.height + diffSize.height)];

}

@end

@implementation NSObject (MWMinimumViewSize)

- (NSSize)mwMinimumSize {
  return NSMakeSize(0, 0);
}

@end