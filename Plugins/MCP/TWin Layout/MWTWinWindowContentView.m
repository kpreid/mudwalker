/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinWindowContentView.h"

#import <MudWalker/MudWalker.h>
#import "MWTWinViewCompatibility.h"

static const int margin = 2;

@implementation MWTWinWindowContentView

- (void)twinComputePreferredSize {
  NSView *subview = [[self subviews] objectAtIndex:0];
  NSSize pref = [subview twinPreferredSize];
  
  csPref = NSMakeSize(pref.width + margin * 2, pref.height + margin * 2);
  csStretch = [subview twinStretch];
  csShrink = [subview twinShrink];
}

- (void)twinPerformPhysicalLayout {
  NSView *subview = [[self subviews] objectAtIndex:0];
  NSSize mySize = [self bounds].size;
  [subview twinSetFrameFromLayout:NSInsetRect(NSMakeRect(0, 0, mySize.width, mySize.height), margin, margin)];
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  if ((values = [attributes objectForKey:@"Title"])) {
    [[self window] setTitle:[values objectAtIndex:0]];
  }
  [super twinApplyFormAttributes:attributes];
}

- (void)twinNotifyContainerOfSizeChange {
  NSWindow *w = [self window];
  NSPoint curOrigin = [w frame].origin;
  NSSize current = [self frame].size;
  NSSize pref = [self twinPreferredSize];
  NSSize stretch = [self twinStretch];
  NSSize shrink = [self twinShrink];
  
  NSRect minr = NSMakeRect(0, 0,
    pref.width - shrink.width,
    pref.height - shrink.height
  );
  NSRect maxr = NSMakeRect(0, 0,
    pref.width + stretch.width,
    pref.height + stretch.height
  );
  
  /*NSLog(@"\npref = %@\nstretch = %@\nshrink = %@\nmin = %@\nmax = %@\n",
    NSStringFromSize(pref), NSStringFromSize(stretch), NSStringFromSize(shrink), NSStringFromRect(minr), NSStringFromRect(maxr)
  );*/
  
  [w setMinSize:[NSWindow frameRectForContentRect:minr styleMask:[w styleMask]].size];
  [w setMaxSize:[NSWindow frameRectForContentRect:maxr styleMask:[w styleMask]].size];
  
  if (current.width < minr.size.width) current.width = minr.size.width;
  if (current.height < minr.size.height) current.height = minr.size.height;
  if (current.width > maxr.size.width) current.width = maxr.size.width;
  if (current.height > maxr.size.height) current.height = maxr.size.height;
  [w setFrame:[NSWindow frameRectForContentRect:NSMakeRect(curOrigin.x, curOrigin.y, current.width, current.height) styleMask:[w styleMask]] display:NO];
}

@end
