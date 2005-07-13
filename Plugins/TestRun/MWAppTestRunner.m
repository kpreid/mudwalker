/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWAppTestRunner.h"

#import <MudWalker/MWRegistry.h>
#import <AppKit/NSApplication.h>

@implementation MWAppTestRunner

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowRunTests:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)nowRunTests:(id)sender {
  TestRunnerMain(self);
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MWRunTests"]) {
    [NSApp terminate:nil];
  }
}

+ (TestSuite *)suite {
  TestSuite *suite = [TestSuite suiteWithName:@"MWApp All Tests"];
 
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWLuaLanguageTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWSubstitutedLuaLanguageTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWTriggerFilterTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWMCProtocolFilterTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWLibraryMenuControllerTest")]];
    
  return suite;
}

@end
