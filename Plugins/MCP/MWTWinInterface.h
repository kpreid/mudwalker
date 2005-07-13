/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MudWalker.h>
#import <AppKit/AppKit.h>

@interface MWTWinInterface : MWConcreteLinkable {
  NSWindow *window;
  NSMutableDictionary *widgets;
  NSMutableDictionary *revWidgets;
  unsigned long receivedCount, sentCount, ackedSentCount;
  BOOL dontSendChanges, dontCloseWindow;
}

- (void)sendTWinEvent:(NSString *)event widgetView:view arguments:(NSDictionary *)arguments;

- (IBAction)twinInvokeAction:(id)sender;

- (NSView *)widgetNamed:(NSString *)name;
- (NSString *)nameOfWidget:(NSView *)widget;

@end

