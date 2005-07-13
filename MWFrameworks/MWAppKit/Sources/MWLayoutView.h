/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWLayoutView is a view class which watches for changes to its subviews in order to reshape the superview and rearrange the subviews.
\*/

#import <Cocoa/Cocoa.h>

enum { MWAlignmentMin = -1, MWAlignmentMid, MWAlignmentMax };

@interface MWLayoutView : NSView {
  BOOL MWLayoutView_beingDeallocated;
  void *MWLayoutView_future;
}

- (void)performLayout:(NSString *)reason; // for subclass implementation

@end
