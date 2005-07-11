/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class NSPreferencePane, MWAccountConfigPane;

@interface MWDocumentSettingsWinController : NSWindowController {
 @private
  IBOutlet NSTableView *paneList;
  IBOutlet NSView *paneContainer;

  NSMutableArray *panes;
  NSPreferencePane *currentPane;
}

- (MWDocumentSettingsWinController *)init;

- (BOOL)paneSwitch:(NSPreferencePane *)pane;

- (IBAction)paneChosen:(id)sender;

@end
