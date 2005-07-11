/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * A text view with some special features related to use as an output display:
 *   - If the user performs any editing operation, it is redirected to the global input window.
 *   - It supports automatic scrolling to the bottom upon input.
\*/

#import <Cocoa/Cocoa.h>
#import "MWCustomBindingsTextView.h"

@interface MWOutputTextView : MWCustomBindingsTextView <NSUserInterfaceValidations> {
  unsigned lastAutoscrollTextLength;
  BOOL autoScroll;
  BOOL autoScrollLock;
}

- (IBAction)autoScrollLock:(id)sender;

- (BOOL)autoScrollToEnd;
- (void)setAutoScrollToEnd:(BOOL)newVal;
  /* Control automatic scroll mode. NOTE that enabling this mode will change the text view's layout manager's delegate. */
  /* You can safely change the layout manager after calling this method, as long as you also forward all layout manager delegate messages to the text view. */

- (BOOL)autoScrollLock;
- (void)setAutoScrollLock:(BOOL)newVal;
  /* If set, disables automatic scrolling. This is toggled by autoScrollLock:. */

@end
