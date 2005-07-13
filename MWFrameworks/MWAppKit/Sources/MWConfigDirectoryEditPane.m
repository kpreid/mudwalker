/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigDirectoryEditPane.h"

#import "MWConfigViewAdapter.h"

#import <MudWalker/MWConstants.h>
#import <MudWalker/MWUtilities.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>

@implementation MWConfigDirectoryEditPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;

  return self;
}

- (void)dealloc {
  [directory autorelease]; directory = nil;
  [editingDetailsKey autorelease]; editingDetailsKey = nil;
  [super dealloc];
}

- (void)mainViewDidLoad {
  [super mainViewDidLoad];

  [cRemoveButton setEnabled:NO]; // is this always correct?
  
  // FIXME: we should be able to import/export fragments as XML trees or somesuch
  [cDirectory registerForDraggedTypes:[NSArray arrayWithObjects:MWConfigTreeFragmentPboardType, nil]];
}

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];
  // NSLog(@"configChanged path: %@", path);

  if (!path || [path hasPrefix:directory]) {
    [cDirectory reloadData];
    
    if (editingDetailsKey) {
      unsigned index = [[self displaySupplier] indexOfKey:editingDetailsKey inDirectoryAtPath:directory];
      if (index == NSNotFound) {
        [cDirectory deselectAll:nil];
      } else {
        [cDirectory selectRow:index byExtendingSelection:NO];
      }
    }
  }
}

// --- Subclass method stubs ---

- (NSString *)localizedItemName {
  return NSLocalizedString(@"DirectoryItem", nil);
}

- (NSDictionary *)keysForNewItem {
  return [NSDictionary dictionary];
}

// --- Action methods ---

