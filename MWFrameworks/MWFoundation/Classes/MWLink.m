/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLink.h"

#import "MWRegistry.h"
#import "MWConstants.h"
#import "MWUtilities.h"
#import "MWLinkPruner.h"

static int leakedLinks = 0; // ought to provide a way of viewing this value, just in case

// Note on multithreading - we use a NSLock here in case something tries to manipulate links from another thread, but MW in general is *NOT* thread-safe.
static NSRecursiveLock *linkChangeLock;

static BOOL inLog;
void MWLinkLog(NSString *format, ...) {
  va_list v;
  NSString *str;
  if (inLog) return;
  va_start(v, format);
  str = [[NSString alloc] initWithFormat:format arguments:v];
  //printf("%s\n", [str lossyCString]);
  inLog = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkTraceNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:str, @"message", nil]];
  inLog = NO;
  [str release];
  va_end(v);
}

@implementation NSObject (MWLinkableConvenience)

  - (MWLink *)link:(NSString *)linkName to:(NSString *)otherLinkName of:(id <MWLinkable>)target {
    return [[MWLink allocWithZone:[self zone]] initWithObject:(id <MWLinkable>)self linkName:linkName object:target linkName:otherLinkName];
  }
  
  - (void)unlink:(NSString *)linkName {
    [[[(id <MWLinkable>)self links] objectForKey:linkName] unlink];
  }

  - (void)unlinkAll {
    NSEnumerator *e = [[(id <MWLinkable>)self links] objectEnumerator];
    id link;
    while ((link = [e nextObject])) {
      [link unlink];
    }
  }
  
  - (void)send:(id)obj toLinkFor:(NSString *)linkName {
    // will silently fail if there's no link
    [[[(id <MWLinkable>)self links] objectForKey:linkName] send:obj from:(id <MWLinkable>)self];
  }
  
  - (id)probe:(SEL)sel ofLinkFor:(NSString *)linkName {
    // will silently fail if there's no link
    return [[[(id <MWLinkable>)self links] objectForKey:linkName] probe:sel from:(id <MWLinkable>)self];
  }
  
  // Strictly, this isn't a convenience method, but it's also not usually implemented differently.
  - (id)probe:(SEL)sel fromLinkFor:(NSString *)link {
    if ([self respondsToSelector:sel]) {
      return [self performSelector:sel withObject:link];
    } else {
      if ([link isEqual:@"outward"]) return [self probe:sel ofLinkFor:@"inward"];
      else if ([link isEqual:@"inward"]) return [self probe:sel ofLinkFor:@"outward"];
      else return nil;
    }
    return nil; // shut up gcc
  }
  
  - (void)linkableTraceMessage:(NSString *)str {
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkableTraceNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:str, @"message", nil]];
  }
  
  - (void)linkableErrorMessage:(NSString *)str {
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkableTraceNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:str, @"message", [NSNumber numberWithBool:YES], @"important", nil]];
    NSLog(@"%@: %@", [(id <MWLinkable>)self linkableUserDescription], str);
  }
  
@end

@implementation MWLink

+ (void)initialize {
  if (!linkChangeLock) linkChangeLock = [[NSRecursiveLock alloc] init];
}

// --- Convenience ---

+ (void)buildFilterChain:(NSArray *)filters config:(id <MWConfigSupplier>)config {
  NSEnumerator *e = [filters objectEnumerator];
  id lobj, lprev;
  
  if (config) [filters makeObjectsPerformSelector:@selector(setConfig:) withObject:config];
  for (lprev = [e nextObject], lobj = [e nextObject]; lobj != nil; lprev = lobj, lobj = [e nextObject]) {
    [lobj link:@"outward" to:@"inward" of:lprev];
  }
}

// --- Initialization ---

- (MWLink *)initWithObject:
         (id <MWLinkable>)objAp linkName:(NSString *)nameAp
  object:(id <MWLinkable>)objBp linkName:(NSString *)nameBp {
  
  if (!(self = [super init])) return nil;
  
  // Some trickiness here...we need to make sure the object stays in a consistent state, and is also not kept around 'half-linked'.

  [linkChangeLock lock];

  if ([[objAp links] objectForKey:nameAp]) {
    [linkChangeLock unlock];
    [NSException raise:NSInvalidArgumentException format:@"Tried to create a MWLink on an already existing outlet: %@ > %@", objAp, nameAp];
  }
  if ([[objBp links] objectForKey:nameBp]) {
    [linkChangeLock unlock];
    [NSException raise:NSInvalidArgumentException format:@"Tried to create a MWLink on an already existing outlet: %@ > %@", objBp, nameBp];
  }
  
  // First, set all the ivars so that objects looking at the link in their -registerLink:forName: (though they shouldn't really) see it in its final state
  objA = [objAp retain];
  nameA = [nameAp retain];
  objB = [objBp retain];
  nameB = [nameBp retain];
  
  // Now, register the first link.
  
  NS_DURING
    [objA registerLink:self forName:nameA];
    [objB registerLink:self forName:nameB];
  NS_HANDLER
    // If there was an exception, we don't know whether the object registered right or not, or if the second object was registered at all. Therefore we perform a normal -unlink.
    [self unlink];
    // Since we're not returning, we must release ourself.
    [self release];
    [localException raise];
  NS_ENDHANDLER
 
  [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkChangedNotification object:objA userInfo:[NSDictionary dictionaryWithObjectsAndKeys:nameA, @"link", nil]];
  [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkChangedNotification object:objB userInfo:[NSDictionary dictionaryWithObjectsAndKeys:nameB, @"link", nil]];

  [linkChangeLock unlock];

  return self;
}

