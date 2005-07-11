/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWMiscTestController.h"

#import <MWAppKit/MWKeyCapturingPanel.h>
#import <ObjcUnit/ObjcUnit.h>

@implementation MWMiscTestController

- (void)awakeFromNib {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowRunTests:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)nowRunTests:(id)sender {
  TestRunnerMain([self class]);
  [NSApp terminate:nil];
}

+ (TestSuite *)suite {
  TestSuite *suite = [TestSuite suiteWithName:@"MWAppKit Tests"];
 
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWConfigScriptTextViewAdapterTest")]];
  [suite addTest:[TestSuite suiteWithClass:NSClassFromString(@"MWAppRegistryTest")]];
    
  return suite;
}

- (IBAction)keyCapture:(id)sender {
  [MWKeyCapturingPanel captureKeyEventDelegate:self window:[sender window]];
}

@end
