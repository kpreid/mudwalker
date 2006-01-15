/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWLogger.h>
#import <MudWalker/MWMockLinkable.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWLineString.h>
#import <MudWalker/MWConstants.h>

@interface MWLoggerTest : TestCase {
  MWLogger *specimen;
  NSString *path;
  MWMockLinkable *stub;
} @end

@implementation MWLoggerTest

- (void)setUp {
  path = [[NSString stringWithFormat:
           @"%@/MudWalker Log Test %u.log",
           NSTemporaryDirectory(), 
           [[NSProcessInfo processInfo] processIdentifier]] retain];

  specimen = [[MWLogger alloc] init];
  {
    MWConfigTree *lfnTree = [[[MWConfigTree alloc] init] autorelease];
    [lfnTree setObject:path atPath:[MWConfigPath pathWithComponent:@"LogFileName"]];
    [specimen setConfig:lfnTree];
  }
  
  stub = [[MWMockLinkable alloc] initWithExpectations:[NSDictionary dictionaryWithObjectsAndKeys:
  nil]];

  [specimen link:@"foo" to:@"foo" of:stub];
}

- (void)tearDown {
  [specimen release]; specimen = nil;
  [stub release]; stub = nil;
  
  [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
  [path release]; path = nil;
}

- (NSString *)logContents {
  [specimen flush];
  id log = [NSString stringWithContentsOfFile:path];
  return [log substringFromIndex:[log rangeOfString:@"\n"].location + 1];
}

- (void)testPlain {
  [stub send:[MWLineString lineStringWithString:@"hi"] toLinkFor:@"foo"];
  [self assert:[self logContents] equals:@"foo ::: hi\n"];
}

- (void)testPassword {
  [stub send:[MWLineString lineStringWithString:@"hi" role:MWPasswordRole] toLinkFor:@"foo"];
  [self assert:[self logContents] equals:@"foo ::: ************\n"];
}

@end