- (void)unlink {
  // the ifs are in case something's a little bit wrong - note that this method can get called from -dealloc
  
  // NOTE also that releasing an object can cause it to unlinkAll - so we must not release anything till the data structures are in agreement. (NOTE2: shouldn't we be autoreleasing instead?)
  
  // Exceptions are caught and ignored to reduce the damage possible.
  
  [linkChangeLock lock];
  
  if (objA) {
    NS_DURING
      [objA unregisterLinkFor:nameA];
    NS_HANDLER
      [[MWRegistry defaultRegistry] reportCaughtException:localException caughtBy:self caughtFrom:objA caughtBecause:MWLocalizedStringHere(@"BecauseExceptionInLinkUnlink")];
    NS_ENDHANDLER
    [MWLinkPruner pruneLater:objA];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkChangedNotification object:objA userInfo:[NSDictionary dictionaryWithObjectsAndKeys:nameA, @"link", nil]];
  }
  if (objB) {
    NS_DURING
      [objB unregisterLinkFor:nameB];
    NS_HANDLER
      [[MWRegistry defaultRegistry] reportCaughtException:localException caughtBy:self caughtFrom:objB caughtBecause:MWLocalizedStringHere(@"BecauseExceptionInLinkUnlink")];
    NS_ENDHANDLER
    [MWLinkPruner pruneLater:objB];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLinkChangedNotification object:objB userInfo:[NSDictionary dictionaryWithObjectsAndKeys:nameB, @"link", nil]];
  }
  
  [objA release]; objA = nil;
  [objB release]; objB = nil;
  
  [linkChangeLock unlock];
  
  // this object should now get deallocated
  leakedLinks++;
}

- (void)dealloc {
  if (objA || objB) {
    NSLog(@"Can't happen: MWLink deallocated while still referencing objects!");
    [self unlink];
  }
  leakedLinks--;
  [super dealloc];
}

// Use send:from: instead of this.
- (void)sendNow:(id <NSObject>)obj from:(id<MWLinkable, NSObject>)sender {
  id <MWLinkable, NSObject> targ;
  NSString *targLinkName;
  
  if      (sender == objA) { targ = objB; targLinkName = nameB; }
  else if (sender == objB) { targ = objA; targLinkName = nameA; }
  else {  NSLog(@"MWLink given sender not one of the link's objects: %@", sender); return; }
  
  MWLinkLog(@"%@ ---%@--> %@", sender, obj, targ);

  // We catch exceptions so that objects sending can't have their processing messed up by the receiver.
  // FIXME: log if receive:fromLinkFor: returns false
  NS_DURING
    [targ receive:obj fromLinkFor:targLinkName];
  NS_HANDLER
    [[MWRegistry defaultRegistry] reportCaughtException:localException caughtBy:self caughtFrom:targ caughtBecause:MWLocalizedStringHere(@"BecauseExceptionInLinkSending")];
  NS_ENDHANDLER
}

- (id)probe:(SEL)sel from:(id<MWLinkable, NSObject>)sender {
  id <MWLinkable, NSObject> targ;
  NSString *targLinkName;
  
  if      (sender == objA) { targ = objB; targLinkName = nameB; }
  else if (sender == objB) { targ = objA; targLinkName = nameA; }
  else { NSLog(@"MWLink given sender not one of the link's objects: %@", sender); return nil; }
  
  // We catch exceptions so that objects sending can't have their processing messed up by the receiver.
  
  NS_DURING
    NS_VALUERETURN([(NSObject *)targ probe:sel fromLinkFor:targLinkName], id);
  NS_HANDLER
    [[MWRegistry defaultRegistry] reportCaughtException:localException caughtBy:self caughtFrom:targ caughtBecause:MWLocalizedStringHere(@"BecauseExceptionInLinkProbing")];
  NS_ENDHANDLER
  return nil;
}

- (void)send:(id <NSObject>)obj from:(id<MWLinkable, NSObject>)sender {
  [self sendNow:obj from:sender];
// Doesn't work: run loop performSelector doesn't guarantee FIFO order
#if 0
  NSInvocation *const i = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(sendNow:from:)]];
  [i setSelector:@selector(sendNow:from:)];
  [i setArgument:&obj atIndex:2];
  [i setArgument:&sender atIndex:3];
  [i retainArguments];
  [[NSRunLoop currentRunLoop] 
    performSelector:@selector(invokeWithTarget:)
    target:i
    argument:self
    order:1 /* ??? */ 
    modes: [NSArray arrayWithObjects:
      NSDefaultRunLoopMode,
      @"NSModalPanelRunLoopMode",
      @"NSEventTrackingRunLoopMode",
      nil]];
#endif
}

- (id <MWLinkable>)otherObject:(id <MWLinkable, NSObject>)sender {
  // On being given the wrong object here we raise an exception, unlike send and probe.
  if      (sender == objA) return objB;
  else if (sender == objB) return objA;
  else { [NSException raise:NSInvalidArgumentException format:@"MWLink given sender not one of the link's objects: %@", sender]; return nil; }
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %@:%@ <-> %@:%@>", [self class], objA, nameA, nameB, objB];
}

@end
