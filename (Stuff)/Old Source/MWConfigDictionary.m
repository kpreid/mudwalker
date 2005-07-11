/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigDictionary.h"

#import "MWConstants.h"

@implementation MWConfigDictionary

- (MWConfigDictionary *)init {
  if (!(self = [super init])) return nil;
  
  nodeData = [[NSMutableDictionary allocWithZone:[self zone]] init];
  if (!nodeData) {
    [self release];
    return nil;
  }
  
  return self;
}

- (void)dealloc {
  [[self undoManager] removeAllActionsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
  [nodeData autorelease]; nodeData = nil;
  [super dealloc];
}

// --- Config node protocol ---

- (void)didBecomeChildOfConfigNode:(id <MWConfigNode>)parent {
  parentNode = parent; // NOT RETAINED
}

- (void)didBecomeOrphanConfigNode {
  parentNode = nil;
}

- (NSUndoManager *)undoManager { return [parentNode undoManager]; }

- (id <MWConfigNode>)parentConfigNode { return [[parentNode retain] autorelease]; }

// --- Dictionary implementation ---

- (unsigned int)count {
  return [nodeData count];
}

- (NSEnumerator *)keyEnumerator {
  return [nodeData keyEnumerator];
}

- (id)objectForKey:(NSString *)key {
  return [nodeData objectForKey:key];
}

- (void)setObject:(id)value forKey:(NSString *)key {
  BOOL isConfigNode = [value conformsToProtocol:@protocol(MWConfigNode)];
  NSParameterAssert(key != nil);
  NSParameterAssert(value != nil);
  NSParameterAssert([key isKindOfClass:[NSString class]]);
  NSParameterAssert([value conformsToProtocol:@protocol(NSCopying)] || [value conformsToProtocol:@protocol(MWConfigNode)]);

  {
    id oldValue = [nodeData objectForKey:key];

    if (oldValue) {
      if ([oldValue conformsToProtocol:@protocol(MWConfigNode)]) {
        [oldValue didBecomeOrphanConfigNode];
      }
      [[[self undoManager] prepareWithInvocationTarget:self]
        setObject:oldValue
        forKey:key
      ];
    } else {
      [[[self undoManager] prepareWithInvocationTarget:self]
        removeObjectForKey:key
      ];
    }
    
    if (isConfigNode) {
      [nodeData setObject:value forKey:key];
      [(id <MWConfigNode>)value didBecomeChildOfConfigNode:self];
    } else {
      [nodeData setObject:[value copyWithZone:[self zone]] forKey:key];
    }

    [[NSNotificationCenter defaultCenter] 
      postNotificationName:MWConfigNodeChangedNotification
      object:self
      userInfo:[NSDictionary dictionaryWithObject:key forKey:@"key"]
    ];
  }
}

@end