- (IBAction)dirAddItem:(id)sender {
  MWConfigTree *config = [self configTarget];
  MWConfigPath *newPath = [config nonexistentPathAtPath:directory];
  
  // FIXME: moderately unsuitable for key-matters data. ought to: 1. use "" if available? 2. modally prompt? 3. nonmodally prompt?
  
  [self setEditingDetailsKey:nil];
  
  [config addDirectoryAtPath:newPath recurse:YES insertIndex:-1];  
  [config addEntriesFromDictionary:[self keysForNewItem] atPath:newPath insertIndex:-1];
  
  { int newRow = [config countAtPath:[newPath pathByDeletingLastComponent]] - 1;
    [cDirectory selectRow:newRow byExtendingSelection:NO];
    [cDirectory scrollRowToVisible:newRow];
  }
 [[cFirstDetailControl window] makeFirstResponder:cFirstDetailControl];

  [[config undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeAdd%@"), [self localizedItemName]]];
}

- (IBAction)dirDeleteItems:(id)sender {
  MWConfigTree *config = [self configTarget];
  // copy the row set so that the removals don't affect the operation of the enumerator
  NSEnumerator *e = [[[cDirectory selectedRowEnumerator] allObjects] objectEnumerator];
  NSNumber *rowIndex;
  unsigned offset = 0;
  
  [self setEditingDetailsKey:nil];
  
  // deleting rows changes indexes of course, so we compensate
  while ((rowIndex = [e nextObject])) {
    unsigned int index = [rowIndex unsignedIntValue] - (offset++);
    [config removeItemAtPath:
      [directory pathByAppendingComponent:
        [[self displaySupplier] keyAtIndex:index inDirectoryAtPath:directory]
      ]
    recurse:YES];
  }
  [[config undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeDelete%@"), [self localizedItemName]]];
  [cDirectory deselectAll:nil];
}

// --- Table view delegate and data source ---

- (int)numberOfRowsInTableView:(NSTableView *)sender {
  return [[self displaySupplier] countAtPath:directory];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  NSString *cid = [column identifier];
  NSString *key = [[[self displaySupplier] allKeysAtPath:directory] objectAtIndex:rowIndex];
  if ([cid isEqualToString:@"__DIRECTORY__"])
    return key;
  else
    return [[self displaySupplier] objectAtPath:[[directory pathByAppendingComponent:key] pathByAppendingComponent:cid]];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
}

- (BOOL)tableView:(NSTableView *)sender writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  NSArray *keys = [[self displaySupplier] allKeysAtPath:directory];
  NSEnumerator *e = [rows objectEnumerator];
  NSNumber *rowIndex = nil;
  MWConfigTree *fragment = [[[MWConfigTree alloc] init] autorelease];
  
  [pboard declareTypes:[NSArray arrayWithObjects:MWConfigTreeFragmentPboardType, NSStringPboardType, nil] owner:nil];
  
  while ((rowIndex = [e nextObject])) {
    MWConfigPath *path = [directory pathByAppendingComponent:[keys objectAtIndex:[rowIndex unsignedIntValue]]];
    MWConfigPath *destPath = [MWConfigPath pathWithComponent:[keys objectAtIndex:[rowIndex unsignedIntValue]]];
    [fragment addDirectoryAtPath:destPath recurse:NO insertIndex:-1];
    [fragment copyContentsOfDirectory:path from:[self configTarget] toDirectory:destPath insertIndex:-1];
  }
  
  [pboard setData:[NSArchiver archivedDataWithRootObject:fragment] forType:MWConfigTreeFragmentPboardType];
  [pboard setString:[fragment description] forType:NSStringPboardType];
  return YES;
}

- (BOOL)draggingSourceIsSelf:(id)source {
  return [source isKindOfClass:[NSTableView class]] && [source dataSource] == self;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  NSPasteboard *pboard = [info draggingPasteboard];
  
  if (![pboard availableTypeFromArray:[NSArray arrayWithObjects:MWConfigTreeFragmentPboardType, nil]])
    return NSDragOperationNone;
  
  if (row < 0)
    [sender setDropRow:[sender numberOfRows] dropOperation:NSTableViewDropAbove];
  else if (dropOperation == NSTableViewDropOn)
    [sender setDropRow:row dropOperation:NSTableViewDropAbove];
  
  if ([self draggingSourceIsSelf:[info draggingSource]])
    return [info draggingSourceOperationMask];
  else
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)dropOperation {
  NSPasteboard *pboard = [info draggingPasteboard];
  NSString *gettingType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:MWConfigTreeFragmentPboardType, nil]];
  MWConfigTree *config = [self configTarget];
  MWConfigTree *fragment = nil;
  int rowLast = row;
  
  NSAssert1(gettingType, @"can't happen: %@ directory table got wrong pasteboard type", self);
  
  fragment = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:MWConfigTreeFragmentPboardType]];
  NSAssert(fragment && [fragment isKindOfClass:[MWConfigTree class]], @"failed to unarchive config tree fragment on pasteboard"); // FIXME: doc for dataForType: should display an error alert

  if ([info draggingSourceOperationMask] & NSDragOperationGeneric && [self draggingSourceIsSelf:[info draggingSource]]) {
    // --- move, so delete and readd items
    
    NSArray *allKeys = [config allKeysAtPath:directory];
    NSEnumerator *newKeyE = [[fragment allKeysAtPath:[MWConfigPath emptyPath]] objectEnumerator];
    NSString *newKey;
    int rowAdjust = 0;
    
    while ((newKey = [newKeyE nextObject])) {
      int delIndex = [allKeys indexOfObject:newKey];
      [config removeItemAtPath:[directory pathByAppendingComponent:newKey] recurse:YES];
      if (row > delIndex) rowAdjust++;
    }
    row -= rowAdjust;
    
    [config addDirectoryAtPath:directory recurse:YES insertIndex:-1];
    { int max = [config countAtPath:directory];
      if (row > max) row = max; // support for inherited items
    }
    [config addEntriesFromTree:fragment atPath:directory insertIndex:row];
    rowLast = row + [fragment countAtPath:[MWConfigPath emptyPath]];
    
  [[config undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeReorder%@"), [self localizedItemName]]];

  } else {
    // --- copy, so insert new items

    NSEnumerator *newKeyE = [[fragment allKeysAtPath:[MWConfigPath emptyPath]] objectEnumerator];
    NSString *newKey;
    
    while ((newKey = [newKeyE nextObject])) {
      MWConfigPath *sourcePath = [MWConfigPath pathWithComponent:newKey];
      MWConfigPath *destPath = [config nonexistentPathAtPath:directory];
      // FIXME: unsuitable for key-matters data.
      if ([fragment isDirectoryAtPath:sourcePath]) {
        [config addDirectoryAtPath:destPath recurse:YES insertIndex:rowLast++];
        [config copyContentsOfDirectory:sourcePath from:fragment toDirectory:destPath insertIndex:-1];
      } else {
        [config setObject:[fragment objectAtPath:sourcePath] atPath:destPath insertIndex:rowLast++];
      }
    }

  [[config undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeAdd%@"), [self localizedItemName]]];
  }
  
  [cDirectory scrollRowToVisible:rowLast];
  [cDirectory scrollRowToVisible:row];
  for (; row < rowLast; row++)
    [cDirectory selectRow:row byExtendingSelection:NO];
    
  return YES;
}

- (IBAction)tableViewSelectionDidChange:(NSNotification *)notif {
  NSEnumerator *e = [cDirectory selectedRowEnumerator];
  unsigned selectedRows = 0;
  while ([e nextObject]) selectedRows++;
  
  if (selectedRows == 1)
    [self setEditingDetailsKey:[[self displaySupplier] keyAtIndex:[cDirectory selectedRow] inDirectoryAtPath:directory]];
  else
    [self setEditingDetailsKey:nil];

  [cRemoveButton setEnabled:!!selectedRows];
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  MWConfigTree *config = [self configTarget];
  NSString *cid = [column identifier];
  NSString *key = [[self displaySupplier] keyAtIndex:rowIndex inDirectoryAtPath:directory];
  if ([cid isEqualToString:@"__DIRECTORY__"]) {
    MWConfigPath *oldPath = [directory pathByAppendingComponent:key];
    MWConfigPath *newPath = [directory pathByAppendingComponent:newVal];
    
    if (![oldPath isEqual:newPath]) {
      NSLog(@"%@ %@", oldPath, newPath);
      [config addDirectoryAtPath:newPath recurse:NO insertIndex:rowIndex];
      [config copyContentsOfDirectory:oldPath from:[self displaySupplier] toDirectory:newPath insertIndex:-1];
      [config removeItemAtPath:oldPath recurse:YES];
    }
    
  } else {
    MWConfigPath *fieldPath = [[directory pathByAppendingComponent:key] pathByAppendingComponent:[column identifier]];
    
    if (![[config objectAtPath:fieldPath] isEqual:newVal]) {
      [config addDirectoryAtPath:[directory pathByAppendingComponent:key] recurse:YES insertIndex:-1];
      [config setObject:newVal atPath:fieldPath];
      [[config undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeValue%@"), [self localizedItemName]]];
    }
  }
}

// ---

- (void)updateDetailAdaptersInView:(NSView *)view discard:(BOOL)discard {
  if ([view isKindOfClass:[MWConfigViewAdapter class]]) {
    [(MWConfigViewAdapter *)view setBasePath:editingDetailsKey ? [directory pathByAppendingComponent:editingDetailsKey] : nil discard:discard];
    
  } else if ([view isKindOfClass:[NSTabView class]]) {
    MWenumerate([[(NSTabView *)view tabViewItems] objectEnumerator], NSTabViewItem *, item) {
      [self updateDetailAdaptersInView:[item view] discard:discard];
    }
  } else {
    MWenumerate([[view subviews] objectEnumerator], NSView *, subview) {
      [self updateDetailAdaptersInView:subview discard:discard];
    }
  }
}

// ---

- (NSTableView *)directoryTableView {
  return cDirectory;
}

- (MWConfigPath *)directory {
  return directory;
}
- (void)setDirectory:(MWConfigPath *)newVal {
  [directory autorelease]; directory = [newVal retain];
  [cDirectory reloadData];
  [cDirectory deselectAll:nil];
}

- (NSString *)editingDetailsKey { return editingDetailsKey; }
- (void)setEditingDetailsKey:(NSString *)newVal {
  NSString *prevKey = editingDetailsKey;
  [editingDetailsKey autorelease];
  editingDetailsKey = [newVal retain];
  [self updateDetailAdaptersInView:cDetailAdapterContainer discard:(!prevKey || ([[self displaySupplier] indexOfKey:prevKey inDirectoryAtPath:directory] == NSNotFound))];
}


@end
