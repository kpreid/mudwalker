/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MWAppKit/MWConfigPane.h>
#import <MWAppKit/MWConfigDirectoryEditPane.h>

@interface MWAppRegistryTest : TestCase {
} @end

@implementation MWAppRegistryTest

- (void)setUp {
  [MWRegistry setDefaultRegistry:nil];
}

- (void)tearDown {
}

- (void)testPreferencePane1 {
  MWRegistry *const reg = [MWRegistry defaultRegistry];
  NSArray *const one = [NSArray arrayWithObject:[MWConfigPane class]];
  //NSArray *const zero = [NSArray array];
  
  [reg registerPreferencePane:[MWConfigPane class] forScope:MWConfigScopeAll];
  [self assert:[reg preferencePanesForScope:MWConfigScopeDocument] equals:one message:@"scope document"];
  [self assert:[reg preferencePanesForScope:MWConfigScopeUser] equals:one message:@"scope user"];
}

- (void)testPreferencePane2 {
  MWRegistry *const reg = [MWRegistry defaultRegistry];
  NSArray *const one = [NSArray arrayWithObject:[MWConfigPane class]];
  NSArray *const zero = [NSArray array];
  
  [reg registerPreferencePane:[MWConfigPane class] forScope:MWConfigScopeUser];
  [self assert:[reg preferencePanesForScope:MWConfigScopeDocument] equals:zero message:@"scope document"];
  [self assert:[reg preferencePanesForScope:MWConfigScopeUser] equals:one message:@"scope user"];
}

- (void)testPreferencePaneSort {
  MWRegistry *const reg = [MWRegistry defaultRegistry];
  NSArray *const two = [NSArray arrayWithObjects:[MWConfigDirectoryEditPane class], [MWConfigPane class], nil];
  //NSArray *const zero = [NSArray array];
  
  [reg registerPreferencePane:[MWConfigPane class] forScope:MWConfigScopeUser];
  [reg registerPreferencePane:[MWConfigDirectoryEditPane class] forScope:MWConfigScopeUser];
  [self assert:[reg preferencePanesForScope:MWConfigScopeUser] equals:two message:@"scope user"];
}


@end