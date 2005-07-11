/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWToken.h"

@implementation MWToken

+ (MWToken *)token:(NSString *)n {
  // FIXME: intern
  return [[[self alloc] initWithName:n] autorelease];
}

- (MWToken *)initWithName:(NSString *)aName {
  if (!(self = (MWToken *)[super init])) return nil;
  
  NSParameterAssert([aName isKindOfClass:[NSString class]]);
  
  tokenName = [aName copy];
  
  return self;
}

- (void)dealloc {
  [tokenName autorelease]; tokenName = nil;
  [super dealloc];
}

// Default to copying
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) return [super replacementObjectForPortCoder:encoder];
  return self;
}

- (NSString *)name { return tokenName; }

- (NSString *)description { return [NSString stringWithFormat:@"<'%@>", [self name]]; }

- (BOOL)isEqual:(id)other {
  return self == other || ([self isKindOfClass:[other class]] && [[self name] isEqual:[other name]]);
}
- (unsigned)hash { return [[self name] hash]; }

@end
