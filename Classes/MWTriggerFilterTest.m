/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
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
  
  { NSString *const trigger = @"test";
    [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, nil] recurse:YES insertIndex:-1];
    [config setObject:@"triggerer" atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"patterns", nil]];
    [config setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"doSubstitute", nil]];
    [config setObject:[[[MWScript alloc] initWithSource:@"triggered" languageIdentifier:@"BaseIdentity"] autorelease] atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"doSubstitute_replacement", nil]];
  }
  
  { NSString *const trigger = @"arg-counter";
    [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, nil] recurse:YES insertIndex:-1];
    [config 
      setObject:@"^argtest ([^ ]*)$\n^argtest ([^ ]*) ([^ ]*)$\n^argtest ([^ ]*) ([^ ]*) ([^ ]*)$\n^argtest ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)$"
      atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"patterns", nil]];
    [config 
      setObject:[NSNumber numberWithBool:YES] 
      atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"doSubstitute", nil]];
    [config
       setObject:[[[MWScript alloc] initWithSource:@"return tostring(arg.count) .. \" \" .. tostring(arg[2])" languageIdentifier:@"Lua"] autorelease] 
       atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"doSubstitute_replacement", nil]];
  }
  
  { NSString *const trigger = @"gagger";
    [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, nil] recurse:YES insertIndex:-1];
    [config 
      setObject:@"^gagb$"
      atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"patterns", nil]];
    [config 
      setObject:[NSNumber numberWithBool:YES] 
      atPath:[MWConfigPath pathWithComponents:@"Triggers", trigger, @"doGag", nil]];
  }
  
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

- (void)waitAndVerify {
  [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.5]];
  [outsideEx verify]; 
  [insideEx verify];
  [outsideEx release]; outsideEx = nil;
  [insideEx release]; insideEx = nil;
}

- (void)testPassthruOut {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"hi"]];

  [stub send:[MWLineString lineStringWithString:@"hi"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testPassthruIn {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"hi"]];

  [stub send:[MWLineString lineStringWithString:@"hi"] toLinkFor:@"outside"];
  
  [self waitAndVerify];
}


// --- Triggers ---

- (void)testSubstituteTrigger {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"triggered"]];

  [stub send:[MWLineString lineStringWithString:@"triggerer"] toLinkFor:@"outside"];
  
  [insideEx verify]; [insideEx release]; insideEx = nil;
}

- (void)testGagTrigger {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"gaga"]];
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"gagc"]];

  [stub send:[MWLineString lineStringWithString:@"gaga"] toLinkFor:@"outside"];
  [stub send:[MWLineString lineStringWithString:@"gagb"] toLinkFor:@"outside"];
  [stub send:[MWLineString lineStringWithString:@"gagc"] toLinkFor:@"outside"];
  
  [self waitAndVerify];
}

- (void)testTriggerArgumentCount {
  [insideEx addExpectedObject:[MWLineString lineStringWithString:@"3 bar"]];
  
  [stub send:[MWLineString lineStringWithString:@"argtest foo bar baz"] toLinkFor:@"outside"];
  
  [self waitAndVerify];
}

// --- Aliases ---


- (void)testSimpleAlias {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"big long command string"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testWordAliasArg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"big long command string"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias argstr"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testWordAliasNonarg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"shortaliasargstr"]];

  [stub send:[MWLineString lineStringWithString:@"shortaliasargstr"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testPunctAliasArg {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"dollar at"]];

  [stub send:[MWLineString lineStringWithString:@"$@ argstr"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testAliasUseArgPunct {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"speech argstr"]];

  [stub send:[MWLineString lineStringWithString:@"\"argstr"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testAliasUseArgWord {
  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"speech argstr"]];

  [stub send:[MWLineString lineStringWithString:@"say argstr"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

- (void)testAliasInactive {
  [config setObject:[NSNumber numberWithBool:YES] atPath:[MWConfigPath pathWithComponents:@"Aliases", @"test1", @"inactive", nil]];

  [outsideEx addExpectedObject:[MWLineString lineStringWithString:@"shortalias"]];

  [stub send:[MWLineString lineStringWithString:@"shortalias"] toLinkFor:@"inside"];
  
  [self waitAndVerify];
}

@end