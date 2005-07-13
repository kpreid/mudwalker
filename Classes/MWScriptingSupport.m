/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWScriptingSupport.h"

#import "MWAppDelegate.h"

// http://www.omnigroup.com/mailman/archive/macosx-dev/2002-January/022385.html

@implementation MWGetURLScriptCommand

- (id)performDefaultImplementation {
  NSURL *url = [NSURL URLWithString:[self directParameter]];
  
  NSAssert(url != nil, @"Could not construct NSURL from event arguments");
    
  [(MWAppDelegate *)[NSApp delegate] makeDocumentForURL:url connect:YES];

  return nil;
}

@end
