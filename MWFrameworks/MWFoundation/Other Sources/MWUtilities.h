/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

// Loop over an enumerator. Usage: MWenumerate([dict keyEnumerator], NSString *, key)
#define MWenumerate(enumerator, elementType, elementVar) \
  NSEnumerator * const elementVar ## E = (enumerator); \
  elementType elementVar; \
  while ((elementVar = [elementVar ## E nextObject])) 

// Make a range from this-element to before-that-element, rather than location, length
static __inline__ NSRange MWMakeABRange(unsigned int locationA, unsigned int locationB) {
  NSCParameterAssert(locationA <= locationB);
  return NSMakeRange(locationA, locationB - locationA);
}

/* If its argument is nil, returns the empty string, otherwise returns its argument's description. */
static __inline__ NSString * MWForceToString(id x) {
  return x ? [x description] : @"";
}

/* Returns a value unique to a given object (at least for that object's life) suitable for use as a dictionary key (i.e., copyable) */
static __inline__ id <NSObject, NSCopying> MWKeyFromObjectIdentity(id obj) {
  return [NSNumber numberWithUnsignedLong:(unsigned long)obj];
}

/* Return a localized string from a bundle */
static __inline__ NSString *MWLocalizedStringFromBundle(NSString *key, NSBundle *bundle) { return [bundle localizedStringForKey:key value:nil table:nil]; }

/* Return a localized string from a class's bundle */
static __inline__ NSString *MWLocalizedStringForClass(NSString *key, Class aClass) { return MWLocalizedStringFromBundle(key, [NSBundle bundleForClass:aClass]); }

/* Return a localized string from a class's bundle, or nil if there is no string. */
static __inline__ NSString *MWLocalizedStringForClassFailable(NSString *key, Class aClass) {
  static NSString *const failureString = @"LOCALIZED_ƒÅÎLÜ®É";
  NSString *const s = [[NSBundle bundleForClass:aClass] localizedStringForKey:key value:failureString table:nil];
  return (s == failureString || [s isEqualToString:failureString]) ? nil : s;
}

/* Return a localized string from a class's bundle or any of its superclasses' bundles, or nil if there is no string. */
static __inline__ NSString *MWLocalizedStringForClassSearchingFailable(NSString *key, Class aClass) {
  // NOTE: might want to cache results of this complex lookup
  NSString *localized;
  while (!(localized = MWLocalizedStringForClassFailable(key, aClass)) && aClass) aClass = [aClass superclass];
  return localized;
}

/* Return a localized string from a class's bundle or any of its superclasses' bundles, or the original string. */
static __inline__ NSString *MWLocalizedStringForClassSearching(NSString *key, Class aClass) {
  NSString *const s = MWLocalizedStringForClassSearchingFailable(key, aClass);
  return s ? s : key;
}

#define MWLocalizedStringHere(key) MWLocalizedStringForClassSearching((key), [self class])
#define MWLocalizedStringHereFailable(key) MWLocalizedStringForClassSearchingFailable((key), [self class])

