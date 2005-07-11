/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import "MWLuaLanguage.h"
#import "MWSubstitutedLuaLanguage.h"

@interface MWSubstitutedLuaLanguageTest : TestCase {
  MWRegistry *originalRegistry;
  MWSubstitutedLuaScriptWriter *ssw;
  MWScriptContexts *context;
} @end

@implementation MWSubstitutedLuaLanguageTest

- (void)setUp {
  originalRegistry = [[MWRegistry defaultRegistry] retain];
  [MWRegistry setDefaultRegistry:nil];
  [[MWRegistry defaultRegistry] registerScriptLanguage:[[MWLuaLanguage alloc] init]];
  [[MWRegistry defaultRegistry] registerScriptLanguage:[[MWSubstitutedLuaLanguage alloc] init]];
  ssw = [[MWSubstitutedLuaScriptWriter alloc] init];
  context = [[MWScriptContexts alloc] init];
}

- (void)tearDown {
  [ssw release];
  [context release];
  [MWRegistry setDefaultRegistry:originalRegistry];
  [originalRegistry autorelease]; originalRegistry = nil;
}

- (void)testWriterSimpleLiteral {
  [ssw inputLiteral:@"hi"];
  [self assert:[ssw result] equals:@"send(\"hi\")\n"];
}

- (void)testWriterMultilineLiteral {
  [ssw inputLiteral:@"hi\nthere"];
  [self assert:[ssw result] equals:@"send(\"hi\")\nsend(\"there\")\n"];
}

- (void)testWriterStatement {
  [ssw inputLiteral:@"hi\n"];
  [ssw inputCode:@"doSomething()"];
  [ssw inputLiteral:@"there"];
  [self assert:[ssw result] equals:@"send(\"hi\")\ndoSomething()\nsend(\"there\")\n"];
}

- (void)testWriterEmptyScript {
  [ssw inputLiteral:@""];
  [self assert:[ssw result] equals:@""];
}

- (void)testWriterEmptyLine {
  [ssw inputLiteral:@"\n"];
  [self assert:[ssw result] equals:@"send(\"\")\n"];
}

- (void)testWriterExpr {
  [ssw inputLiteral:@"hi"];
  [ssw inputExpr:@"returnSomething()"];
  [ssw inputLiteral:@"there"];
  [self assert:[ssw result] equals:@"send(\"hi\" .. returnSomething() .. \"there\")\n"];
}

- (void)testSimpleLiteral {
  MWScript *script = [[MWScript alloc] initWithSource:@"hi" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"hi"
  ];
}

- (void)testMultilineLiteral {
  MWScript *script = [[MWScript alloc] initWithSource:@"hi\nthere" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"hi\nthere"
  ];
}

- (void)testEscaping {
  MWScript *script = [[MWScript alloc] initWithSource:@"one\"two'three\\four\\\\five" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"one\"two'three\\four\\\\five"
  ];
}

- (void)testStatement {
  MWScript *script = [[MWScript alloc] initWithSource:@"one\n@@ send('two')\nthree\n" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"one\ntwo\nthree"
  ];
}

- (void)testBlock {
  MWScript *script = [[MWScript alloc] initWithSource:@"@@if true then\none\n@@else\ntwo\n@@end" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"one"
  ];
}

- (void)testExpr {
  MWScript *script = [[MWScript alloc] initWithSource:@"1 + 1 = $( 1 + 1 )$" languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"1 + 1 = 2"
  ];
}

- (void)testSimpleExpr {
  MWScript *script = [[MWScript alloc] initWithSource:@"the hint is $$arg._MWScriptResultHint ." languageIdentifier:@"SubstitutedLua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:@"the hint is return ."
  ];
}

@end