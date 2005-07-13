/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

#import <AppKit/NSNibDeclarations.h>

extern NSString *MWLibraryDidChangeNotification;

@class NSImage, MWConnectionDocument;

@protocol MWLibraryItem
  - (id <NSObject>)objectForKey:(id <NSObject>)key;
  - (void)setObject:(id <NSObject>)obj forKey:(id <NSObject>)key;
  - (NSImage *)libItemImage;

  - (BOOL)libItemIsEditableAtKey:(id <NSObject>)key;
  
  - (BOOL)libItemHasChildren;
  - (int)libItemNumberOfChildren;
  - (id <NSObject, MWLibraryItem>)libItemChildAtIndex:(int)index;
  
  - (BOOL)canPerformOpenAction;
  - (IBAction)performOpenAction:(id)sender;
  
  - (void)removeFromLibrary;
@end

@interface MWMudLibrary : NSObject <MWLibraryItem> {
  NSUserDefaults *userDefaults;
  NSMutableArray *outlineItems;
  NSMutableDictionary *itemKeys;
  id lastSeenDefaultsEntry;
}

- (id)initWithUserDefaults:(NSUserDefaults *)ud;

//- (NSArray *)categories;
- (BOOL)isEditableItem:(id)item atKey:(id <NSObject>)key;

- (void)noticeDocument:(MWConnectionDocument *)doc;

- (void)forgetAddress:(NSURL *)url;
- (void)forgetDocument:(NSURL *)docURL forAddress:(NSURL *)address;

@end
