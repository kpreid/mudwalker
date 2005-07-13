/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * A floating panel to allow the user to conveniently enable and disable triggers. Imitates Rapscallion.
\*/

#import <AppKit/AppKit.h>

@class MWConnectionDocument;

@interface MWTriggerEnablePanelWinController : NSWindowController {
  IBOutlet NSTableView *triggerTable;
  MWConnectionDocument *targetDocument;
}

@end
