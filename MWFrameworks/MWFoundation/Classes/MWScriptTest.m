/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWScript.h>
#import <MudWalker/MWScriptLanguage.h>
#import <MudWalker/MWRegistry.h>

@interface MWScriptTest : TestCase <MWScriptLanguage> {
  MWScript *script;
} @end

@implementation MWScriptTest

- (void)setUp {
  [MWRegistry setDefaultRegistry:[[[MWRegistry alloc] init] autorelease]];
  [[MWRegistry defaultRegistry] registerCapability:[NSArray arrayWithObjects:@"MWScriptLanguage", @"ScriptTestLanguage", nil] qualifiers:nil handler:self];
}

- (void)tearDown {
  [script release]; script = nil;
  [MWRegistry setDefaultRegistry:nil];
}

- (NSString *)languageIdentifier { return @"Test"; }
- (NSString *)localizedLanguageName { return @"Test"; }

- (NSString *)syntaxErrorsInScript:(MWScript *)lscript contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  return nil;
}

- (id)evaluateScript:(MWScript *)lscript arguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  return [script source];
}

- (void)testEmptyCreation {
  script = [[MWScript alloc] init];
  [self assertNotNil:script];
}

- (void)testValues {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];
  [self assert:[script source] equals:@"hithere"];
  [self assert:[script languageIdentifier] equals:@"ScriptTestLanguage"];
}

- (void)testNilLanguage {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:nil];
  [self assert:[script source] equals:@"hithere"];
  [self assertNil:[script languageIdentifier]];
}

- (void)testMutableValues {
  NSMutableString *s = [[NSMutableString alloc] initWithString:@"foo"];
  NSMutableString *l = [[NSMutableString alloc] initWithString:@"baz"];
  script = [[MWScript alloc] initWithSource:s languageIdentifier:l];
  [s setString:@"bar"];
  [l setString:@"qux"];
  [self assert:[script source] equals:@"foo"];
  [self assert:[script languageIdentifier] equals:@"baz"];
}

- (void)testEquality {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];
  MWScript *script2 = [[[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"] autorelease];
  [self assertTrue:[script isEqual:script2]];
}

- (void)testInequality {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];
  MWScript *script2 = [[[MWScript alloc] initWithSource:@"hith ere" languageIdentifier:@"ScriptTestLanguage"] autorelease];
  [self assertFalse:[script isEqual:script2]];
}

- (void)testCopying {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];
  
  [script autorelease];
  script = [script copy];

  [self assert:[script source] equals:@"hithere"];
}

- (void)testCoding {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];

  script = [[NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:[script autorelease]]] retain];

  [self assert:[script source] equals:@"hithere"];
  [self assert:[script languageIdentifier] equals:@"ScriptTestLanguage"];
}  

// - (void)testSyntaxCheck

- (void)testExecution {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];

  [self assert:[script evaluateWithArguments:[NSDictionary dictionary] contexts:nil location:@"MWScriptTest"] equals:@"hithere"];
}

- (void)testCompiledForm {
  script = [[MWScript alloc] initWithSource:@"hithere" languageIdentifier:@"ScriptTestLanguage"];

  [script setCompiledForm:@"compiled"];
  [self assert:[script compiledForm] equals:@"compiled"];  
}

@end