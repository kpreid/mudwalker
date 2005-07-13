/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/


#import <Foundation/Foundation.h>

@class MWMudLibrary, NSMenu;

@interface MWLibraryMenuController : NSObject {
  NSMenu *theMenu;
  MWMudLibrary *theLibrary;
}

- (NSMenu *)menu;

- (void)setMenu:(NSMenu *)newVal;
- (void)setLibrary:(MWMudLibrary *)newVal;

@end
