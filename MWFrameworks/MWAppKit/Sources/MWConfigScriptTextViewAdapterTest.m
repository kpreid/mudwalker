/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>

#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWScript.h>
#import <AppKit/AppKit.h>
#import <MWAppKit/MWConfigViewAdapter.h>
#import <MWAppKit/MWValidatedButton.h>

@interface MWConfigScriptTextViewAdapterTest : TestCase {
  MWConfigTree *config;
  MWConfigPath *scriptPath;
  MWConfigScriptTextViewAdapter *cva;
  NSTextView *textView;
} @end

@implementation MWConfigScriptTextViewAdapterTest

- (void)setUp {
  scriptPath = [[MWConfigPath alloc] initWithComponent:@"script"];
  
  config = [[MWConfigTree alloc] init];
  [config setObject:[[[MWScript alloc] initWithSource:@"foo" languageIdentifier:@"FooLang"] autorelease] atPath:scriptPath];

  textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
  
  cva = [[MWConfigScriptTextViewAdapter alloc] initWithFrame:NSZeroRect];
  [cva setBasePath:[MWConfigPath emptyPath] discard:YES];
  [cva setRelativePath:scriptPath discard:YES];
  [cva setReadConfig:config];
  [cva setWriteConfig:config];
  [cva setControl:textView];
  [cva cvaUpdateFromConfig:nil];
}

- (void)tearDown {
  [scriptPath release];
  [config release];
  [cva release];
  [textView release];
}

- (void)testValidate_cvaUpdateFromConfig {
  MWValidatedButton *const revertButton = [[[MWValidatedButton alloc] initWithFrame:NSZeroRect] autorelease];
  [revertButton setAction:@selector(cvaUpdateFromConfig:)];
  
  [self assertFalse:[cva validateUserInterfaceItem:revertButton] message:@"revert should be disabled"];
  [textView setString:@"bar"];
  [self assertTrue:[cva validateUserInterfaceItem:revertButton] message:@"revert should be enabled"];
}

@end