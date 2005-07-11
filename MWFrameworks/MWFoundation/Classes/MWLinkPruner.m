/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLinkPruner.h"

@implementation MWLinkPruner

+ (void)pruneLater:(id <MWLinkable>)t {
  MWLinkPruner *i = [[[self alloc] init] autorelease];
  i->target = [t retain];
}

- (void)dealloc {
  [target linkPrune];
  [target release]; target = nil;
  [super dealloc];
}

@end
