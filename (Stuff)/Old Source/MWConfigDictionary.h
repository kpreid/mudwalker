/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import "MWConfigNode.h"

@interface MWConfigDictionary : NSMutableDictionary <MWConfigNode> {
  id <MWConfigNode> parentNode;
  NSMutableDictionary *nodeData;
}

@end
