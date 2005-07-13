/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryItem.h"

#import "MWAppDelegate.h"
#import <AppKit/AppKit.h>

@implementation MWLibraryAddressItem

- (id)initWithAddress:(NSURL *)nadr userDefaults:(NSUserDefaults *)ud {
  if (!(self = [super init])) return nil;
  
  address = [nadr retain];
  userDefaults = [ud retain];
  
  return self;
}

- (void)dealloc {
  [address autorelease]; address = nil;
  [documentItems autorelease]; documentItems = nil;
  [userDefaults autorelease]; userDefaults = nil;
  [super dealloc];
}

- (NSURL *)serverURL { return address; }

#if 0 /* unused */
static int sortByNameKey(id a, id b, void *context) {
  return [
    [a objectForKey:@"name"]
    caseInsensitiveCompare:
    [b objectForKey:@"name"]
  ];
}
#endif
- (NSArray *)documentItems {
  if (!documentItems) {
    NSDictionary *const myInfo = [[userDefaults objectForKey:@"MWLibraryAddresses"] objectForKey:[address absoluteString]];

    documentItems = [[NSMutableArray alloc] init];
    NSEnumerator *const docE = [[myInfo objectForKey:@"documentURLs"] objectEnumerator];
    NSString *doc;
    while ((doc = [docE nextObject])) {
      NSURL *const url = [NSURL URLWithString:doc];
      if (!url)
        continue;
      [documentItems addObject:[[[MWLibraryDocumentItem alloc] initWithDocumentURL:url forAddress:address] autorelease]];
    }
    //[documentItems sortUsingFunction:sortByNameKey context:NULL];
  }
  return documentItems;
}

- (void)reloadData {
  [documentItems release]; documentItems = nil;
}

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  if ([key isEqual:@"location"])
    return [address absoluteString];
  else
    return [[[userDefaults objectForKey:@"MWLibraryAddresses"] objectForKey:[address absoluteString]] objectForKey:key];
}
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {
  NSMutableDictionary *const addresses = [[[userDefaults objectForKey:@"MWLibraryAddresses"] mutableCopy] autorelease];
  
  NSString *const adrKey = [address absoluteString];
  
  NSMutableDictionary *const info = [[[addresses objectForKey:adrKey] mutableCopy] autorelease];

  [info setObject:obj forKey:key];
  
  [addresses setObject:info forKey:adrKey];
    
  [userDefaults setObject:addresses forKey:@"MWLibraryAddresses"];
}

- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key {
  if ([key isEqual:@"location"]) {
    return NO;
  } else {
    return YES;
  }
}

- (NSImage *)libItemImage {
  if ([self libItemNumberOfChildren]) {
    return [[self libItemChildAtIndex:0] libItemImage];
  } else {
    static NSImage *urlImage = nil;
    // fixme: ack, accessing privateish system stuff
    if (!urlImage)
      urlImage = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Dock.app/Contents/Resources/url.png"];
    return urlImage;
  }
}

- (BOOL)libItemHasChildren { return [[self documentItems] count] > 0; }
- (int)libItemNumberOfChildren { return [[self documentItems] count]; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index { return [[self documentItems] objectAtIndex:index]; }

- (BOOL)canPerformOpenAction { return YES; }
- (IBAction)performOpenAction:(id)sender {
  if ([self libItemNumberOfChildren])
    [[self libItemChildAtIndex:0] performOpenAction:nil];
  else
    [(MWAppDelegate *)[NSApp delegate] makeDocumentForURL:[NSURL URLWithString:(NSString *)[self objectForKey:@"location"]] connect:NO];
}

- (void)removeFromLibrary {
  [[(MWAppDelegate *)[NSApp delegate] mudLibrary] forgetAddress:address];
}

@end

@implementation MWLibraryDocumentItem

- (id)initWithDocumentURL:(NSURL *)url forAddress:(NSURL *)nadr {
  if (!(self = [super init])) return nil;
  
  docURL = [url retain];
  address = [nadr retain];
  docImage = [[[NSWorkspace sharedWorkspace] iconForFileType:[[url path] pathExtension]] retain];
  
  return self;
}

- (void)dealloc {
  [address autorelease]; address = nil;
  [docURL autorelease]; docURL = nil;
  [docImage autorelease]; docImage = nil;
  [super dealloc];
}

- (NSURL *)documentURL { return docURL; }

- (id <NSObject>)objectForKey:(id <NSObject>)key {
 if ([key isEqual:@"name"]) {
    return [[[docURL path] lastPathComponent] stringByDeletingPathExtension];
  } else if ([key isEqual:@"type"]) {
    return NSLocalizedString(@"Document", @"Type of document entries in library");
  } else if ([key isEqual:@"location"]) {
    if ([[docURL scheme] isEqual:@"file"]) {
      return [[docURL path] stringByAbbreviatingWithTildeInPath];
    } else {
      return docURL;
    }
  } else {
    return @"";
  }
}
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {
}

- (NSImage *)libItemImage {
  return docImage;
}

- (BOOL)libItemHasChildren { return NO; }
- (int)libItemNumberOfChildren { return 0; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index { return nil; }

- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key { return NO; }

- (BOOL)canPerformOpenAction { return YES; }
- (IBAction)performOpenAction:(id)sender {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:docURL display:YES];
}

- (void)removeFromLibrary {
  [[(MWAppDelegate *)[NSApp delegate] mudLibrary] forgetDocument:docURL forAddress:address];
}

@end
