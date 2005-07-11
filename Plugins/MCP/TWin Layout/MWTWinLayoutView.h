/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MWAppKit/MWLayoutView.h>
#import "MWTWin.h"

extern NSString *MWLayoutTWinSizeChanged;

@interface MWTWinLayoutView : MWLayoutView {
  // cached size
  NSSize csPref, csStretch, csShrink;
}

- (NSSize)twinPreferredSize;
- (NSSize)twinStretch;
- (NSSize)twinShrink;

- (void)twinComputePreferredSize;
- (void)twinPerformPhysicalLayout;
- (void)twinRecursivePerformPhysicalLayout;
- (void)twinApplyFormAttributes:(NSDictionary *)attributes;
- (void)twinNotifyContainerOfSizeChange;

@end
