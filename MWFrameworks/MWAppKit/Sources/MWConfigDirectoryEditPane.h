/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWConfigPane.h"

@class MWConfigPath;

@interface MWConfigDirectoryEditPane : MWConfigPane {
 @private
  NSString *editingDetailsKey;
  MWConfigPath *directory;
 
  IBOutlet NSTableView *cDirectory;
  IBOutlet NSButton *cRemoveButton;
  IBOutlet NSView *cFirstDetailControl;
  IBOutlet NSView *cDetailAdapterContainer;
}

- (IBAction)dirAddItem:(id)sender;
- (IBAction)dirDeleteItems:(id)sender;

// for subclass implementation

- (NSString *)localizedItemName;
- (NSDictionary *)keysForNewItem;

// Accessors

- (NSTableView *)directoryTableView;

- (MWConfigPath *)directory;
- (void)setDirectory:(MWConfigPath *)newVal;

- (NSString *)editingDetailsKey;
- (void)setEditingDetailsKey:(NSString *)key;

@end
