/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Tests for MWFoundation aka MudWalker.framework.
\*/

#import <Foundation/Foundation.h>
#import <ObjcUnit/ObjcUnit.h>

@interface MWFoundationAllTests : NSObject
+ (TestSuite *)suite;
@end

@implementation MWFoundationAllTests
+ (TestSuite *)suite {
  TestSuite *suite = [TestSuite suiteWithName:@"MWFoundation All Tests"];
 
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWConfigTreeTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWConfigStackerTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWNSStringAdditionsTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWNSScannerAdditionsTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWRegistryTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWScriptTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWTokenTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWURLFormatterTest")]];
    
  return suite;
}
@end

int main(void) {
  return TestRunnerMain([MWFoundationAllTests class]);
}
