/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigTree.h"

#import "MWConfigPath.h"
#import "MWConstants.h"
#import "MWUtilities.h"

enum {
  version1 = 1,
};
static const int currentVersion = version1;

@interface MWConfigTreeDirectory (Private)
- (NSMutableArray *)privateConfigTreeGetMutableArray;
@end

@implementation MWConfigTreeDirectory

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)init {
  if (!(self = [super init])) return nil;
  inner = [[NSMutableArray alloc] init];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (!(self = [super init])) return nil;
  switch ([aDecoder versionForClassName:@"MWConfigTreeDirectory"]) {
    case version1:
      inner = [[aDecoder decodeObject] retain];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigTreeDirectory!", [aDecoder versionForClassName:@"MWConfigTreeDirectory"]];
  }
  return self;
}

- (void)dealloc {
  [inner release]; inner = nil;
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:inner];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@>%@", [self class], [inner description]];
}

- (NSMutableArray *)privateConfigTreeGetMutableArray { return inner; }

@end

// --------------------------

@implementation MWConfigTree

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)init {
  if (!(self = [super init])) return nil;
  
  store = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  // make directory object for root
  [store
    setObject:[[[MWConfigTreeDirectory allocWithZone:[self zone]] init] autorelease]
    forKey:[MWConfigPath emptyPath]
  ];
  
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (!(self = [super init])) return nil;
  switch ([aDecoder versionForClassName:@"MWConfigTree"]) {
    case version1:
      store = [[aDecoder decodeObject] retain];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigTree!", [aDecoder versionForClassName:@"MWConfigTree"]];
  }
  return self;
}

- (void)dealloc {
  [undoManager removeAllActionsWithTarget:self];

  [undoManager autorelease]; undoManager = nil;
  [store autorelease]; store = nil;

  [super dealloc];
}

- (void)privateRecursiveDescriptionOf:(MWConfigPath *)path into:(NSMutableString *)buf locale:(NSDictionary *)locale indent:(unsigned)level {

  level++;
  
  MWenumerate([[self allKeysAtPath:path] objectEnumerator], NSString *, key) {
    MWConfigPath *const subpath = [path pathByAppendingComponent:key];
    
    int i;
    for (i = 0; i < level; i++) {
      [buf appendString:@"    "];
    }
    
    [buf appendString:key];
    
    if ([self isDirectoryAtPath:subpath]) {
      [buf appendString:@"/\n"];
      [self privateRecursiveDescriptionOf:subpath into:buf locale:locale indent:level];
    } else {
      id const subobj = [self objectAtPath:subpath];

      NSString *const subdesc = 
        [subobj respondsToSelector:@selector(descriptionWithLocale:indent:)]
        ? [subobj descriptionWithLocale:locale indent:level]
        : [subobj description];
      
      [buf appendString:@" = "];
      [buf appendString:subdesc];
      [buf appendString:@"\n"];
    }
  }
}

