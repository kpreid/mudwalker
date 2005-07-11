/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import "MWMCProtocolFilter.h"

@interface MWMCProtocolFilterTest : TestCase {
  MWRegistry *originalRegistry;
} @end

@implementation MWMCProtocolFilterTest

- (void)setUp {
  originalRegistry = [[MWRegistry defaultRegistry] retain];
  [MWRegistry setDefaultRegistry:nil];

  [MWMCProtocolFilter registerAsMWPlugin:[MWRegistry defaultRegistry]];
}

- (void)tearDown {
  [MWRegistry setDefaultRegistry:originalRegistry];
  [originalRegistry autorelease]; originalRegistry = nil;
}

- (void)testFake {}


@end