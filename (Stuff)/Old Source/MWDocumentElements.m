/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWDocumentElements.h"

#import <MudWalker/MudWalker.h>

NSString *MWDocumentElementsChangedNotification = @"MWDocumentElementsChangedNotification";

NSString *OrderingKey = @"_MWDocumentElements_Ordering";

@implementation MWDocumentElements

- (MWDocumentElements *)init {return [self initWithDocument:nil];}

- (MWDocumentElements *)initWithDocument:(NSDocument *)doc {  
  if (!(self = [super init])) return nil;
  
  document = [doc retain];
  elements = [[NSMutableDictionary allocWithZone:[self zone]] init];
  prevElements = [[NSMutableDictionary allocWithZone:[self zone]] init];
  ordering = [[NSMutableArray allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [[self undoManager] removeAllActionsWithTarget:self];
  [document release]; document = nil;
  [elements release]; elements = nil;
  [prevElements release]; prevElements = nil;
  [ordering release]; ordering = nil;
  [super dealloc];
}

- (NSDictionary *)convertToDictionaryForStorage {
  NSEnumerator *enumerator = [elements keyEnumerator];
  id key;
  NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];

  while ((key = [enumerator nextObject])) {
    id value = [elements objectForKey:key];
    {
      [resultDict setObject:[value copy] forKey:key];
    }
  }
  [resultDict setObject:ordering forKey:OrderingKey];
  return resultDict;
}

- (void)restoreFromDictionaryForStorage:(NSDictionary *)dict {
  NSEnumerator *enumerator = [dict keyEnumerator];
  id key;
  
  while ((key = [enumerator nextObject])) {
    id value = [dict objectForKey:key];
    if ([key isEqual:OrderingKey]) {
      [ordering setArray:value];
    } else {
      [elements setObject:value forKey:key];
    }
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:MWDocumentElementsChangedNotification object:self userInfo:nil];
}

// --- Data access, general ---

- (unsigned)count {
  return [elements count];
}

// --- Data access, special ---

- (NSArray *)orderedKeys {
  return [[ordering copy] autorelease];
}

- (NSEnumerator *)keyEnumerator {
  return [[ordering copy] objectEnumerator];
}

- (id)nonexistentKey {
  unsigned long kI = 0;
  NSString *kS = [NSString stringWithFormat:@"%lu", kI];
  while ([elements objectForKey:kS]) {
    kI++;
    kS = [NSString stringWithFormat:@"%lu", kI];
  }
  return kS;
}

- (id)keyAtIndex:(unsigned)index {
  return [ordering objectAtIndex:index];
}

- (unsigned)indexOfKey:(id)key {
  return [ordering indexOfObject:key];
}

- (void)willChangeObjectForKey:(id)key {
  [prevElements setObject:[[elements objectForKey:key] mutableCopy] forKey:key];
}

- (void)changedObjectForKey:(id)key {
  if (!key) return;
  [[[self undoManager] prepareWithInvocationTarget:self]
    setObject:[prevElements objectForKey:key]
    forKey:key
  ];
  [prevElements removeObjectForKey:key];
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:MWDocumentElementsChangedNotification
    object:self
    userInfo:[NSDictionary dictionaryWithObject:key forKey:@"key"]];
}

// --- Data access, array-like ---

- (id)objectAtIndex:(unsigned)index {
  return [elements objectForKey:[ordering objectAtIndex:index]];
}

- (void)removeObjectAtIndex:(unsigned)index {
  [self removeObjectForKey:[ordering objectAtIndex:index]];
}

// --- Data access, dictionary-like ---

- (id)objectForKey:(id)key {
  return [elements objectForKey:key];
}

- (void)setObject:(id)value forKey:(id)key {
  id oldValue = [elements objectForKey:key];
  
  NSParameterAssert(key != nil);
  
  if (oldValue) {
    [[[self undoManager] prepareWithInvocationTarget:self]
      setObject:oldValue
      forKey:key
    ];
  } else {
    [[[self undoManager] prepareWithInvocationTarget:self]
      removeObjectForKey:key
    ];
    [ordering addObject:key];
  }
  
  [elements setObject:value forKey:key];
  
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:MWDocumentElementsChangedNotification
    object:self
    userInfo:oldValue ? [NSDictionary dictionaryWithObject:key forKey:@"key"] : [NSDictionary dictionaryWithObjectsAndKeys:key, @"key", [NSNumber numberWithBool:YES], @"orderingChanged", nil]];
}

- (void)removeObjectForKey:(id)key {
  id oldValue = [elements objectForKey:key];
  
  NSParameterAssert(key != nil);
  
  if (oldValue) {
    [[[self undoManager] prepareWithInvocationTarget:self]
      setObject:oldValue
      forKey:key
    ];
    // FIXME: should have a setObject:forKey:insertIndex: method and use it here
  }
  
  [elements removeObjectForKey:key];
  [ordering removeObject:key];
  
  if (oldValue) {
    [[NSNotificationCenter defaultCenter] 
      postNotificationName:MWDocumentElementsChangedNotification
      object:self
      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:key, @"key", [NSNumber numberWithBool:YES], @"orderingChanged", nil]];
  }
}

// --- Accessors ---

- (NSUndoManager *)undoManager {return [[self document] undoManager];}
- (NSDocument *)document {return document;}

@end
