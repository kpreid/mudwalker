/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MWAppKit/MWAppKit.h>

@interface MWTelnetConfigPane : MWConfigPane {
  IBOutlet NSPopUpButton *cEncoding;
  IBOutlet NSPopUpButton *cLineEnding;
  IBOutlet NSTextField *cPromptTimeout;
}

- (IBAction)cEncodingAction:(id)sender;
- (IBAction)cLineEndingAction:(id)sender;
- (IBAction)cPromptTimeoutAction:(id)sender;

@end
