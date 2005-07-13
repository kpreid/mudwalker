/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWDocumentSettings, NSPreferencePane, MWAccountConfigPane;

@interface MWDocumentSettingsWinController : NSWindowController {
 @private
  IBOutlet id dURLFormatter;
  IBOutlet id dSplitDelegate;
  
  IBOutlet NSTableView *paneList;
  IBOutlet NSView *paneContainer;
  //IBOutlet NSSplitView *paneSplit;
  
  IBOutlet NSView *cAddress;
  IBOutlet NSView *cAutoConnect;
  IBOutlet NSView *cLineEnding;
  IBOutlet NSPopUpButton *cCharEncoding;
  IBOutlet NSView *cScrollbackLength;
  IBOutlet NSTextField	*cPromptTimeout;
  IBOutlet NSTextView *cLoginScript;
  IBOutlet NSTextView *cLogoutScript;
  IBOutlet NSView *cColorsContainer;
  IBOutlet NSView *cColorSetPopup;
  IBOutlet NSView *cColorSetAdd;
  IBOutlet NSView *cColorSetRemove;
  IBOutlet NSView *cColorBrightColor;
  IBOutlet NSView *cColorBrightBold;
  IBOutlet NSSlider *cLineIndent;

  NSMutableArray *panes;
  NSPreferencePane *currentPane;

  NSMutableDictionary *keyToControlDict;
  NSMutableDictionary *keyToCTypeDict;
  NSMutableDictionary *controlToKeyDict;
}

- (MWDocumentSettingsWinController *)init;

- (BOOL)paneSwitch:(NSPreferencePane *)pane;

- (IBAction)paneChosen:(id)sender;

- (IBAction)settingControlChanged:(id)sender;
- (IBAction)settingColorWellChanged:(id)sender;

@end
