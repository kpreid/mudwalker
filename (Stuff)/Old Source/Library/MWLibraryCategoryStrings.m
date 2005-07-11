/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryCategoryStrings.h"

#import "MWLibraryEntry.h"

static int sortByNameKey(id a, id b, void *context) {
  return [
    [a objectForKey:@"name"]
    caseInsensitiveCompare:
    [b objectForKey:@"name"]
  ];
}

@implementation MWLibraryCategoryStrings

- (MWLibraryCategoryStrings *)initWithDisplayName:(NSString *)dn fileName:(NSString *)fn {
  if (!(self = [super init])) return nil;
  
  displayName = [dn retain];
  fileName = [fn retain];

  return self;
}

- (void)dealloc {
  [displayName autorelease]; displayName = nil;
  [fileName autorelease]; fileName = nil;
  [fileItems autorelease]; fileItems = nil;
  [super dealloc];
}

- (void)loadFile {
  if (fileItems) return;
  
  {
    NSDictionary *raw = [NSDictionary dictionaryWithContentsOfFile:fileName];

    NSEnumerator *e = [raw keyEnumerator];
    NSString *key;
    fileItems = [[NSMutableArray allocWithZone:[self zone]] init];
    while ((key = [e nextObject])) {
      NSMutableDictionary *info = [[[raw objectForKey:key] mutableCopy] autorelease];
      [info setObject:key forKey:@"name"];
      [fileItems addObject:[[[MWLibraryURLEntry allocWithZone:[self zone]] initWithCategory:self info:info] autorelease]];
    }
    [fileItems sortUsingFunction:sortByNameKey context:NULL];
  }
  
  readOnly = ![[NSFileManager defaultManager] isWritableFileAtPath:fileName];
}

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  if ([key isEqual:@"name"]) {
    return displayName;
  } else {
    return [super objectForKey:key];
  }
}

- (int)libItemNumberOfChildren { [self loadFile]; return [fileItems count]; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index {
  [self loadFile];
  return [fileItems objectAtIndex:index];
}
- (BOOL)childrenAreEditable { return !readOnly; }

@end
