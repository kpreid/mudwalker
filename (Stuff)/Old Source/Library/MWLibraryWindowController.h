/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWMudLibrary;

@interface MWLibraryWindowController : NSWindowController <NSUserInterfaceValidations> {
  IBOutlet NSOutlineView *libOutline;
  IBOutlet NSScrollView *libScroller;
}

- (IBAction)mwConnect:(id)sender;
- (IBAction)mwWebSite:(id)sender;

- (MWMudLibrary *)dataSource;

@end
