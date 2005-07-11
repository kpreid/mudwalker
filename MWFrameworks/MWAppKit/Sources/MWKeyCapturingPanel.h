/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@interface MWKeyCapturingPanel : NSPanel {
  NSEvent *capturedKeyEvent;
  BOOL released;

  IBOutlet NSView *futureContentView;
  IBOutlet NSTextField *displayField;
}

+ (void)captureKeyEventDelegate:(id)del window:(NSWindow *)win;

- (IBAction)cancelButton:(id)sender;
- (IBAction)okButton:(id)sender;

- (NSEvent *)capturedKeyEvent;

@end

@interface NSObject (MWKeyCapturingPanelDelegate)

- (void)keyCaptureCancelled:(MWKeyCapturingPanel *)panel;
- (void)keyCaptureCompleted:(MWKeyCapturingPanel *)panel event:(NSEvent *)event;

@end
