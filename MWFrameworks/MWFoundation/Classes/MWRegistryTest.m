/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWRegistry.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>

@interface MWTestRegistrySubclass : MWRegistry @end
@implementation MWTestRegistrySubclass @end

@interface MWRegistryTest : TestCase {
} @end

@implementation MWRegistryTest

- (void)setUp {}

- (void)tearDown {
  [MWRegistry setDefaultRegistry:nil];
}

- (void)testAutoCreate {
  [self assertNotNil:[MWRegistry defaultRegistry]];
}

- (void)testSubclass {
  [MWRegistry setDefaultRegistry:[[[MWTestRegistrySubclass alloc] init] autorelease]];
  [self assertTrue:[[MWRegistry defaultRegistry] isKindOfClass:[MWTestRegistrySubclass class]]];
}

- (void)testConfig {
  MWRegistry *reg = [MWRegistry defaultRegistry];
  
  [[reg defaultConfig] setObject:@"a" atPath:[MWConfigPath pathWithComponent:@"defaultConfigKey"]];
  [[reg userConfig] setObject:@"b" atPath:[MWConfigPath pathWithComponent:@"userConfigKey"]];
  
  [self assert:[[reg config] objectAtPath:[MWConfigPath pathWithComponent:@"defaultConfigKey"]] equals:@"a"];
  [self assert:[[reg config] objectAtPath:[MWConfigPath pathWithComponent:@"userConfigKey"]] equals:@"b"];

  [[reg defaultConfig] setObject:@"c" atPath:[MWConfigPath pathWithComponent:@"defaultConfigKey"]];

  [self assert:[[reg config] objectAtPath:[MWConfigPath pathWithComponent:@"defaultConfigKey"]] equals:@"c"];
}

@end