- (NSString *)description {
  return [self descriptionWithLocale:nil indent:0];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale {
  return [self descriptionWithLocale:locale indent:0];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level {
  NSMutableString *const buf = [NSMutableString string];
  [buf appendString:@"<"];
  [buf appendString:[[self class] description]];
  [buf appendString:@">\n"];

  [self privateRecursiveDescriptionOf:[MWConfigPath emptyPath] into:buf locale:locale indent:level];

  [buf appendString:@"</"];
  [buf appendString:[[self class] description]];
  [buf appendString:@">"];
  return buf;
}


// --- Tree methods ---

- (id)objectAtPath:(MWConfigPath *)path {
  return [store objectForKey:path];
}
- (id)objectAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path {
  return [store objectForKey:[path pathByAppendingComponent:[self keyAtIndex:index inDirectoryAtPath:path]]];
}
- (NSString *)keyAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path {
  return [[[store objectForKey:path] privateConfigTreeGetMutableArray] objectAtIndex:index];
}
- (unsigned)indexOfKey:(NSString *)key inDirectoryAtPath:(MWConfigPath *)path {
  return [[[store objectForKey:path] privateConfigTreeGetMutableArray] indexOfObject:key];
}
- (BOOL)isDirectoryAtPath:(MWConfigPath *)path {
  return [[store objectForKey:path] isKindOfClass:[MWConfigTreeDirectory class]];
}

- (unsigned)countAtPath:(MWConfigPath *)path {
  return [[[store objectForKey:path] privateConfigTreeGetMutableArray] count];
}
- (NSArray *)allKeysAtPath:(MWConfigPath *)path {
  // must copy to avoid aliasing issues
  return [[[[store objectForKey:path] privateConfigTreeGetMutableArray] copy] autorelease];
}
- (NSArray *)allValuesAtPath:(MWConfigPath *)path {
  NSEnumerator *kE = [[[store objectForKey:path] privateConfigTreeGetMutableArray] objectEnumerator];
  NSString *k;
  NSMutableArray *out = [NSMutableArray array];
  while ((k = [kE nextObject])) [out addObject:[self objectAtPath:[path pathByAppendingComponent:k]]];
  return out;
}


- (NSString *)nonexistentKeyAtPath:(MWConfigPath *)path {
  return [[[self nonexistentPathAtPath:path] components] objectAtIndex:[[path components] count]];
}

#define nonexistentPathAtPath_format() [path pathByAppendingComponent:[NSString stringWithFormat:@"U-%p-%lx-%lx-%lx", self, time(NULL), kI, random()]]
- (MWConfigPath *)nonexistentPathAtPath:(MWConfigPath *)path {
  unsigned long kI = 1;
  MWConfigPath *kP = nonexistentPathAtPath_format();
  while ([store objectForKey:kP]) {
    kI++;
    kP = nonexistentPathAtPath_format();
  }
  // NSLog(@"%@", kP);
  return kP;
}

// --- Mutation methods ---

- (void)setObject:(id<NSObject>)object atPath:(MWConfigPath *)path {
  [self setObject:object forKey:[[path components] lastObject] atPath:[path pathByDeletingLastComponent] insertIndex:-1];
}
- (void)setObject:(id<NSObject>)object forKey:(NSString *)key atPath:(MWConfigPath *)path {
  [self setObject:object forKey:key atPath:path insertIndex:-1];
}
- (void)setObject:(id<NSObject>)object atPath:(MWConfigPath *)path insertIndex:(int)index {
  [self setObject:object forKey:[[path components] lastObject] atPath:[path pathByDeletingLastComponent] insertIndex:index];
}
- (void)setObject:(id<NSObject>)object forKey:(NSString *)key atPath:(MWConfigPath *)path insertIndex:(int)newIndex {
  MWConfigTreeDirectory *dirw;
  NSMutableArray *dir;
  MWConfigPath *newItemPath;
  id oldObject;
  
  NSParameterAssert(object != nil);
  NSParameterAssert(key != nil);
  NSParameterAssert(path != nil);
  
  dirw = [store objectForKey:path];
  if (!dirw) [NSException raise:NSInvalidArgumentException format:@"%@ setObject:forKey:atPath:insertIndex: given nonexistent directory path %@", self, path];
  dir = [dirw privateConfigTreeGetMutableArray];
  newItemPath = [path pathByAppendingComponent:key];

  if (newIndex < 0 || newIndex > [dir count]) newIndex = [dir count];
  
  if ((oldObject = [store objectForKey:newItemPath])) {
    if ([oldObject isKindOfClass:[MWConfigTreeDirectory class]])
      [NSException raise:NSInvalidArgumentException format:@"%@ %p: Attempted to replace a directory (%@) with an object (%@)", [self class], self, newItemPath, object];
      
    [[undoManager prepareWithInvocationTarget:self]
      setObject:oldObject
      forKey:key
      atPath:path
      insertIndex:[dir indexOfObject:key]
    ];
    
    {
      unsigned int oldIndex = [dir indexOfObject:key];
      [dir removeObjectAtIndex:oldIndex];
      // by removing the old object, the indexes change...
      if (newIndex > oldIndex) newIndex--;
    }
  } else {
    [[undoManager prepareWithInvocationTarget:self]
      removeItemAtPath:newItemPath
      recurse:NO
    ];
  }
  
  [store setObject:object forKey:newItemPath];
  //NSLog(@"before insert %u %@ %u", [dir count], dir, newIndex);
  [dir insertObject:key atIndex:newIndex];
  //NSLog(@"after insert %u %@", [dir count], dir);

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:MWConfigSupplierChangedNotification
    object:self
    userInfo:[NSDictionary dictionaryWithObject:newItemPath forKey:@"path"]
  ];
}
- (void)addEntriesFromDictionary:(NSDictionary *)objects atPath:(MWConfigPath *)path insertIndex:(int)index {
  NSEnumerator *kE = [objects keyEnumerator];
  id k;
  while ((k = [kE nextObject]))
    [self setObject:[objects objectForKey:k] forKey:k atPath:path insertIndex:index++];
}
- (void)addEntriesFromTree:(MWConfigTree *)source atPath:(MWConfigPath *)destPrefix insertIndex:(int)index {
  [self copyContentsOfDirectory:[MWConfigPath emptyPath] from:source toDirectory:destPrefix insertIndex:index];
}

- (void)addDirectoryAtPath:(MWConfigPath *)innerPath recurse:(BOOL)recurse insertIndex:(int)newIndex {
  id obj;
  NSParameterAssert(innerPath != nil);

  if ((obj = [store objectForKey:innerPath])) {
    if ([obj isKindOfClass:[MWConfigTreeDirectory class]])
      return;
    else
      [NSException raise:NSInvalidArgumentException format:@"%@: Attempted to replace an object with a directory: %@", self, innerPath];
  }
  
  {
    MWConfigPath *outerPath = [innerPath pathByDeletingLastComponent];
    NSString *key = [[innerPath components] lastObject];
  
    if (![store objectForKey:outerPath]) {
      if (recurse)
        [self addDirectoryAtPath:outerPath recurse:YES insertIndex:-1];
      else
        [NSException raise:NSInvalidArgumentException format:@"%@: Can't create multiple directory levels without recurse flag: %@", self, innerPath];
    }
    
    {
      NSMutableArray *dir = [[store objectForKey:outerPath] privateConfigTreeGetMutableArray];

      if (newIndex < 0 || newIndex > [dir count]) newIndex = [dir count];

      [[undoManager prepareWithInvocationTarget:self]
        removeItemAtPath:innerPath
        recurse:NO
      ];
      [store setObject:[[[MWConfigTreeDirectory allocWithZone:[self zone]] init] autorelease] forKey:innerPath];
      //NSLog(@"before insert %u %@ %u", [dir count], dir, newIndex);
      [dir insertObject:key atIndex:newIndex];
      //NSLog(@"after insert %u %@", [dir count], dir);
    }

    [[NSNotificationCenter defaultCenter] 
      postNotificationName:MWConfigSupplierChangedNotification
      object:self
      userInfo:[NSDictionary dictionaryWithObject:innerPath forKey:@"path"]
    ];
  }
}
- (void)removeItemAtPath:(MWConfigPath *)innerPath recurse:(BOOL)recurse {
  NSParameterAssert(innerPath != nil);
  {
    id oldObject = [store objectForKey:innerPath];
    NSString *key = [[innerPath components] lastObject];
    MWConfigPath *outerPath = [innerPath pathByDeletingLastComponent];
    NSMutableArray *outerDir = [[store objectForKey:outerPath] privateConfigTreeGetMutableArray];
    
    if (!oldObject) return;
    
    if ([oldObject isKindOfClass:[MWConfigTreeDirectory class]]) {
      NSArray *children = [[store objectForKey:innerPath] privateConfigTreeGetMutableArray];
      if (recurse) {
        NSEnumerator *childE = [children objectEnumerator];
        NSString *childKey;
        while ((childKey = [childE nextObject])) {
          [self removeItemAtPath:[innerPath pathByAppendingComponent:childKey] recurse:YES];
        }
      } else if ([children count]) {
        [NSException raise:NSInvalidArgumentException format:@"%@: Can't remove nonempty directory without recurse flag: %@", self, innerPath];
      }
      
      //NSLog(@"%@ %@ %@ %@ %u", innerPath, outerPath, outerDir, key, [outerDir indexOfObject:key]);
      [[undoManager prepareWithInvocationTarget:self]
        addDirectoryAtPath:innerPath
        recurse:NO
        insertIndex:[outerDir indexOfObject:key]
      ];
    } else {
      [[undoManager prepareWithInvocationTarget:self]
        setObject:oldObject
        forKey:key
        atPath:outerPath
        insertIndex:[outerDir indexOfObject:key]
      ];
    }
    [store removeObjectForKey:innerPath];
    [outerDir removeObject:key];

    [[NSNotificationCenter defaultCenter] 
      postNotificationName:MWConfigSupplierChangedNotification
      object:self
      userInfo:[NSDictionary dictionaryWithObject:innerPath forKey:@"path"]
    ];
  }
}

- (void)copyContentsOfDirectory:(MWConfigPath *)sourcePath from:(id <MWConfigSupplier, NSObject>)replacement toDirectory:(MWConfigPath *)destPath insertIndex:(int)insertIndex {
  NSEnumerator *kE = [[replacement allKeysAtPath:sourcePath] objectEnumerator];
  NSString *k;
  while ((k = [kE nextObject])) {
    MWConfigPath *sourceSub = [sourcePath pathByAppendingComponent:k];
    MWConfigPath *destSub = [destPath pathByAppendingComponent:k];
    if ([replacement isDirectoryAtPath:sourceSub]) {
      [self addDirectoryAtPath:destSub recurse:NO insertIndex:insertIndex < 0 ? -1 : insertIndex++];
      [self copyContentsOfDirectory:sourceSub from:replacement toDirectory:destSub insertIndex:-1];
    } else {
      [self setObject:[replacement objectAtPath:sourceSub] atPath:destSub];
    }
  }
}

- (void)privateFastReplaceContent:(NSMutableDictionary *)replacement {
  [[undoManager prepareWithInvocationTarget:self] privateFastReplaceContent:store];
  [store autorelease];
  store = [replacement retain];
}

- (MWConfigTree *)subtreeFromDirectoryAtPath:(MWConfigPath *)path {
  MWConfigTree *result = [[[[self class] alloc] init] autorelease];
  
  [result copyContentsOfDirectory:path from:self toDirectory:[MWConfigPath emptyPath] insertIndex:-1];
  
  return result;
}

- (void)setConfig:(id <MWConfigSupplier, NSObject>)replacement {
  NSParameterAssert(replacement);

  [[undoManager prepareWithInvocationTarget:self] privateFastReplaceContent:store];
  
  [store autorelease];
  store = [[NSMutableDictionary allocWithZone:[self zone]] init];
  [store
    setObject:[[[MWConfigTreeDirectory allocWithZone:[self zone]] init] autorelease]
    forKey:[MWConfigPath emptyPath]
  ];
  
  [self copyContentsOfDirectory:[MWConfigPath emptyPath] from:replacement toDirectory:[MWConfigPath emptyPath] insertIndex:-1];
  
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:MWConfigSupplierChangedNotification
    object:self
    userInfo:nil
  ];
}

// --- Copying and coding ---

- (id)mutableCopyWithZone:(NSZone *)zone {
  MWConfigTree *copy = [[[self class] allocWithZone:zone] init];
  
  [copy setConfig:self];

  return copy;
}

- (id)copyWithZone:(NSZone *)zone {
  return [self mutableCopyWithZone:zone];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:store];
}

// --- Accessors ---

- (NSUndoManager *)undoManager { return undoManager; }
- (void)setUndoManager:(NSUndoManager *)newVal {
  [undoManager autorelease]; undoManager = [newVal retain];
}

@end
