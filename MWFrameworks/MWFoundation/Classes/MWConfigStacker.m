/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigStacker.h"

#import "MWConfigPath.h"
#import "MWConstants.h"

/* Combine two arrays, skipping items in the second array which exist in the first */
static __inline__ NSArray * merge(NSArray *a, NSArray *b) {
  if (a) {
    if (b) {
      NSMutableArray *outa = [NSMutableArray arrayWithArray:a];
      NSMutableSet *outs = [NSMutableSet setWithArray:a];
      NSEnumerator *e = [b objectEnumerator];
      id v;

      while ((v = [e nextObject]))
        if (![outs containsObject:v])
          [outa addObject:v];

      return outa;
    } else {
      return a;
    }
  } else {
    return b ? b : [NSArray array];
  }
}


@implementation MWConfigStacker

+ (MWConfigStacker *)stackerWithSuppliers:(id <MWConfigSupplier, NSObject>)pcar :(id <MWConfigSupplier, NSObject>)pcdr {
  return [[[self alloc] initWithSuppliers:pcar :pcdr] autorelease];
}

- (id)init {
  if (!(self = [super init])) return nil;
  
  return self;
}

- (MWConfigStacker *)initWithSuppliers:(id <MWConfigSupplier, NSObject>)pcar :(id <MWConfigSupplier, NSObject>)pcdr {
  if (!(self = [super init])) return nil;
  
  car = [pcar retain];
  cdr = [pcdr retain];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forwardNotification:) name:MWConfigSupplierChangedNotification object:car];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forwardNotification:) name:MWConfigSupplierChangedNotification object:cdr];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:car];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:cdr];
  [car autorelease]; car = nil;
  [cdr autorelease]; cdr = nil;
  [super dealloc];
}

- (NSString *)description {
   return [NSString stringWithFormat:@"(%@ %@ %@)", [self class], car, cdr];
}

// --- Notification forwarding ---

- (void)forwardNotification:(NSNotification *)notif {
  [[NSNotificationCenter defaultCenter]
    postNotificationName:[notif name]
    object:self
    userInfo:[notif userInfo]
  ];
}

// --- Tree methods ---

/* Some of these implementations, like -objectAtIndex:inDirectoryAtPath:, are somewhat strange. The reason for this is to provide a *self-consistent* view of the two config trees. */

- (id)objectAtPath:(MWConfigPath *)path {
  id           r = [car objectAtPath:path];
  return   r ? r : [cdr objectAtPath:path];
}
- (id)objectAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path {
  return [self objectAtPath:[path pathByAppendingComponent:[[self allKeysAtPath:path] objectAtIndex:index]]];
}
- (NSString *)keyAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path {
  return [[self allKeysAtPath:path] objectAtIndex:index];
}
- (unsigned)indexOfKey:(NSString *)key inDirectoryAtPath:(MWConfigPath *)path {
  return [[self allKeysAtPath:path] indexOfObject:key];
}
- (BOOL)isDirectoryAtPath:(MWConfigPath *)path {
  return [car objectAtPath:path] ? [car isDirectoryAtPath:path] : [cdr isDirectoryAtPath:path];
}

- (unsigned)countAtPath:(MWConfigPath *)path {
  return [merge([car allKeysAtPath:path], [cdr allKeysAtPath:path]) count];
}
- (NSArray *)allKeysAtPath:(MWConfigPath *)path {
  return merge([car allKeysAtPath:path], [cdr allKeysAtPath:path]);
}
- (NSArray *)allValuesAtPath:(MWConfigPath *)path {
  NSEnumerator *kE = [merge([car allKeysAtPath:path], [cdr allKeysAtPath:path]) objectEnumerator];
  NSString *k;
  NSMutableArray *outa = [NSMutableArray array];
  while ((k = [kE nextObject]))
    [outa addObject:[self objectAtPath:[path pathByAppendingComponent:k]]];
  return outa;
}


// --- Copying ---

- (id)copyWithZone:(NSZone *)zone {
  // we're immutable, so:
  if (zone == [self zone])
    return self;
  else
    return [[[self class] allocWithZone:zone] initWithSuppliers:car :cdr];
}

@end
