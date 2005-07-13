/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWConfigTree manages a virtual tree structure that is actually flat, and undoable.
 *
 * Whenever a change is made to the tree, a NSNotification is posted to the default notification center with name MWConfigSupplierChangedNotification and userInfo containing the changed path in key @"path". Note that if you are displaying a list of keys in a directory, the list must be updated if you get a change notification for the path of the directory, OR the path of any key immediately below it.
 *
 * IMPORTANT: If a change notification has no path specified, then you must assume the entire tree has changed.
\*/

#import <Foundation/Foundation.h>
#import "MWConfigSupplier.h"

@interface MWConfigTreeDirectory : NSObject <NSCoding> {
 @private
  NSMutableArray *inner; void *extend;
}
@end

@interface MWConfigTree : NSObject <MWConfigSupplier, NSCopying, NSMutableCopying, NSCoding> {
  NSUndoManager *undoManager;
  NSMutableDictionary *store;
  void *MWConfigTree_future1;
  void *MWConfigTree_future2;
  void *MWConfigTree_future3;
}

/* These methods are defined in MWConfigSupplier, included here for reference:
  - (id)objectAtPath:(MWConfigPath *)path;
  - (id)objectAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path;
  - (NSString *)keyAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path;
  - (BOOL)isDirectoryAtPath:(MWConfigPath *)path;
  
  - (unsigned)countAtPath:(MWConfigPath *)path;
  - (NSArray *)allKeysAtPath:(MWConfigPath *)path;
  - (NSArray *)allValuesAtPath:(MWConfigPath *)path;
*/

/* Return an unspecified key string which does not exist at the given path. The key is guaranteed to be reasonably unique, even among multiple config trees. */
- (NSString *)nonexistentKeyAtPath:(MWConfigPath *)path;
/* Return a path which does not exist and is the given path plus one unspecified component. */
- (MWConfigPath *)nonexistentPathAtPath:(MWConfigPath *)path;

/* An insertIndex of -1 means insert at the end. */

/* Insert an object in the tree, possibly replacing an existing one. */
- (void)setObject:(id<NSObject>)object atPath:(MWConfigPath *)path;
- (void)setObject:(id<NSObject>)object forKey:(NSString *)key atPath:(MWConfigPath *)path;
/* If a key already exists and the insertIndex is different, then it will be moved to the new index (as determined *before* the old item is removed). */
- (void)setObject:(id<NSObject>)object atPath:(MWConfigPath *)path insertIndex:(int)index;
- (void)setObject:(id<NSObject>)object forKey:(NSString *)key atPath:(MWConfigPath *)path insertIndex:(int)index;
- (void)addEntriesFromDictionary:(NSDictionary *)objects atPath:(MWConfigPath *)path insertIndex:(int)index;
/* Insert everything in another tree into this one in a subdirectory. */
- (void)addEntriesFromTree:(MWConfigTree *)source atPath:(MWConfigPath *)destPrefix insertIndex:(int)index;
/* Create a directory. If recurse is true, then it will create multiple levels of directories if necessary */
- (void)addDirectoryAtPath:(MWConfigPath *)innerPath recurse:(BOOL)recurse insertIndex:(int)index;
/* Delete the specified item. If recurse is false, then an exception will be raised if the item is a directory and the directory is not empty. */
- (void)removeItemAtPath:(MWConfigPath *)innerPath recurse:(BOOL)recurse;

/* Copy the contents of a directory in another tree to this tree. Both directories must exist. If the destination directory already contains some of the copied keys, directories are recursively merged. If this results in a object/directory mismatch, the copy may be aborted midway. */
- (void)copyContentsOfDirectory:(MWConfigPath *)sourcePath from:(id <MWConfigSupplier, NSObject>)replacement toDirectory:(MWConfigPath *)destPath insertIndex:(int)insertIndex;

/* Make a new tree with part of this one. */
- (MWConfigTree *)subtreeFromDirectoryAtPath:(MWConfigPath *)path;
/* Replace the entire contents of this tree with the given tree or other supplier. */
- (void)setConfig:(id <MWConfigSupplier, NSObject>)replacement;

- (NSUndoManager *)undoManager;
- (void)setUndoManager:(NSUndoManager *)newVal;

- (NSString *)descriptionWithLocale:(NSDictionary *)locale;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level;

@end
