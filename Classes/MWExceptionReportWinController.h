/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@interface MWExceptionReportWinController : NSWindowController {
  IBOutlet NSTextField *excCaughtBecause;
  IBOutlet NSTextField *excCaughtBy;
  IBOutlet NSTextField *excCaughtFrom;
  IBOutlet NSTextField *excName;
  IBOutlet NSTextField *excReason;
  IBOutlet NSTextField *excUserInfo;
}

- (IBAction)excBugReport:(id)sender;
- (IBAction)excCopyInfo:(id)sender;
- (IBAction)excIgnore:(id)sender;
- (IBAction)excSaveAll:(id)sender;
- (IBAction)excSaveAndQuit:(id)sender;

@end
