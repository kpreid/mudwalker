/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Manages the Find function. 
\*/

#import <Cocoa/Cocoa.h>

@class MWValidatedButton;

@interface MWTextFindController : NSWindowController <NSUserInterfaceValidations> {
  IBOutlet NSTextField *findField;
  IBOutlet NSTextField *replaceField;
  IBOutlet MWValidatedButton *findNextBtn;
  IBOutlet MWValidatedButton *findPrevBtn;
  IBOutlet MWValidatedButton *replaceBtn;
  IBOutlet MWValidatedButton *replaceAndFindBtn;
  IBOutlet MWValidatedButton *replaceAllBtn;
  IBOutlet NSButton *ignoreCaseBtn;
  IBOutlet NSButton *replaceInSelectionBtn;
  IBOutlet NSButton *gotoBtn;
  IBOutlet NSTextField *gotoField;
  IBOutlet NSMatrix *gotoModeRadio;

  NSString *originalWindowTitle;
  
  NSWindow *targetWindow;
  
  NSString *findString;
  NSString *replaceString;
  BOOL lastFindWasSuccessful, lastGotoWasSuccessful;
}

+ (MWTextFindController *)sharedInstance;

- (IBAction)useSelectionForFind:(id)sender;

- (IBAction)findNext:(id)sender;
- (IBAction)findNextOnce:(id)sender;
- (IBAction)findPrevious:(id)sender;

- (IBAction)replaceFound:(id)sender;
- (IBAction)replaceAndFind:(id)sender;
- (IBAction)replaceAll:(id)sender;

- (IBAction)showGotoLineControls:(id)sender;
- (IBAction)gotoPerform:(id)sender;
- (IBAction)gotoPerformOnce:(id)sender;

@end
