/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWMockLinkable.h"

@interface MWMockLinkable (ExampleAddActualObject)

- (void)addActualObject:(id)obj;

@end

@implementation MWMockLinkable

- (id)initWithExpectations:(NSDictionary *)e {
  if (!(self = [super init])) return nil;
  
  expectations = [e copy];
  
  return self;
}

- (void)dealloc {
  [expectations release]; expectations = nil;
  [super dealloc];
}

- (NSSet *)linkNames { return [NSSet setWithArray:[expectations allKeys]]; }
- (NSSet *)linksRequired { return [NSSet setWithArray:[expectations allKeys]]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)linkName {
  [[expectations objectForKey:linkName] addActualObject:obj];
  return YES;
}

@end
