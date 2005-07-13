/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Implements a button which is enabled/disabled via the validation mechanism.
\*/

#import <AppKit/AppKit.h>

@interface MWValidatedButton : NSButton <NSValidatedUserInterfaceItem>

- (void)validate;

@end
