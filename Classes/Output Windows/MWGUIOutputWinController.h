/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWOutputWinController.h"

typedef enum MWViewKind {
  MWVKContainer,
  MWVKButton,
  MWVKTextField,
  MWVKTextOutput,
} MWViewKind;

@interface MWGUIOutputWinController : MWOutputWinController {
  IBOutlet NSView *customContainer;

  NSString *title;
  
  NSMutableDictionary *viewIdentifiers;
  NSMutableDictionary *identifierViews;
}

- (MWGUIOutputWinController *)init;

- (NSRect)customAreaBounds;

- (id)lpHandlesGUI:(NSString *)link;
- (id)lpGUIRootView:(NSString *)link;
- (id)lpGUICustomController:(NSString *)link;

- (void)shrinkwrap;

- (NSString *)title;
- (void)setTitle:(NSString *)str;

@end
