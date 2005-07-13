/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigStacker.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConstants.h>

@interface MWConfigStackerTest : TestCase {
  MWConfigTree *tree1;
  MWConfigTree *tree2;
  MWConfigStacker *stacker;
  ExpectationGroup *expectations;
} @end

@implementation MWConfigStackerTest

- (void)setUp {
  tree1 = [[MWConfigTree alloc] init];
  tree2 = [[MWConfigTree alloc] init];
  stacker = [[MWConfigStacker stackerWithSuppliers:tree1 :tree2] retain];
  
  [tree1 addDirectoryAtPath:[MWConfigPath pathWithComponent:@"Dir1"] recurse:NO insertIndex:-1];
  [tree2 addDirectoryAtPath:[MWConfigPath pathWithComponent:@"Dir2"] recurse:NO insertIndex:-1];
  [tree1 addDirectoryAtPath:[MWConfigPath pathWithComponent:@"DirBoth"] recurse:NO insertIndex:-1];
  [tree2 addDirectoryAtPath:[MWConfigPath pathWithComponent:@"DirBoth"] recurse:NO insertIndex:-1];
  [tree1 addDirectoryAtPath:[MWConfigPath pathWithComponents:@"DirBoth", @"Sub1", nil] recurse:NO insertIndex:-1];
  [tree2 addDirectoryAtPath:[MWConfigPath pathWithComponents:@"DirBoth", @"Sub2", nil] recurse:NO insertIndex:-1];
  
  [tree1 setObject:@"Foo1" atPath:[MWConfigPath pathWithComponent:@"ValBoth"]];
  [tree2 setObject:@"Foo2" atPath:[MWConfigPath pathWithComponent:@"ValBoth"]];
  [tree2 setObject:@"Bar2" atPath:[MWConfigPath pathWithComponent:@"Val2"]];
  
  expectations = nil;
}

- (void)tearDown {
  [tree1 release]; tree1 = nil;
  [tree2 release]; tree2 = nil;
  [stacker release]; stacker = nil;
  [expectations release]; expectations = nil;
}

- (void)testCreation {
  [self assertNotNil:tree1];
  [self assertNotNil:tree2];
  [self assertNotNil:stacker];
}

- (void)testObjectAtPath {
  [self assert:[stacker objectAtPath:[MWConfigPath pathWithComponent:@"ValBoth"]] equals:@"Foo1"];
  [self assertNil:[stacker objectAtPath:[MWConfigPath pathWithComponent:@"Nonexistent"]]];
  [self assert:[stacker objectAtPath:[MWConfigPath pathWithComponent:@"Val2"]] equals:@"Bar2"];
}

- (void)testObjectAtIndex {
#if 0
  NSLog(@"%@", [stacker objectAtIndex:0 inDirectoryAtPath:[MWConfigPath emptyPath]]);
  NSLog(@"%@", [stacker objectAtIndex:1 inDirectoryAtPath:[MWConfigPath emptyPath]]);
  NSLog(@"%@", [stacker objectAtIndex:2 inDirectoryAtPath:[MWConfigPath emptyPath]]);
  NSLog(@"%@", [stacker objectAtIndex:3 inDirectoryAtPath:[MWConfigPath emptyPath]]);
  NSLog(@"%@", [stacker objectAtIndex:4 inDirectoryAtPath:[MWConfigPath emptyPath]]);
#endif
  [self assert:[stacker objectAtIndex:2 inDirectoryAtPath:[MWConfigPath emptyPath]] equals:@"Foo1"];
  [self assert:[stacker objectAtIndex:4 inDirectoryAtPath:[MWConfigPath emptyPath]] equals:@"Bar2"];
}

- (void)testKeyAtIndex {
  [self assert:[stacker keyAtIndex:2 inDirectoryAtPath:[MWConfigPath emptyPath]] equals:@"ValBoth"];
  [self assert:[stacker keyAtIndex:3 inDirectoryAtPath:[MWConfigPath emptyPath]] equals:@"Dir2"];
  [self assert:[stacker keyAtIndex:4 inDirectoryAtPath:[MWConfigPath emptyPath]] equals:@"Val2"];
}

- (void)testCountAtPath {
  [self assertInt:[stacker countAtPath:[MWConfigPath emptyPath]] equals:5];
}

- (void)testAllKeysAtPath {
  [self assert:[stacker allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"Dir1", @"DirBoth", @"ValBoth", @"Dir2", @"Val2", nil]];
}

- (void)testAllValuesAtPath {
  NSArray *av = [stacker allValuesAtPath:[MWConfigPath emptyPath]];
  [self assert:[av objectAtIndex:2] equals:@"Foo1"];
  [self assert:[av objectAtIndex:4] equals:@"Bar2"];
}

- (void)testNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(treeNotification:) name:MWConfigSupplierChangedNotification object:stacker];
  
  expectations = [[ExpectationGroup alloc] initWithName:@""];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:2];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NewKey1"]];
  [[expectations setNamed        :@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NewKey2"]];

  [tree1 setObject:@"1" atPath:[MWConfigPath pathWithComponent:@"NewKey1"]];
  [tree2 setObject:@"2" atPath:[MWConfigPath pathWithComponent:@"NewKey2"]];

  [expectations verify];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:stacker];
}

- (void)treeNotification:(NSNotification *)notif {
  MWConfigPath *p = [[notif userInfo] objectForKey:@"path"];
  [[expectations counterNamed:@"number"] increment];
  [[expectations setNamed:@"path"] addActualObject:p ? (id)p : (id)[NSNull null]];
}

@end