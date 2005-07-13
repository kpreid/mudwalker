/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConstants.h>
#import <MudWalker/MWConfigStacker.h> // for the scope test only

@interface MWConfigTreeTest : TestCase {
  NSUndoManager *um;

  MWConfigPath *path1;
  MWConfigPath *path2;
  MWConfigPath *path12;
  
  MWConfigTree *tree;
  MWConfigTree *filledTree;
  
  ExpectationGroup *expectations;
} @end

@implementation MWConfigTreeTest

- (void)setUp {
  um = [[NSUndoManager alloc] init];
  [um setGroupsByEvent:NO];
  [um beginUndoGrouping];

  path1 = [[MWConfigPath pathWithComponent:@"test1"] retain];
  path2 = [[MWConfigPath pathWithComponent:@"test2"] retain];
  path12 = [[MWConfigPath pathWithComponents:@"test1", @"test2", nil] retain];
  
  tree = [[MWConfigTree alloc] init];
  [tree setUndoManager:um];
  
  filledTree = [[MWConfigTree alloc] init];
  [filledTree setUndoManager:um];
  
  [filledTree addDirectoryAtPath:path1 recurse:NO insertIndex:-1];
  [filledTree setObject:@"Bar" atPath:path12];
  [filledTree setObject:@"Foo" atPath:path2];
  [filledTree setObject:@"Third" atPath:[MWConfigPath pathWithComponent:@"thirdKey"]];
  
  expectations = nil;
}

- (void)tearDown {
  [um endUndoGrouping];
  [um release]; um = nil;
  [path1 release]; path1 = nil;
  [path2 release]; path2 = nil;
  [path12 release]; path12 = nil;
  [tree release]; tree = nil;
  [filledTree release]; filledTree = nil;
  [expectations release]; expectations = nil;
}

/* Utility method: Check that filledTree or something which is identical to it is correct. */
- (void)doAssertsOnFilledTree:(MWConfigTree *)ft {
  [self assert:[ft objectAtPath:path12] equals:@"Bar"];
  [self assert:[ft objectAtPath:path2] equals:@"Foo"];
  [self assertInt:[ft countAtPath:[MWConfigPath emptyPath]] equals:3 message:@"incorrect countAtPath for root"];
  [self assertInt:[ft countAtPath:path1] equals:1 message:@"incorrect countAtPath for subdirectory"];
  [self assert:[ft allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test1", @"test2", @"thirdKey", nil] message:@"incorrect allKeysAtPath for root"];
  [self assert:[ft allKeysAtPath:path1] equals:[NSArray arrayWithObject:@"test2"] message:@"incorrect allKeysAtPath for subdirectory"];
}

- (void)testCreation {
  [self assertNotNil:tree];
  [self assertNotNil:filledTree];
  [self assertNotNil:path1];
  [self assertNotNil:path2];
  [self assertNotNil:path12];
  [self assertNotNil:um];
}

- (void)testPathBasic {
  [self assert:path1 equals:path1 message:@"path not equal to itself"];
  [self assert:path1 equals:[MWConfigPath pathWithComponent:@"test1"] message:@"path not equal to equivalent"];
  [self assertFalse:[path1 isEqual:path12] message:@"path equal to unequal object"];
  [self assertFalse:[path1 isEqual:[NSNotificationCenter defaultCenter]]];
  [self assert:[path1 description] equals:@"<MWConfigPath>/test1" message:@"path not printing correctly"];
  
  [self assert:[MWConfigPath pathWithStringRepresentation:@"/test1"] equals:path1];
  [self assert:[MWConfigPath pathWithStringRepresentation:@"/test1/test2"] equals:path12];
  [self assertNil:[MWConfigPath pathWithStringRepresentation:@"test1/test2"]];
  [self assert:[MWConfigPath pathWithStringRepresentation:@"/%2f"] equals:[MWConfigPath pathWithComponent:@"/"]];
  
  [self assertFalse:[[MWConfigPath pathWithComponents:@"a", @"b", nil] isEqual:[MWConfigPath pathWithComponent:@"a/b"]]];
  [self assertFalse:[[MWConfigPath pathWithComponents:@"a", @"b", nil] isEqual:[MWConfigPath pathWithComponent:@"a%b"]]];
  [self assertFalse:[[MWConfigPath pathWithComponent:@"a/b"] isEqual:[MWConfigPath pathWithComponent:@"a%b"]]];
  
  // !!! this is poking at semi-private aspects of the implementation. but it's convenient to check the escaping.
  [self assert:[[MWConfigPath pathWithComponents:@"a%/%%b%///c", @"a%/%%b%///c", nil] stringRepresentation] equals:@"/a%25%2f%25%25b%25%2f%2f%2fc/a%25%2f%25%25b%25%2f%2f%2fc"];
}

- (void)testPathPrefix {
  [self assertTrue:[path12 hasPrefix:path1]];
  [self assertTrue:[path1 hasPrefix:path1]];
  [self assertTrue:[[MWConfigPath emptyPath] hasPrefix:[MWConfigPath emptyPath]]];
  [self assertTrue:[path12 hasPrefix:[MWConfigPath emptyPath]]];
  [self assertTrue:[path1  hasPrefix:[MWConfigPath emptyPath]]];
  [self assertFalse:[path1 hasPrefix:path2]];
  [self assertFalse:[[MWConfigPath emptyPath] hasPrefix:path1]];
  [self assertFalse:[[MWConfigPath pathWithComponent:@"footing"] hasPrefix:[MWConfigPath pathWithComponent:@"foo"]]];
  
  // test for crash
  [path1 hasPrefix:nil];
  [path2 hasPrefix:nil];
  [path12 hasPrefix:nil];
}

- (void)testPathCreation {
  [self assert:[MWConfigPath emptyPath] equals:[MWConfigPath emptyPath]];
  [self assert:path1 equals:[MWConfigPath pathWithComponent:@"test1"]];
  [self assert:path1 equals:[MWConfigPath pathWithComponents:@"test1", nil]];
  [self assert:path1 equals:[MWConfigPath pathWithArray:[NSArray arrayWithObject:@"test1"]]];
}

- (void)testPathCoding {
  MWConfigPath *rebuilt;

  rebuilt = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:path1]];
  [self assert:rebuilt equals:path1];
}  

