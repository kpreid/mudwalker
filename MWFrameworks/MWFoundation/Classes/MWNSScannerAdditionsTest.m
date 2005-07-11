/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWNSScannerAdditions.h>

@interface MWNSScannerAdditionsTest : TestCase {
} @end

@implementation MWNSScannerAdditionsTest

- (void)setUp {}

- (void)tearDown {}

- (void)testQuoting {
  NSScanner *scan = [NSScanner scannerWithString:@" args: \" subject: introduction \""];
  NSString *buf;
  
  buf = nil;
  [self assertTrue:[scan mwScanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@": "] possiblyQuotedBy:'"' intoString:&buf]];
  [self assert:buf equals:@"args"];
  [self assertInt:[scan scanLocation] equals:5];
  
  buf = nil;
  [self assertTrue:[scan scanString:@":" intoString:&buf]];
  [self assert:buf equals:@":"];
  [self assertInt:[scan scanLocation] equals:6];
  
  buf = nil;
  [self assertTrue:[scan mwScanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:/*{*/@"} "] possiblyQuotedBy:'"' intoString:&buf]];
  [self assert:buf equals:@" subject: introduction "];
  [self assertInt:[scan scanLocation] equals:32];
 
  [self assertTrue:[scan isAtEnd]];
}

@end