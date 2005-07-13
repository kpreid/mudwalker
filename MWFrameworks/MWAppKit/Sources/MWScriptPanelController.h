/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWConfigScriptViewAdapter, MWValidatedButton;

@interface MWScriptPanelController : NSWindowController {
  MWConfigScriptViewAdapter *target;
  IBOutlet NSTextView *errorView;
  IBOutlet NSPopUpButton *languagePopUp;
  
  IBOutlet MWValidatedButton *saveButton, *revertButton;
}

- (IBAction)changeLanguage:(id)sender;

- (void)updateErrors;
- (void)updateLanguage;

- (void)setTarget:(MWConfigScriptViewAdapter *)newVal;

@end
