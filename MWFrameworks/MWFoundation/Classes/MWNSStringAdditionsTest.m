/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWNSStringAdditions.h>

@interface MWNSStringAdditionsTest : TestCase {
} @end

@implementation MWNSStringAdditionsTest

- (void)setUp {}

- (void)tearDown {}

- (void)testCharacterRangeForLineNumbers {
  NSString *testString = @"abc\ndef\nghi\njkl\nmno\n";

  [self
    assert:NSStringFromRange([testString mwCharacterRangeForLineNumbers:NSMakeRange(2, 1)]) 
    equals:NSStringFromRange(NSMakeRange(4, 4))
  ];
  [self
    assert:NSStringFromRange([testString mwCharacterRangeForLineNumbers:NSMakeRange(2, 2)]) 
    equals:NSStringFromRange(NSMakeRange(4, 8))
  ];
  [self
    assert:NSStringFromRange([testString mwCharacterRangeForLineNumbers:NSMakeRange(1, 2)]) 
    equals:NSStringFromRange(NSMakeRange(0, 8))
  ];
  [self
    assert:NSStringFromRange([testString mwCharacterRangeForLineNumbers:NSMakeRange(5, 1)]) 
    equals:NSStringFromRange(NSMakeRange(16, 4))
  ];
}

- (void)testLineNumbersForCharacterRange { /* FIXME: write these tests */ }

- (void)testComponentsSeparatedByLineTerminators {
  [self 
    assert:[@"foo" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", nil]
    message:@"foo"
  ];
  [self 
    assert:[@"foo\n" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", nil]
    message:@"foo/"
  ];
  [self 
    assert:[@"foo\nbar" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", @"bar", nil]
    message:@"foo/bar"
  ];
  [self 
    assert:[@"foo\nbar\n" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", @"bar", nil]
    message:@"foo/bar/"
  ];
  [self 
    assert:[@"foo\nbar\nbaz" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil]
    message:@"foo/bar/baz"
  ];
  [self 
    assert:[@"\nbar" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"", @"bar", nil]
    message:@"/bar"
  ];
  [self 
    assert:[@"foo\n\n" componentsSeparatedByLineTerminators]
    equals:[NSArray arrayWithObjects:@"foo", @"", nil]
    message:@"foo//"
  ];
}

- (void)testEscapedByPrefix {
  NSCharacterSet *escape = [NSCharacterSet characterSetWithCharactersInString:@"\"\\e"];
  [self assert:[@"foo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"foo"];
  [self assert:[@"f\\oo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"f\\\\oo"];
  [self assert:[@"\\foo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"\\\\foo"];
  [self assert:[@"foo\\" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"foo\\\\"];
  [self assert:[@"foo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"foo"];
  [self assert:[@"f\"oo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"f\\\"oo"];
  [self assert:[@"\"foo" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"\\\"foo"];
  [self assert:[@"foo\"" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"foo\\\""];
  [self assert:[@"\\\"\\" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"\\\\\\\"\\\\"];
  [self assert:[@"qwerty" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"qw\\erty"];
  [self assert:[@"qwErty" stringWithCharactersFromSet:escape escapedByPrefix:@"\\"] equals:@"qwErty"];
}

@end