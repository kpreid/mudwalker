/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWMudLibrary.h"

#import <MudWalker/MudWalker.h>
#import <AppKit/AppKit.h>

#import "MWConnectionDocument.h"

#import "MWLibraryItem.h"

NSString *MWLibraryDidChangeNotification = @"MWLibraryDidChangeNotification";

@interface MWMudLibrary (Private)

- (void)updateFromDefaults:(NSNotification *)notif;

@end

@implementation MWMudLibrary

+ (void)initialize {
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultLibrary" ofType:@"plist"]], @"MWLibraryAddresses",
    nil
  ]];
}

- (MWMudLibrary *)initWithUserDefaults:(NSUserDefaults *)ud { // designated initializer
  if (!(self = [super init])) return nil;

  userDefaults = [ud retain];
  [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(updateFromDefaults:) name:NSUserDefaultsDidChangeNotification object:userDefaults];
  //[self updateFromDefaults:nil];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:userDefaults];
  [outlineItems autorelease]; outlineItems = nil;
  [itemKeys autorelease]; itemKeys = nil;
  [userDefaults autorelease]; userDefaults = nil;
  [lastSeenDefaultsEntry autorelease]; lastSeenDefaultsEntry = nil;
  [super dealloc];
}

- (void)noticeDocument:(MWConnectionDocument *)doc {
  BOOL dirty = NO;

  NSMutableDictionary *adict = [[[userDefaults dictionaryForKey:@"MWLibraryAddresses"] mutableCopy] autorelease];
  
  NSString *const key = [[[doc config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]] absoluteString];
  
  if (![key length])
    return;
  
  NSMutableDictionary *info = [[[adict objectForKey:key] mutableCopy] autorelease];
  
  if (!info) {
    info = [NSMutableDictionary dictionary];
    dirty = YES;
  }
  
  NSMutableArray *documents = [[[info objectForKey:@"documentURLs"] mutableCopy] autorelease];
  
  if (!documents)
    documents = [NSMutableArray array];
    
  if ([doc fileName]) {
    // make sure that the document is present in the array, at the beginning
    unsigned existingIndex = [documents indexOfObject:[[NSURL fileURLWithPath:[doc fileName]] absoluteString]];
    if (existingIndex != 0) {
      if (existingIndex != NSNotFound)
        [documents removeObjectAtIndex:existingIndex];
      [documents insertObject:[[NSURL fileURLWithPath:[doc fileName]] absoluteString] atIndex:0];
      dirty = YES;
    }
  }
  
  // add info about the document
  
  if ([doc fileName] && ![(NSString *)[info objectForKey:@"name"] length]) {
    [info setObject:[doc displayName] forKey:@"name"];
    dirty = YES;
  } else if (![info objectForKey:@"name"]) {
    [info setObject:@"" forKey:@"name"];
    dirty = YES;
  }
  
  NSURL *website = [[doc config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil]];
  if (website && ![[info objectForKey:@"web"] isEqual:[website absoluteString]]) {
    [info setObject:[website absoluteString] forKey:@"web"];
    dirty = YES;
  } else if (![info objectForKey:@"web"]) {
    [info setObject:@"" forKey:@"web"];
    dirty = YES;
  }
    

  
  // everything after here is just saving the changes into the defaults db, so skip it if we didn't really change anything
  if (!dirty)
    return;
  
  [info setObject:documents forKey:@"documentURLs"];
    
  [adict setObject:[[info copy] autorelease] forKey:key];
    
  [userDefaults setObject:[[adict copy] autorelease] forKey:@"MWLibraryAddresses"];
  [self updateFromDefaults:nil];
}

- (NSDictionary *)libraryData {
  id nowSeen = [userDefaults dictionaryForKey:@"MWLibraryAddresses"];
  
  // lastSeenDefaultsEntry is used so that we can tell whether or not the defaults database's changes are actually of interest to us
  if (nowSeen != lastSeenDefaultsEntry) {
    [lastSeenDefaultsEntry release];
    lastSeenDefaultsEntry = [nowSeen retain];
  }
  return nowSeen;
}

static int sortByNameKey(id a, id b, void *context) {
  return [
    [a objectForKey:@"name"]
    caseInsensitiveCompare:
    [b objectForKey:@"name"]
  ];
}

- (void)updateOutlineItems {
  if (!outlineItems)
    outlineItems = [[NSMutableArray alloc] init];
  if (!itemKeys)
    itemKeys = [[NSMutableDictionary alloc] init];

  NSEnumerator *const adrStrE = [[self libraryData] keyEnumerator];
  NSString *adrStr;
  while ((adrStr = [adrStrE nextObject])) {
    NSURL *const url = [NSURL URLWithString:adrStr];
    if (!url)
      continue;
    if (![itemKeys objectForKey:url]) {
      id const item = [[[MWLibraryAddressItem alloc] initWithAddress:url userDefaults:userDefaults] autorelease];
      [itemKeys setObject:item forKey:url];
      [outlineItems addObject:item];
    } else {
      [[itemKeys objectForKey:url] reloadData];
    }
  }
  
  NSEnumerator *const urlE = [itemKeys keyEnumerator];
  NSURL *url;
  while ((url = [urlE nextObject])) {
    if (![[self libraryData] objectForKey:[url absoluteString]]) {
      [outlineItems removeObject:[itemKeys objectForKey:url]];
      [itemKeys removeObjectForKey:url];
    }
  }

  [outlineItems sortUsingFunction:sortByNameKey context:NULL];
}

