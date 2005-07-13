/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryCategoryRecent.h"

#import <MudWalker/MWUtilities.h>
#import <AppKit/AppKit.h>
#import "MWConnectionDocument.h"
#import "MWLibraryEntry.h";

@interface MWLibraryCategoryRecent (Private)

- (void)loadData;

@end

@implementation MWLibraryCategoryRecent

- (id)init {
  if (!(self = [super init])) return nil;
  
  [self loadData];
  
  return self;
}

- (void)dealloc {
  [cacheRecentDocumentURLs release]; cacheRecentDocumentURLs = nil;
  [super dealloc];
}

- (void)loadData {
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSMutableArray *a = [NSMutableArray array];
  NSEnumerator *ue = [[dc recentDocumentURLs] objectEnumerator];
  NSURL *url;

  [cacheRecentDocumentURLs release];
  
  while ((url = [ue nextObject])) {
    if ([MWConnectionDocument isNativeType:[dc typeFromFileExtension:[[url path] pathExtension]]])
      [a addObject:[[[MWLibraryDocumentEntry alloc] initWithCategory:self URL:url] autorelease]];
  }
  
  cacheRecentDocumentURLs = [a copy];
}

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  if ([key isEqual:@"name"]) {
    return MWLocalizedStringHere(@"Library Category Recent");
  } else {
    return [super objectForKey:key];
  }
}

- (int)libItemNumberOfChildren { return [cacheRecentDocumentURLs count]; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index {
  return [cacheRecentDocumentURLs objectAtIndex:index];
}
- (BOOL)childrenAreEditable { return NO; }

@end
