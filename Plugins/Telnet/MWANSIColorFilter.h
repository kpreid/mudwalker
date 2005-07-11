/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MWConcreteLinkable.h>

@interface MWANSIColorFilter : MWConcreteLinkable {
 @private
  int
    styleForeColor,
    styleBackColor,
    styleBrightness;
  BOOL
    styleUnderline,
    styleBlinking,
    styleInverse;
}

@end
