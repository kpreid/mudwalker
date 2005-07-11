/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWLinkableObjectController, MWOutputTextView;

@interface MWLinkableInspectorWinController : NSWindowController {
  IBOutlet MWOutputTextView *cTraceText;
  IBOutlet NSScrollView *cTraceScrollView;
  IBOutlet NSBrowser *cLinkBrowser;

  MWLinkableObjectController *LOC;
  
  NSMutableDictionary *linkOrderings;
}

// hook to open inspectors on 'important' messages - add this as an observer of MWLinkableTraceNotification
+ (void)checkImportant:(NSNotification *)notif;

- (MWLinkableInspectorWinController *)init;

- (void)showWindowBesideWindow:(NSWindow *)win;

- (MWLinkableObjectController *)LOC;
- (void)setLOC:(MWLinkableObjectController *)newLOC;

- (IBAction)mwBrowserAction:(id)sender;

- (void)makeTraceVisible;

@end
