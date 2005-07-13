/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MWConcreteLinkable.h>
#import <AppKit/AppKit.h>

@class MWTerminalPane;
@protocol MWExtInputManager;

@protocol MWTerminalPaneDelegate

/* Document name or nil. */
- (NSString *)terminalPaneBaseTitle:(MWTerminalPane *)pane;

/* Called when the pane knows that the [summary] title has changed. Note that neither of these methods will be called, even though the title may be different, if the delegate's -terminalPaneBaseTitle: changes. */
- (void)terminalPaneTitleDidChange:(MWTerminalPane *)pane;
- (void)terminalPaneSummaryTitleDidChange:(MWTerminalPane *)pane;

/* FIXME: ASAP, make the ExtInputManager part of the terminal pane's state instead of the OWC's */
- (id <MWExtInputManager>)terminalPaneExtInputManager:(MWTerminalPane *)pane;

@end

@interface MWTerminalPane : MWConcreteLinkable <NSUserInterfaceValidations> {
  IBOutlet id <MWTerminalPaneDelegate> delegate;
}

- (void)mainViewDidLoad;

- (NSString *)title;
- (NSString *)summaryTitle;

/* FIXME: temporary till the transition is over */
- (void)setInputPrompt:(NSAttributedString *)prompt;

/* NONRETAINED */
- (id <MWTerminalPaneDelegate>)delegate;
- (void)setDelegate:(id <MWTerminalPaneDelegate>)newVal;

@end
