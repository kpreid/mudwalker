/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLayoutView.h"

@interface MWLinearLayoutView : MWLayoutView {
  BOOL vertical;
  int alignment;
  int padding;
}

// Accessors
- (BOOL)vertical;
- (void)setVertical:(BOOL)val;
- (int)alignment;
- (void)setAlignment:(int)val;
- (int)padding;
- (void)setPadding:(int)val;


@end
