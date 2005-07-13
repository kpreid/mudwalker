/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

// Ick. This breaks our nice layout model because its size depends on its superview.

#import "MWTWinSpaceView.h"

#import "MWTWinLinearLayoutView.h"
#import <MudWalker/MWConstants.h>

@implementation MWTWinSpaceView

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;
  
  pref = 1;
  stretch = shrink = 0;
  
  return self;
}

- (NSSize)twinPreferredSize {
  if ([[self superview] isKindOfClass:[MWTWinLinearLayoutView class]]) {
    if ([(MWTWinLinearLayoutView *)[self superview] isVertical])
      return NSMakeSize(0, pref);
    else
      return NSMakeSize(pref, 0);
  } else
    return NSMakeSize(pref, pref);
}

- (NSSize)twinStretch {
  if ([[self superview] isKindOfClass:[MWTWinLinearLayoutView class]]) {
    if ([(MWTWinLinearLayoutView *)[self superview] isVertical])
      return NSMakeSize(MWTWinInfinity, stretch);
    else
      return NSMakeSize(stretch, MWTWinInfinity);
  } else
    return NSMakeSize(stretch, stretch);
}

- (NSSize)twinShrink {
  if ([[self superview] isKindOfClass:[MWTWinLinearLayoutView class]]) {
    if ([(MWTWinLinearLayoutView *)[self superview] isVertical])
      return NSMakeSize(0, shrink);
    else
      return NSMakeSize(shrink, 0);
  } else
    return NSMakeSize(shrink, shrink);
}

- (void)twinComputePreferredSize {}

- (void)twinPerformPhysicalLayout {}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  if ((values = [attributes objectForKey:@"Main"])) {
    pref = stretch = shrink = -1;
    [[values componentsJoinedByString:@" "] getTWinSize:&pref stretch:&stretch shrink:&shrink];
  }
  [self performLayout:MWLayoutAttributesChanged];
  [super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
}

@end
