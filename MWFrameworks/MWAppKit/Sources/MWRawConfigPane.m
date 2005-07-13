/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWRawConfigPane.h"

#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigPath.h>

// outline views don't retain items. therefore we keep a permanent cache of config paths as the canonical items.
static NSMutableSet *pathCache = nil;

@implementation MWRawConfigPane

+ (void)initialize {
  if (!pathCache) pathCache = [[NSMutableSet alloc] init];
}

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;
  
  return self;
}

- (MWConfigPath *)cachePath:(MWConfigPath *)input {
  MWConfigPath *retained;
  
  if (!input)
    return nil;
  else if ((retained = [pathCache member:input]))
    return retained;
  else {
    [pathCache addObject:input];
    return input;
  }
}

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];
  MWConfigPath *dir;
  
  //NSLog(@"%@ notf %@ outline %@", self, notif, outline);
  dir = [path isEqual:[MWConfigPath emptyPath]] ? path : [path pathByDeletingLastComponent];
  dir = [self cachePath:dir];
  
  //NSLog(@"%@ updating dir %@", self, dir);
  if (!dir || [dir isEqual:[MWConfigPath emptyPath]])
    [outline reloadData];
  else
    [outline reloadItem:dir reloadChildren:[outline isItemExpanded:dir]];
}

// --- Outline view delegate ---

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  NSString *ident = [tableColumn identifier];
  
  // return NO;

  if ([ident isEqualToString:@"key"])
    return YES;
  else if ([ident isEqualToString:@"value"])
    if ([[self displaySupplier] isDirectoryAtPath:item])
      return NO;
    else
      return [[[self displaySupplier] objectAtPath:item] isKindOfClass:[NSString class]];
  else if ([ident isEqualToString:@"type"])
    return NO;
  else
    return NO; // shouldn't happen
}

// --- Outline view data source ---

// - (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
  if (!item) item = [MWConfigPath emptyPath];
  return [self cachePath:[item pathByAppendingComponent:[[self displaySupplier] keyAtIndex:index inDirectoryAtPath:item]]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  if (!item) item = [MWConfigPath emptyPath];
  return [[self displaySupplier] isDirectoryAtPath:item];
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
  return [NSUnarchiver unarchiveObjectWithData:object];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) item = [MWConfigPath emptyPath];
  return [[self displaySupplier] countAtPath:item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  NSString *ident = [tableColumn identifier];
  if (!item) item = [MWConfigPath emptyPath];
  
  if ([ident isEqualToString:@"key"])
    if ([[self configTarget] objectAtPath:item])
      return [[item components] lastObject];
    else
      return [[[NSAttributedString alloc] initWithString:[[item components] lastObject] attributes:[NSDictionary dictionaryWithObject:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName]] autorelease];
  else if ([ident isEqualToString:@"value"])
    if ([[self displaySupplier] isDirectoryAtPath:item])
      return @"";
    else {
      id value = [[self displaySupplier] objectAtPath:item];
      if ([value isKindOfClass:[NSString class]])
        return value;
      else
        return [[[NSAttributedString alloc] initWithString:[value description] attributes:[NSDictionary dictionaryWithObject:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName]] autorelease];
    }
  else if ([ident isEqualToString:@"type"])
    if ([[self displaySupplier] isDirectoryAtPath:item])
      return @"Directory";
    else
      return [[[[self displaySupplier] objectAtPath:item] class] description];
  else
    return @"can't happen";
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
  if (!item) item = [MWConfigPath emptyPath];
  return [NSArchiver archivedDataWithRootObject:item];
}

// - (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item

// - (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index

// - (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard

@end
