/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWLink.h>
#import <MudWalker/MWMockLinkable.h>
#import <MudWalker/MWLineString.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWScript.h>
#import "MWTriggerFilter.h"

//@class MWTriggerFilterTest_StubLinkable;

@interface MWTriggerFilterTest : TestCase {
 @public
  MWConfigTree *config;
  MWMockLinkable *stub;
  MWTriggerFilter *filter;
  id insideEx, outsideEx;
} @end

#if 0

@interface MWTriggerFilterTest_StubLinkable : MWConcreteLinkable {
 @public
  MWTriggerFilterTest *test;
} @end

@implementation MWTriggerFilterTest_StubLinkable

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)linkName {
  if ([linkName isEqual:@"outside"])
    [test->outsideEx addActualObject:obj];
  else if ([linkName isEqual:@"inside"])
    [test->insideEx addActualObject:obj];
  return YES;
}

@end

#endif

@implementation MWTriggerFilterTest

- (void)setUp {
  config = [[MWConfigTree alloc] init];
  
  [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Triggers", @"test", nil] recurse:YES insertIndex:-1];
  [config setObject:@"triggerer" atPath:[MWConfigPath pathWithComponents:@"Triggers", @"test", @"patterns", nil]];
  [config setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponents:@"Triggers", @"test", @"doSubstitute", nil]];
  [config setObject:[[[MWScript alloc] initWithSource:@"triggered" languageIdentifier:@"BaseIdentity"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Triggers", @"test", @"doSubstitute_replacement", nil]];
  
  [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Aliases", @"test1", nil] recurse:YES insertIndex:-1];
  [config setObject:@"shortalias" atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test1", @"match", nil]];
  [config setObject:[[[MWScript alloc] initWithSource:@"big long command string" languageIdentifier:@"BaseIdentity"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test1", @"script", nil]];

  [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Aliases", @"test2", nil] recurse:YES insertIndex:-1];
  [config setObject:@"$@" atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test2", @"match", nil]];
  [config setObject:[[[MWScript alloc] initWithSource:@"dollar at" languageIdentifier:@"BaseIdentity"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test2", @"script", nil]];

  [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Aliases", @"test3", nil] recurse:YES insertIndex:-1];
  [config setObject:@"\"" atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test3", @"match", nil]];
  [config setObject:[[[MWScript alloc] initWithSource:@"speech $$arg[1]" languageIdentifier:@"SubstitutedLua"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test3", @"script", nil]];

  [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Aliases", @"test4", nil] recurse:YES insertIndex:-1];
  [config setObject:@"say" atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test4", @"match", nil]];
  [config setObject:[[[MWScript alloc] initWithSource:@"speech $$arg[1]" languageIdentifier:@"SubstitutedLua"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test4", @"script", nil]];

  //stub = [[MWTriggerFilterTest_StubLinkable alloc] init];
  //stub->test = self;
  outsideEx = [[ExpectationList alloc] initWithName:@""];
  insideEx = [[ExpectationList alloc] initWithName:@""];

  stub = [[MWMockLinkable alloc] initWithExpectations:[NSDictionary dictionaryWithObjectsAndKeys:
    insideEx, @"inside",
    outsideEx, @"outside",
  nil]];

  filter = [[NSClassFromString(@"MWTriggerFilter") alloc] init];
  [filter setConfig:config];
  [filter link:@"inward" to:@"inside" of:stub];
  [filter link:@"outward" to:@"outside" of:stub];
}

- (void)tearDown {
  [config release];
  [stub release];
  [filter release];
  [insideEx release];
  [outsideEx release];
  filter = nil;
  insideEx = nil;
  outsideEx = nil;
}

- (void)testPassthruOut {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"hi"]];

  [stub send:[MWLineString lineStringWithString:@"hi"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testPassthruIn {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"hi"]];

  [stub send:[MWLineString lineStringWithString:@"hi"] toLinkFor:@"outside"];
  
  [insideEx verify]; [insideEx release]; insideEx = nil;
}

- (void)testSubstituteTrigger {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"triggered"]];

  [stub send:[MWLineString lineStringWithString:@"triggerer"] toLinkFor:@"outside"];
  
  [insideEx verify]; [insideEx release]; insideEx = nil;
}

- (void)testSimpleAlias {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"big long command string"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testWordAliasArg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"big long command string"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias argstr"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testWordAliasNonarg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"shortaliasargstr"]];

  [stub send:[MWLineString lineStringWithString:@"shortaliasargstr"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testPunctAliasArg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"dollar at"]];

  [stub send:[MWLineString lineStringWithString:@"$@ argstr"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testAliasUseArgPunct {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"speech argstr"]];

  [stub send:[MWLineString lineStringWithString:@"\"argstr"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testAliasUseArgWord {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"speech argstr"]];

  [stub send:[MWLineString lineStringWithString:@"say argstr"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

- (void)testAliasInactive {
  [config setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test1", @"inactive", nil]];

  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"shortalias"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias"] toLinkFor:@"inside"];
  
  [outsideEx verify]; [outsideEx release]; outsideEx = nil;
}

@end