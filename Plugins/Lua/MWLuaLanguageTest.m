/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import "MWLuaLanguage.h"

#import <AppKit/NSSound.h>

@interface MWLuaLanguageTest : TestCase {
  MWRegistry *originalRegistry;
  MWScriptContexts *context;
} @end

@implementation MWLuaLanguageTest

- (void)setUp {
  originalRegistry = [[MWRegistry defaultRegistry] retain];
  [MWRegistry setDefaultRegistry:nil];
  [[MWRegistry defaultRegistry] registerScriptLanguage:[[MWLuaLanguage alloc] init]];
  context = [[MWScriptContexts alloc] init];
}

- (void)tearDown {
  [context release];
  [MWRegistry setDefaultRegistry:originalRegistry];
  [originalRegistry autorelease]; originalRegistry = nil;
}


- (void)testSoundNamed {
  MWScript *script = [[MWScript alloc] initWithSource:@"return soundNamed('Purr')" languageIdentifier:@"Lua"];
  [self 
    assert:[script evaluateWithArguments:[NSDictionary dictionaryWithObject:@"return" forKey:@"_MWScriptResultHint"] contexts:context location:@"test"]
    equals:[NSSound soundNamed:@"Purr"]
  ];
}

@end