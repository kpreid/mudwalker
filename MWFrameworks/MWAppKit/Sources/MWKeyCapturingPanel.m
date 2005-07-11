/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWKeyCapturingPanel.h"

#import "MWAppUtilities.h"

@implementation MWKeyCapturingPanel

- (void)fixNib {
  NSLog(@"%@", futureContentView);
  [self setContentSize:[futureContentView frame].size];
  [self setContentView:futureContentView];
  [futureContentView release];
  futureContentView = nil;
}

+ (void)captureKeyEventDelegate:(id)del window:(NSWindow *)win {
  MWKeyCapturingPanel *inst = [[self alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
  if (![NSBundle loadNibNamed:@"MWKeyCapturingPanel" owner:inst]) {
    NSLog(@"Failed to load MWKeyCapturingPanel nib!");
    return;
  }
  [inst fixNib];
  [inst setDelegate:del];
  [NSApp beginSheet:inst modalForWindow:win modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)dealloc {
  [capturedKeyEvent autorelease];
  capturedKeyEvent = nil;
  [super dealloc];
}

- (void)done {
  [self orderOut:nil];
  if (!released) [self autorelease];
  released = YES;
}

- (IBAction)cancelButton:(id)sender {
  [self done];
  [[self delegate] keyCaptureCancelled:self];
}

- (IBAction)okButton:(id)sender {
  [self done];
  [[self delegate] keyCaptureCancelled:self];
}

- (void)sendEvent:(NSEvent *)anEvent {
  if ([anEvent type] == NSKeyDown) {
    [capturedKeyEvent autorelease];
    capturedKeyEvent = [anEvent retain];
    [displayField setStringValue:MWEventToHumanReadableString(capturedKeyEvent)];
  } else {
    [super sendEvent:anEvent];
  }
}

- (NSEvent *)capturedKeyEvent {
  return capturedKeyEvent;
}

@end
