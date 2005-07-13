/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinLayoutView.h"

#import <MudWalker/MudWalker.h>

NSString *MWLayoutTWinSizeChanged = @"MWLayoutTWinSizeChanged";

@implementation MWTWinLayoutView

- (NSSize)twinPreferredSize { return csPref; }
- (NSSize)twinStretch { return csStretch; }
- (NSSize)twinShrink { return csShrink; }

- (void)twinComputePreferredSize {
  NSLog(@"%@ did not implement twinComputePreferredSize!", [self description]);
  csPref =    NSMakeSize(100, 100);
  csStretch = NSMakeSize(50, 50);
  csShrink =  NSMakeSize(50, 50);
}
- (void)twinPerformPhysicalLayout {
  NSLog(@"%@ did not implement twinPerformPhysicalLayout!", [self description]);
}

- (void)twinRecursivePerformPhysicalLayout {
  [self twinPerformPhysicalLayout];
  [self setNeedsDisplay:YES];
  [[self subviews] makeObjectsPerformSelector:@selector(twinRecursivePerformPhysicalLayout)];
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {}

- (void)twinNotifyContainerOfSizeChange {
  [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
}

- (void)performLayout:(NSString *)reason {
  if ([reason isEqual:MWLayoutSubviewSizeChanged]) return;
 
  [self twinComputePreferredSize];
  //printf("%s sizes: %f +%f -%f, %f +%f -%f\n", [[self description] cString], [self twinPreferredSize].width, [self twinStretch].width, [self twinShrink].width, [self twinPreferredSize].height, [self twinStretch].height, [self twinShrink].height);
  [self twinNotifyContainerOfSizeChange];
}

@end
