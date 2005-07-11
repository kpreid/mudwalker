/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWToken.h>

@interface MWTokenTest : TestCase {
} @end

@implementation MWTokenTest

- (void)testName {
  MWToken *t = [MWToken token:@"foo"];
  [self assertNotNil:t];
  [self assert:[t name] equals:@"foo"];
}

- (void)testEquality {
  MWToken *t = [MWToken token:@"foo"];
  MWToken *u = [MWToken token:@"foo"];
  [self assert:t equals:t];
  [self assert:t equals:u];
  [self assert:u equals:t];
}

- (void)testInequality {
  MWToken *t = [MWToken token:@"foo"];
  MWToken *u = [MWToken token:@"bar"];
  [self assertFalse:[t isEqual:u]];
  [self assertFalse:[u isEqual:t]];
}

- (void)testInequalityOther {
  MWToken *t = [MWToken token:@"foo"];
  [self assertFalse:[t isEqual:@"foo"]];
  [self assertFalse:[t isEqual:nil]];
  [self assertFalse:[t isEqual:[NSNull null]]];
}

- (void)testHash {
  MWToken *t = [MWToken token:@"foo"];
  MWToken *u = [MWToken token:@"foo"];
  [self assertInt:[t hash] equals:[u hash]];
}

- (void)testMutableName {
  NSMutableString *s = [[@"hi" mutableCopy] autorelease];
  MWToken *t = [[[MWToken alloc] initWithName:s] autorelease];
  [s setString:@"bye"];
  [self assert:[t name] equals:@"hi"];
}

@end