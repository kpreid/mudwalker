/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWValidatedButton.h"

@implementation MWValidatedButton

- (void)validate {
  id target = [self target];
  
  if (!target) {
    target = [NSApp targetForAction:[self action]];
  }
  
  if ([target conformsToProtocol:@protocol(NSUserInterfaceValidations)]) {
    [self setEnabled:[(id <NSUserInterfaceValidations>)target validateUserInterfaceItem:self]];
  } else if ([self target]) {
    NSLog(@"Oops: %@'s target (%@) does not conform to NSUserInterfaceValidations", self, target);
  }
}

- (void)mouseEntered:(NSEvent *)event {
  [self validate];
  [super mouseEntered:event];
}
- (void)mouseDown:(NSEvent *)event {
  [self validate];
  [super mouseDown:event];
}

// GCC isn't checking protocol conformance correctly. Workaround.
- (int)tag { return [super tag]; }
- (SEL)action { return [super action]; }

@end
