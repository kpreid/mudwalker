/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Control for choosing a font.
\*/

#import <AppKit/AppKit.h>


@interface MWFontSelectorView : NSControl {
 @private
  NSFont *font;
  void *MWFontSelectorView_future;
}

// use objectValue to get/set font

@end
