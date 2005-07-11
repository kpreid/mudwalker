/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWOutputWinController.h"

@interface MWOneLineRequestOutputWinController : MWOutputWinController {
  IBOutlet NSTextField *details;
  IBOutlet NSTextField *inputField;
  NSString *message;
}

- (MWOneLineRequestOutputWinController *)init;

- (IBAction)buttonCancel:(id)sender;
- (IBAction)buttonOK:(id)sender;

- (NSString *)message;
- (void)setMessage:(NSString *)str;

@end
