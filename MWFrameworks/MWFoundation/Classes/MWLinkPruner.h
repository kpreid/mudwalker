/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLink.h"

// MWLinkPruner manages removal of filters that are linked only on one side, and other such situations that refcounting won't take care of.

@interface MWLinkPruner : NSObject {
  id <MWLinkable>target;
}

+ (void)pruneLater:(id <MWLinkable>)t;

@end
