/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>
#import <MWAppKit/MWAppKit.h>
#import "MWTWin.h"

@interface NSView (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize;
- (NSSize)twinStretch;
- (NSSize)twinShrink;
- (void)twinSetFrameFromLayout:(NSRect)frame;

- (void)twinComputePreferredSize;
- (void)twinPerformPhysicalLayout;
- (void)twinRecursivePerformPhysicalLayout;

- (void)twinApplyFormAttributes:(NSDictionary *)attributes;
- (void)twinConfigureAs:(NSString *)widget;

- (void)twinPropagateRadioSelection:(NSView *)selected;
- (void)twinPropagateRadioState:(NSView *)selected;

@end

@interface NSView (MWTWinViewOptional)

- (void)twinEventAppend:(NSDictionary *)args;

@end

@interface MWTWinButton : NSButton {
  void *MWTWinButton_future;
}
@end

@interface MWTWinTabView : NSTabView {
  NSSize csPref, csStretch, csShrink;
}

- (void)performLayout:(NSString *)reason;

@end

@interface MWTWinScrollView : NSScrollView {
  void *MWTWinScrollView_future;
}
@end

/* Just like MWURLLoadingImageView except it responds to clicks. */
@interface MWTWinImageView : MWURLLoadingImageView {
  void *MWTwinImageView_future;
}
@end

@interface NSTabViewItem (MWTWinViewCompatibility)

- (void)twinApplyFormAttributes:(NSDictionary *)attributes;
- (void)twinConfigureAs:(NSString *)widget;

@end

@interface MWDataSourceRetainingTableView : NSTableView
@end