- (NSArray *)outlineItems {
  if (!outlineItems)
    [self updateOutlineItems];
  return outlineItems;
}

- (void)updateFromDefaults:(NSNotification *)notif {
  id nowSeen = [userDefaults dictionaryForKey:@"MWLibraryAddresses"];
  
  // the defaults database doesn't tell us what changed - only update if the thing we're interested in is different
  if (nowSeen != lastSeenDefaultsEntry && ![nowSeen isEqual:lastSeenDefaultsEntry]) {
    [self updateOutlineItems];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLibraryDidChangeNotification object:self];
  }
}

// --- Outline view data source ---

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) {
    // the root
    return [[self outlineItems] count];
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    //NSLog(@"%@ %i children", item, [(id <MWLibraryItem>)item libItemNumberOfChildren]);
    return [(id <MWLibraryItem>)item libItemNumberOfChildren];
  } else {
    return 0;
  }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
  if (!item) {
    // the root
    return [[self outlineItems] objectAtIndex:index];
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    //NSLog(@"%@ %i => %@", item, index, [(id <MWLibraryItem>)item libItemChildAtIndex:index]);
    return [(id <MWLibraryItem>)item libItemChildAtIndex:index];
  } else {
    return nil;
  }
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item {
  if (!item) {
    return YES;
  } else if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    //NSLog(@"%@ expandable %i", item, (int)[(id <MWLibraryItem>)item libItemHasChildren]);
    return [(id <MWLibraryItem>)item libItemHasChildren];
  } else {
    return NO;
  }
}

- (id)outlineView:(NSOutlineView *)sender objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return [item objectForKey:[tableColumn identifier]];
}

- (void)outlineView:(NSOutlineView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  id ident = [tableColumn identifier];
  if ([item respondsToSelector:@selector(setObject:forKey:)]) {
    [item setObject:newVal forKey:ident];
  } else {
    NSBeep();
  }
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
  //NSLog(@"persist %@", item);
  if ([item isKindOfClass:[MWLibraryAddressItem class]]) {
    return [[item serverURL] absoluteString];
  //} else if ([item isKindOfClass:[MWLibraryDocumentItem class]]) {
  //  return [NSString stringWithFormat:@"%@ %@", [[item documentURL] absoluteString], [[item documentURL] absoluteString]];
  } else {
    return nil;
  }
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
  //NSLog(@"unpersist %@", object);
  NSEnumerator *itemE = [[self outlineItems] objectEnumerator];
  id <NSObject, MWLibraryItem> item;
  while ((item = [itemE nextObject])) {
    if ([item respondsToSelector:@selector(serverURL)] && [[[(id)item serverURL] absoluteString] isEqual:object])
      return item;
    //if ([item respondsToSelector:@selector(documentURL)] && [[[(id)item documentURL] absoluteString] isEqual:object])
    //  return item;
  }
  return nil;
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

- (BOOL)isEditableItem:(id)item atKey:(id <NSObject>)key {
  if ([item conformsToProtocol:@protocol(MWLibraryItem)]) {
    return [(id <MWLibraryItem>)item libItemIsEditableAtKey:key];
  } else {
    return NO;
  }
}

- (void)forgetAddress:(NSURL *)url {
  NSMutableDictionary *adict = [[[userDefaults dictionaryForKey:@"MWLibraryAddresses"] mutableCopy] autorelease];
  [adict removeObjectForKey:[url absoluteString]];
  [userDefaults setObject:[[adict copy] autorelease] forKey:@"MWLibraryAddresses"];
  [self updateFromDefaults:nil];
}

- (void)forgetDocument:(NSURL *)docURL forAddress:(NSURL *)address {
  NSMutableDictionary *adict = [[[userDefaults dictionaryForKey:@"MWLibraryAddresses"] mutableCopy] autorelease];
  
  NSString *const key = [address absoluteString];
  
  NSMutableDictionary *info = [[[adict objectForKey:key] mutableCopy] autorelease];
  
  if (!info) return;

  NSMutableArray *documents = [[[info objectForKey:@"documentURLs"] mutableCopy] autorelease];
  
  if (!documents) return;
    
  [documents removeObject:[docURL absoluteString]];
  
  [info setObject:documents forKey:@"documentURLs"];
    
  [adict setObject:[[info copy] autorelease] forKey:key];
    
  [userDefaults setObject:[[adict copy] autorelease] forKey:@"MWLibraryAddresses"];
  [self updateFromDefaults:nil];
}


// --- Root item ---

- (id <NSObject>)objectForKey:(id <NSObject>)key { return nil; }
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {}
- (NSImage *)libItemImage { return nil; }

- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key { return NO; }

- (BOOL)libItemHasChildren { return YES; }
- (int)libItemNumberOfChildren { return [[self outlineItems] count]; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index { return [[self outlineItems] objectAtIndex:index]; }

- (BOOL)canPerformOpenAction { return NO; }
- (IBAction)performOpenAction:(id)sender {}

- (void)removeFromLibrary {}


@end