- (void)testTreeSetRetrieve {
  [tree setObject:@"Foo" atPath:path1];
  [self assert:[tree objectAtPath:path1] equals:@"Foo"];
  [self assert:[tree objectAtPath:[MWConfigPath pathWithComponent:@"test1"]] equals:@"Foo"];
  [self assertNil:[tree objectAtPath:[MWConfigPath pathWithComponent:@"nonexistentkey"]]];

  [tree setObject:@"Foot" atPath:path1];
  [self assert:[tree objectAtPath:path1] equals:@"Foot"];
}

- (void)testTreeNilFetch {
  [tree objectAtPath:nil];
  [tree objectAtIndex:0 inDirectoryAtPath:nil];
}

- (void)testTreeDirectory {
  [tree addDirectoryAtPath:path1 recurse:NO insertIndex:-1];
  [self assertNotNil:[tree objectAtPath:path1]];
  
  [self assertTrue:[tree isDirectoryAtPath:path1]];
  
  // try putting an object in a dir
  [tree setObject:@"Bar" atPath:path12];
  [self assert:[tree objectAtPath:path12] equals:@"Bar"];
  [self assertFalse:[tree isDirectoryAtPath:path12]];
  
  // try putting an object at the root with the same key as used in the dir
  [tree setObject:@"Foo" atPath:path2];
  [self assertFalse:[tree isDirectoryAtPath:path2]];
  
  [tree setObject:@"Third" atPath:[MWConfigPath pathWithComponent:@"thirdKey"]];
  [self doAssertsOnFilledTree:tree];
  
  [tree removeItemAtPath:path1 recurse:YES];
  
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test2", @"thirdKey", nil] message:@"incorrect allKeysAtPath for root after removal"];
}

- (void)testRecursiveDirectory {
  MWConfigPath *bigPath = [MWConfigPath pathWithComponents:@"test1", @"Foo", @"Bar", @"Baz", @"abc", @"1", @"2", @"3", nil];
  MWConfigPath *subPath = [bigPath pathByAppendingComponent:@"4"];
  
  [filledTree addDirectoryAtPath:bigPath recurse:YES insertIndex:-1];
  [filledTree setObject:@"RValue" atPath:subPath];
  
  // check for a particular bug
  [self assert:[filledTree allKeysAtPath:[MWConfigPath pathWithComponents:@"test1", @"Foo", @"Bar", nil]] equals:[NSArray arrayWithObject:@"Baz"]];
  
  [self assert:[filledTree objectAtPath:subPath] equals:@"RValue"];
  [filledTree removeItemAtPath:path1 recurse:YES];
  [self assert:[filledTree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test2", @"thirdKey", nil]];
  
  // NSLog(@"%@", filledTree);
}

- (void)testTreeOrderingAndUndo {
  [um beginUndoGrouping];
  [tree setObject:@"Foo" atPath:path1];
  [tree setObject:@"Bar" atPath:path2];
  [um endUndoGrouping];
  
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test1", @"test2", nil] message:@"key ordering incorrect"];
  
  [um beginUndoGrouping];
  [tree removeItemAtPath:path1 recurse:NO];
  [tree setObject:@"Foo" forKey:@"test1" atPath:[MWConfigPath emptyPath] insertIndex:1];
  [um endUndoGrouping];

  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test2", @"test1", nil] message:@"key ordering incorrect after shuffle"];
  
  [um undoNestedGroup];
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test1", @"test2", nil] message:@"key ordering incorrect after undo"];

  [um undoNestedGroup];
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray array] message:@"key existence incorrect after undo"];
}

