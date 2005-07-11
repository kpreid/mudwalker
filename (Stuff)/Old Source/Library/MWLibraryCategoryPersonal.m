/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryCategoryPersonal.h"

#import <MudWalker/MWUtilities.h>
#import "MWLibraryEntry.h"

@implementation MWLibraryCategoryPersonal

static NSDictionary *builtinEntries = nil;

+ (void)initialize {
  if (!builtinEntries)
    builtinEntries = [NSDictionary dictionaryWithContentsOfFile:fileName];
}

- (id)init {
  NSEnumerator *iE;
  NSDictionary *i;
  if (!(self = [super init])) return nil;

  items = [[NSMutableArray allocWithZone:[self zone]] init];

  iE = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"MWPersonalLibrary"] objectEnumerator];
  
  while ((i = [iE nextObject])) {
    [items addObject:[[[MWLibraryURLEntry allocWithZone:[self zone]] initWithCategory:self info:i] autorelease]];
  }

  return self;
}

- (void)dealloc {
  [items release]; items = nil;
  [super dealloc];
}

- (void)writeToDefaults {
  NSEnumerator *iE = [items objectEnumerator];
  MWLibraryURLEntry *i;
  NSMutableArray *data = [NSMutableArray array];
  
  while ((i = [iE nextObject])) {
    [data addObject:[[[i infoDict] copy] autorelease]];
  }

  [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"MWPersonalLibrary"];
}

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  if ([key isEqual:@"name"]) {
    return MWLocalizedStringHere(@"Library Category Personal");
  } else {
    return [super objectForKey:key];
  }
}

- (int)libItemNumberOfChildren {
  return [items count];
}
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index {
  return [items objectAtIndex:index];
}
- (BOOL)childrenAreEditable { return YES; }

- (void)childWasEdited:(MWLibraryEntry *)child {
  int index = [items indexOfObject:child];
  
  if (index == NSNotFound) return;
  
  [self writeToDefaults];
}

@end
