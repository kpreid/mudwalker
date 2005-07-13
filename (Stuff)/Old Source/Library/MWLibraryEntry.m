/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryEntry.h"

#import "MWLibraryCategory.h"
#import "MWAppDelegate.h"
#import <AppKit/AppKit.h>

@implementation MWLibraryEntry

- (id)initWithCategory:(MWLibraryCategory *)category {
  if (!(self = [super init])) return nil;
  
  parent = category;
  
  return self;
}

- (void)dealloc {
  parent = nil;
  [super dealloc];
}

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  return nil;
}
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {}

- (NSImage *)libItemImage { return nil; }

- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key {
  return [parent childrenAreEditable];
}

- (BOOL)libItemHasChildren { return NO; }
- (int)libItemNumberOfChildren { return 0; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index { return nil; }
- (BOOL)childrenAreEditable { return NO; }

- (BOOL)canPerformOpenAction { return NO; }
- (void)performOpenAction {}

@end

@implementation MWLibraryURLEntry

- (id)initWithCategory:(MWLibraryCategory *)category info:(NSDictionary *)newInfo {
  if (!(self = [super initWithCategory:category])) return nil;
  
  info = [newInfo mutableCopy];
  
  return self;
}

- (void)dealloc {
  [info autorelease]; info = nil;
  [super dealloc];
}

- (NSURL *)serverURL { return [NSURL URLWithString:[self objectForKey:@"location"]]; }

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  return [info objectForKey:key];
}
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {
  [info setObject:obj forKey:key];
  [parent childWasEdited:self];
}

- (NSImage *)libItemImage {
  static NSImage *urlImage = nil;
  // fixme: ack, accessing privateish system stuff
  if (!urlImage)
    urlImage = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Dock.app/Contents/Resources/url.png"];
  return urlImage;
}

- (NSMutableDictionary *)infoDict { return info; }

- (BOOL)canPerformOpenAction { return YES; }
- (void)performOpenAction {
  [(MWAppDelegate *)[NSApp delegate] makeDocumentForURL:[NSURL URLWithString:[self objectForKey:@"location"]] connect:NO];
}

@end

@implementation MWLibraryDocumentEntry

- (id)initWithCategory:(MWLibraryCategory *)category URL:(NSURL *)url {
  if (!(self = [super initWithCategory:category])) return nil;
  
  docURL = [url retain];
  docImage = [[[NSWorkspace sharedWorkspace] iconForFileType:[[url path] pathExtension]] retain];
  
  return self;
}

- (void)dealloc {
  [docURL release]; docURL = nil;
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

- (NSImage *)libItemImage {
  return docImage;
}


- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key { return NO; }

- (BOOL)canPerformOpenAction { return YES; }
- (void)performOpenAction {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self objectForKey:@"location"] display:YES];
}

@end
