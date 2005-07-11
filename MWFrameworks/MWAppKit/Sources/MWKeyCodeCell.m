/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWKeyCodeCell.h"

#import <Cocoa/Cocoa.h>
#import "MWAppUtilities.h"
#import "MWKeyCapturingPanel.h"

@implementation MWKeyCodeCell

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
  [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
  //[self performSelector:@selector(presentEditSheet:) withObject:controlView afterDelay:0];
  
}

- (void)presentEditSheet:(NSView *)controlView {
  NSWindow *win = [controlView window];
  
  if ([win attachedSheet] || [win isSheet])
    NSBeep();
  else
    [MWKeyCapturingPanel captureKeyEventDelegate:self window:win];
}

- (void)keyCaptureCancelled:(id)context {
}
- (void)keyCaptureCompleted:(id)context event:(NSEvent *)event {
  [self setStringValue:MWEventToStringCode(event)];
  [(NSControl *)[self controlView] validateEditing];
}

@end