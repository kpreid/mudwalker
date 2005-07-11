/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <AppKit/AppKit.h>

@interface MWPreferencesWinController : NSWindowController {
  IBOutlet NSMatrix *cSwitches;
  IBOutlet NSMatrix *cStartupAction;
  IBOutlet NSColorWell *cScrollLockColor;
  IBOutlet NSPopUpButton *cScriptLanguage;
  BOOL delayUpdate, queuedUpdate;
}

- (IBAction)cSwitchesChanged:(id)sender;
- (IBAction)cScrollLockColorChanged:(id)sender;
- (IBAction)cStartupActionChanged:(id)sender;
- (IBAction)cScriptLanguageChanged:(id)sender;

@end
