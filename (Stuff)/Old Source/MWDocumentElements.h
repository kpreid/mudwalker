/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWDocumentElements is a 'container' for an ordered dictionary of things in a document, and provides notifications when they change.
\*/

#import <Cocoa/Cocoa.h>

@class MWConnectionDocument;

extern NSString *MWDocumentElementsChangedNotification;

@interface MWDocumentElements : NSObject {
  NSDocument *document;
  NSMutableDictionary *elements;
  NSMutableDictionary *prevElements;
  NSMutableArray *ordering;
}

- (MWDocumentElements *)init;
- (MWDocumentElements *)initWithDocument:(NSDocument *)document;
  // designated initializer

- (NSDictionary *)convertToDictionaryForStorage;
- (void)restoreFromDictionaryForStorage:(NSDictionary *)dict;

// Data access
- (unsigned)count;
- (NSArray *)orderedKeys;
- (NSEnumerator *)keyEnumerator;
- (id)nonexistentKey;
- (id)keyAtIndex:(unsigned)index;
- (unsigned)indexOfKey:(id)key;
- (id)objectAtIndex:(unsigned)index;
- (void)removeObjectAtIndex:(unsigned)index;
- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)removeObjectForKey:(id)key;

// Use these to register changes in mutable objects stored in the MWDocumentElements.
/* Use these ONLY IF ALL OF THE FOLLOWING ARE TRUE:
  The objects are mutable.
  The objects do not themselves register undo actions.
  In this case, the objects MUST implement NSMutableCopying. 
*/
- (void)willChangeObjectForKey:(id)key;
- (void)changedObjectForKey:(id)key;

// Accessors
- (NSUndoManager *)undoManager;
- (NSDocument *)document;

@end
