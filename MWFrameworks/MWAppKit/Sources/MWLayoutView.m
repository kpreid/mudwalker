/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLayoutView.h"

#import "MWConstants.h"

@implementation MWLayoutView

// no initWithFrame: needed

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  MWLayoutView_beingDeallocated = 1;
  [super dealloc];
}

- (void)didAddSubview:(NSView *)v {
  [super didAddSubview:v];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subviewFrameChanged:) name: NSViewFrameDidChangeNotification object:v];
  [self performLayout:MWLayoutSubviewAdded];
}

- (void)willRemoveSubview:(NSView *)v {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:v];
  [super willRemoveSubview:v];
  if (!MWLayoutView_beingDeallocated) [self performSelector:@selector(myDidRemoveSubview:) withObject:v afterDelay:0];
}

- (void)myDidRemoveSubview:(NSView *)v {
  [self performLayout:MWLayoutSubviewRemoved];
}

- (void)subviewFrameChanged:(NSView *)v {
  [self performLayout:MWLayoutSubviewSizeChanged];
}

- (void)performLayout:(NSString *)reason {
  // for subclass implementation
}

@end
