/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * Presents a dialog to allow the user to type in an address to quickly set up a document. Currently specifically used as the window to display for documents with no address set.
\*/

#import <Cocoa/Cocoa.h>

@interface MWAddressEntryWinController : NSWindowController {
  IBOutlet NSButton *connectButton;
  IBOutlet NSComboBox *entryComboBox;
}

- (IBAction)openSettingsWindow:(id)sender;
- (IBAction)performConnect:(id)sender;

@end
