/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Tee filter branches off everything it receives, like this:
 *  
 *        teeOutward       teeInward
 *           ^|                |^
 *            \                /
 *             \              / 
 *  outward <---\------------/---< inward
 *  outward >---------------/----> inward
 *
\*/

#import "MWConcreteLinkable.h"

@interface MWTeeFilter : MWConcreteLinkable
@end



