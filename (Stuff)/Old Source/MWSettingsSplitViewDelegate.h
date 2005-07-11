/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@interface MWSettingsSplitViewDelegate : NSObject {}

//- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview;

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset;
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset;

//- (float)splitView:(NSSplitView *)splitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset;

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize;

//- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;
//- (void)splitViewWillResizeSubviews:(NSNotification *)aNotification;

@end

@interface NSObject (MWMinimumViewSize)

- (NSSize)mwMinimumSize;

@end