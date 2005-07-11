/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWLineString.h"

@implementation MWLineString

/* NOTE: We used to init only one of plainString and attrString and lazily construct the other version, but that caused a nasty bug when a mutable attributed string containing MWLineStrings in its attributes was altered, causing our isEqual: to be called, causing the creation of an attributed string, causing apparently nonreentrant code in Foundation to be called (+[NSAttributeDictionary newWithDictionary:]). */

+ (MWLineString *)lineStringWithString:(NSString *)s role:(NSString *)r {
  return [[[self alloc] initWithString:s role:r] autorelease];
}
+ (MWLineString *)lineStringWithString:(NSString *)s {
  return [[[self alloc] initWithString:s role:nil] autorelease];
}
+ (MWLineString *)lineStringWithAttributedString:(NSAttributedString *)s role:(NSString *)r {
  return [[[self alloc] initWithAttributedString:s role:r] autorelease];
}
+ (MWLineString *)lineStringWithAttributedString:(NSAttributedString *)s {
  return [[[self alloc] initWithAttributedString:s role:nil] autorelease];
}

- (MWLineString *)initWithString:(NSString *)s role:(NSString *)r {
  if (!(self = (MWLineString *)[super init])) return nil;
  
  NSParameterAssert(s != nil);
  
  plainString = [s copy];
  attrString = [[NSAttributedString allocWithZone:[self zone]] initWithString:plainString attributes:[NSDictionary dictionary]];
  role = [r copy];
  
  return self;
}
- (MWLineString *)initWithString:(NSString *)s {
  return [self initWithString:s role:nil];
}

- (MWLineString *)initWithAttributedString:(NSAttributedString *)s role:(NSString *)r {
  if (!(self = (MWLineString *)[super init])) return nil;

  NSParameterAssert(s != nil);
    
  attrString = [s copy];
  plainString = [[attrString string] retain];
  role = [r copy];
  
  return self;
}
- (MWLineString *)initWithAttributedString:(NSAttributedString *)s {
  return [self initWithAttributedString:s role:nil];
}

- (MWLineString *)copyWithZone:(NSZone *)z {
  MWLineString *copy = [[[self class] allocWithZone:z] init];
  copy->plainString = [plainString retain];
  copy->attrString = [attrString retain];
  copy->role = [role retain];
  return copy;
}

- (void)dealloc {
  [plainString autorelease];
  [attrString autorelease];
  [role autorelease];
  plainString = nil;
  attrString = nil;
  role = nil;
  [super dealloc];
}

// Default to copying
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) return [super replacementObjectForPortCoder:encoder];
  return self;
}

- (NSString *)string { return plainString; }
- (NSAttributedString *)attributedString { return attrString; }
- (NSString *)role { return role; }

- (unsigned)hash {
  return [[self attributedString] hash];
}

- (BOOL)isEqual:(id)other {
  NSString *const mrole = [self role];
  return self == other || ([other isKindOfClass:[MWLineString class]] && [[self attributedString] isEqual:[(MWLineString *)other attributedString]] && (mrole == nil ? [(MWLineString *)other role] == nil : [mrole isEqual:[(MWLineString *)other role]]));
}

- (NSString *)description { return [NSString stringWithFormat:@"<LINEs %@ >%@", [self role], [self string]]; }

@end
