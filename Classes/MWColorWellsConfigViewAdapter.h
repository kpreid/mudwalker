/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MWAppKit/MWConfigViewAdapter.h>


@interface MWColorWellsConfigViewAdapter : MWConfigViewAdapter {
  IBOutlet NSView *viewContainingColorWells;
}

- (void)setViewContainingColorWells:(id)newVal;

@end
