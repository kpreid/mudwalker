/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLineData.h"

@implementation MWLineData

- (MWLineData *)initWithData:(NSData *)d role:(NSString *)r {
  if (!(self = (MWLineData *)[super init])) return nil;
  
  data = [d copy];
  role = [r copy];
  
  return self;
}
- (MWLineData *)initWithData:(NSData *)d {
  return [self initWithData:d role:nil];
}

- (MWLineData *)copyWithZone:(NSZone *)z {
  return [[[self class] allocWithZone:z] initWithData:data role:role];
}

- (void)dealloc {
  [data autorelease]; data = nil;
  [role autorelease]; role = nil;
  [super dealloc];
}

// Default to copying
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) return [super replacementObjectForPortCoder:encoder];
  return self;
}

- (NSData *)data { return data; }
- (NSString *)role { return role; }

- (NSString *)description { return [NSString stringWithFormat:@"<LINEd %@ %@>", [self role], [[self data] description]]; }

@end
