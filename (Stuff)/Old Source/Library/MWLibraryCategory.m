/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryCategory.h"

#import <AppKit/NSWorkspace.h>

@implementation MWLibraryCategory

- (id <NSObject>)objectForKey:(id <NSObject>)key {
  if ([key isEqual:@"name"] || [key isEqual:@"type"]) {
    return @"Category";
  } else {
    return @"";
  }
}
- (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key {}

- (NSImage *)libItemImage {
  return [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle bundleForClass:[self class]] resourcePath]];
  // doesn't work:
  return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode('fold')];
}

- (BOOL)libItemIsEditableAtKey:(id <NSObject>)key { return NO; }

- (BOOL)libItemHasChildren { return YES; }
- (int)libItemNumberOfChildren { return 0; }
- (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index { return nil; }
- (BOOL)childrenAreEditable { return NO; }

- (void)childWasEdited:(MWLibraryEntry *)child {}

- (BOOL)canPerformOpenAction { return NO; }
- (void)performOpenAction {}

@end