- (void)testTreeOrdering2 {
  [tree setObject:@"Foo" atPath:path2];
  [tree setObject:@"Bar" atPath:path1];
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test2", @"test1", nil] message:@"key ordering incorrect"];
}

- (void)testTreeIndexOfKey {
  [tree setObject:@"def" forKey:@"two" atPath:[MWConfigPath emptyPath]];
  [tree setObject:@"ghi" forKey:@"three" atPath:[MWConfigPath emptyPath]];
  
  [self assertInt:[tree indexOfKey:@"one" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:NSNotFound];
  [self assertInt:[tree indexOfKey:@"two" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:0];
  [self assertInt:[tree indexOfKey:@"three" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:1];
  
  [tree setObject:@"abc" forKey:@"one" atPath:[MWConfigPath emptyPath] insertIndex:0];
  
  [self assertInt:[tree indexOfKey:@"one" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:0];
  [self assertInt:[tree indexOfKey:@"two" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:1];
  [self assertInt:[tree indexOfKey:@"three" inDirectoryAtPath:[MWConfigPath emptyPath]] equals:2];
}

- (void)testAllValues {
  [tree setObject:@"Foo" atPath:path1];
  [tree setObject:@"Bar" atPath:path2];
  [self assert:[tree allKeysAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"test1", @"test2", nil]];
  [self assert:[tree allValuesAtPath:[MWConfigPath emptyPath]] equals:[NSArray arrayWithObjects:@"Foo", @"Bar", nil]];
}

- (void)testTreeCopying {
  MWConfigTree *treeCopy = nil;
  
  treeCopy = [[filledTree copy] autorelease];
  
  [self doAssertsOnFilledTree:treeCopy];
  
  [filledTree setObject:@"Foot" atPath:path2];
  
  [self assert:[filledTree objectAtPath:path2] equals:@"Foot"];
  [self assert:[treeCopy objectAtPath:path2] equals:@"Foo"];
  
  // mutableCopy should give the same results as copy
  treeCopy = [[filledTree mutableCopy] autorelease];

  [self assert:[treeCopy objectAtPath:path12] equals:@"Bar"];
  [self assert:[treeCopy objectAtPath:path2] equals:@"Foot"];
  [self assertInt:[treeCopy countAtPath:[MWConfigPath emptyPath]] equals:3 message:@"incorrect countAtPath for root in mutable copy"];
  [self assertInt:[treeCopy countAtPath:path1] equals:1 message:@"incorrect countAtPath for subdirectory in mutable copy"];
}

- (void)testTreeCopyingDirectories {
  // Checking for aliasing of directories in tree copies
  MWConfigTree *treeCopy = nil;

  treeCopy = [[filledTree copy] autorelease];
  [treeCopy setObject:@"Foot" atPath:[MWConfigPath pathWithComponent:@"NewKey"]];
  [self doAssertsOnFilledTree:filledTree];

  treeCopy = [[filledTree copy] autorelease];
  [filledTree setObject:@"Foot" atPath:[MWConfigPath pathWithComponent:@"NewKey"]];
  [self doAssertsOnFilledTree:treeCopy];
}

- (void)testTreeSubcopying {
  MWConfigTree *fragment = [filledTree subtreeFromDirectoryAtPath:path1];
  
  //NSLog(@"Original: %@", filledTree);
  //NSLog(@"Extract: %@", fragment);
  
  [self assert:[fragment objectAtPath:path2] equals:@"Bar" message:@"after extract"];
  
  [um beginUndoGrouping];
  [tree addDirectoryAtPath:path1 recurse:NO insertIndex:-1];
  [tree addEntriesFromTree:fragment atPath:path1 insertIndex:-1];

  //NSLog(@"Copied into: %@", tree);

  [self assert:[tree objectAtPath:path12] equals:@"Bar" message:@"after insert"];
  
  [um endUndoGrouping];
  [um undoNestedGroup];
  [self assertInt:[tree countAtPath:[MWConfigPath emptyPath]] equals:0];
}

- (void)testTreeReplacement {
  [tree setConfig:filledTree];
  [self doAssertsOnFilledTree:tree];
}

- (void)testTreeNonexistentKey {
  int i;
  for (i = 0; i < 50; i++) {
    NSString *nk = [filledTree nonexistentKeyAtPath:path1];
    MWConfigPath *np;
    [self assertNil:[filledTree objectAtPath:[path1 pathByAppendingComponent:nk]]];
    [filledTree setObject:@"NonexistenceTest" atPath:[path1 pathByAppendingComponent:nk]];
    
    np = [filledTree nonexistentPathAtPath:path1];
    [self assertNil:[filledTree objectAtPath:np]];
    [filledTree setObject:@"NonexistenceTest" atPath:np];
  }
}

#if 0
- (void)testTreeNonexistentKeyScope {
  MWConfigStacker *stack = [MWConfigStacker stackerWithSuppliers:tree :filledTree];
  int i;
  [tree setScope:@"Scope1"];
  [filledTree setScope:@"Scope2"];
  
  [tree addDirectoryAtPath:path1 recurse:NO insertIndex:-1];
  
  for (i = 0; i < 50; i++) {

    MWConfigPath *np = [filledTree nonexistentPathAtPath:path1];
    
    [filledTree setObject:@"NonexistenceTest" atPath:np];
    
    np = [tree nonexistentPathAtPath:path1];
    [tree setObject:@"NonexistenceTest" atPath:np];
  }
  
  [self assertInt:[stack countAtPath:path1] equals:100];
}
#endif

- (void)testTreeCoding {
  MWConfigTree *rebuilt;

  rebuilt = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:filledTree]];
  [self doAssertsOnFilledTree:rebuilt];
  
  // check mutability
  [rebuilt setObject:@"Bar" atPath:[MWConfigPath pathWithComponent:@"foo"]];
  [self assert:[rebuilt objectAtPath:[MWConfigPath pathWithComponent:@"foo"]] equals:@"Bar"];
}  

- (void)testNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(treeNotification:) name:MWConfigSupplierChangedNotification object:filledTree];
  
  expectations = [[ExpectationGroup alloc] initWithName:@"setObject:atPath:  notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:1];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NewKey"]];

  [filledTree setObject:@"Baz" atPath:[MWConfigPath pathWithComponent:@"NewKey"]];
  
  [expectations verify];
  
  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"setObject:forKey:atPath: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:1];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponents:@"test1", @"NewKey2", nil]];

  [filledTree setObject:@"Baz" forKey:@"NewKey2" atPath:path1];
  
  [expectations verify];
  
  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"setObject:forKey:atPath:insertIndex: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:1];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NewKey3"]];

  [filledTree setObject:@"Baz" forKey:@"NewKey3" atPath:[MWConfigPath emptyPath] insertIndex:-1];
  
  [expectations verify];

  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"addDirectoryAtPath:recurse:insertIndex: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:1];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NotifTestDir"]];

  [filledTree addDirectoryAtPath:[MWConfigPath pathWithComponent:@"NotifTestDir"] recurse:NO insertIndex:-1];
  
  [expectations verify];

  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"addEntriesFromDictionary:atPath:insertIndex: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:2];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponents:@"NotifTestDir", @"K1", nil]];
  [[expectations setNamed:@"path"] addExpectedObject:[MWConfigPath pathWithComponents:@"NotifTestDir", @"K2", nil]];

  [filledTree addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
    @"V1", @"K1",
    @"V2", @"K2",
    nil
  ] atPath:[MWConfigPath pathWithComponent:@"NotifTestDir"] insertIndex:-1];
  
  [expectations verify];

  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"removeItemAtPath:recurse: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:3];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[MWConfigPath pathWithComponent:@"NotifTestDir"]];
  [[expectations setNamed:@"path"] addExpectedObject:[MWConfigPath pathWithComponents:@"NotifTestDir", @"K1", nil]];
  [[expectations setNamed:@"path"] addExpectedObject:[MWConfigPath pathWithComponents:@"NotifTestDir", @"K2", nil]];

  [filledTree removeItemAtPath:[MWConfigPath pathWithComponent:@"NotifTestDir"] recurse:YES];
  
  [expectations verify];

  [expectations release];
  expectations = [[ExpectationGroup alloc] initWithName:@"setConfig: notification"];
  [[expectations addedCounterWithName:@"number"] setExpectedCount:1];
  [[expectations addedSetWithName:@"path"] addExpectedObject:[NSNull null]];

  [filledTree setConfig:tree];
  
  [expectations verify];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:filledTree];
}

- (void)treeNotification:(NSNotification *)notif {
  MWConfigPath *p = [[notif userInfo] objectForKey:@"path"];
  //NSLog(@"%@", [notif userInfo]);
  [[expectations counterNamed:@"number"] increment];
  [[expectations setNamed:@"path"] addActualObject:p ? (id)p : (id)[NSNull null]];
}

- (void)testTreeNiceDescription {
  [self assert:[filledTree description] equals:@"<MWConfigTree>\n    test1/\n        test2 = Bar\n    test2 = Foo\n    thirdKey = Third\n</MWConfigTree>"];
}

@end