/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

@class NSImage;

@protocol MWLibraryItem
  - (id <NSObject>)objectForKey:(id <NSObject>)key;
  - (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key;
  - (NSImage *)libItemImage;

  - (BOOL)libItemIsEditableAtKey:(id <NSObject>)key;
  
  - (BOOL)libItemHasChildren;
  - (int)libItemNumberOfChildren;
  - (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index;
  
  - (BOOL)canPerformOpenAction;
  - (void)performOpenAction;
@end

@interface MWMudLibrary : NSObject {
  NSMutableArray *entries;
}

- (NSArray *)categories;
- (BOOL)isEditableItem:(id)item atKey:(id <NSObject>)key;

@end
