/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWMudLibrary.h"

#import <MudWalker/MudWalker.h>
#import <AppKit/AppKit.h>

#import "MWConnectionDocument.h"

#import "MWLibraryCategoryStrings.h"
#import "MWLibraryCategoryRecent.h"
#import "MWLibraryCategoryPersonal.h"
#import "MWLibraryEntry.h"

@implementation MWMudLibrary

- (MWMudLibrary *)init { // designated initializer
  if (!(self = [super init])) return nil;

  categories = [[NSMutableArray alloc] initWithObjects:
    // FIXME: should use standard search paths rather than hardcoding
    [[[MWLibraryCategoryRecent alloc] init] autorelease],
    [[[MWLibraryCategoryPersonal alloc] init] autorelease],
    [[[MWLibraryCategoryStrings alloc] initWithDisplayName:MWLocalizedStringHere(@"Library Category Computer") fileName:@"/Library/Application Support/MudWalker/Library.strings"] autorelease],
    [[[MWLibraryCategoryStrings alloc] initWithDisplayName:MWLocalizedStringHere(@"Library Category Network") fileName:@"/Network/Library/Application Support/MudWalker/Library.strings"] autorelease],
    [[[MWLibraryCategoryStrings alloc] initWithDisplayName:NSLocalizedString(@"Library Category Bundle", @"Title of library category built into the bundle") fileName:[[NSBundle mainBundle] pathForResource:@"Library" ofType:@"strings"]] autorelease],
    nil
  ];
  
  return self;
}

- (void)dealloc {
  [categories release]; categories = nil;
  [super dealloc];
}

// --- Outline view data source ---

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) {
    // the root
    return [categories count];
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    return [(id <MWLibraryItem>)item libItemNumberOfChildren];
  } else {
    return 0;
  }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
  if (!item) {
    // the root
    return [categories objectAtIndex:index];
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    return [(id <MWLibraryItem>)item libItemChildAtIndex:index];
  } else {
    return nil;
  }
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item {
  if (!item) {
    return YES;
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    return [(id <MWLibraryItem>)item libItemHasChildren];
  } else {
    return NO;
  }
}

- (id)outlineView:(NSOutlineView *)sender objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  id ident = [tableColumn identifier];
  
  if ([item respondsToSelector:@selector(objectForKey:)]) {
    return [item objectForKey:ident];
  } else if ([item isKindOfClass:[NSURL class]]) {
    if ([ident isEqual:@"name"]) {
      return [[[(NSURL *)item path] lastPathComponent] stringByDeletingPathExtension];
    } else if ([ident isEqual:@"type"]) {
      return NSLocalizedString(@"Document", @"Type of document entries in library");
    } else if ([ident isEqual:@"location"]) {
      if ([[(NSURL *)item scheme] isEqual:@"file"]) {
        return [[(NSURL *)item path] stringByAbbreviatingWithTildeInPath];
      } else {
        return item;
      }
    } else {
      return @"";
    }
  } else {
    return @"-";
  }
}

- (void)outlineView:(NSOutlineView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  id ident = [tableColumn identifier];
  if ([item respondsToSelector:@selector(setObject:forKey:)]) {
    return [item setObject:newVal forKey:ident];
  } else {
    NSBeep();
  }
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  NSEnumerator *itemE = [rows objectEnumerator];
  id item;
  NSMutableArray *files = [NSMutableArray array];
  NSMutableArray *urls = [NSMutableArray array];
  NSMutableArray *urlstrings = [NSMutableArray array];
  NSString *stringForm = nil;

  while ((item = [itemE nextObject])) {
    if ([item respondsToSelector:@selector(documentURL)]) 
      [files addObject:[[item documentURL] path]];
    if ([item respondsToSelector:@selector(serverURL)]) {
      [urls addObject:[item serverURL]];
      [urlstrings addObject:[[item serverURL] absoluteString]];
    }
  }
  
  stringForm = [[files arrayByAddingObjectsFromArray:urlstrings] componentsJoinedByString:@"\n"];

  { NSMutableArray *types = [NSMutableArray arrayWithCapacity:3];
    if ([files count]) [types addObject:NSFilenamesPboardType];
    if ([urls count] == 1) [types addObject:NSURLPboardType];
    if ([stringForm length]) [types addObject:NSStringPboardType];
    [pboard declareTypes:types owner:nil];
  }

  if ([files count]) 
    [pboard setPropertyList:files forType:NSFilenamesPboardType];
    
  if ([urls count] == 1)
    [[urls objectAtIndex:0] writeToPasteboard:pboard];

  if ([stringForm length]) 
    [pboard setString:stringForm forType:NSStringPboardType];

  return YES;
}

- (id)outlineView:(NSOutlineView *)sender persistentObjectForItem:(id)item {
  return [NSNumber numberWithInt:[categories indexOfObject:item]];
}

- (id)outlineView:(NSOutlineView *)sender itemForPersistentObject:(id)object {
  return [object intValue] < [categories count] ? [categories objectAtIndex:[object intValue]] : nil;
}

// ---

- (NSArray *)categories {
  return [[categories copy] autorelease];
}

- (BOOL)isEditableItem:(id)item atKey:(id <NSObject>)key {
  if ([item isKindOfClass:[MWLibraryCategory class]]) {
    return NO;
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    return [(id <MWLibraryItem>)item libItemIsEditableAtKey:key];
  } else {
    return NO;
  }
}

@end
