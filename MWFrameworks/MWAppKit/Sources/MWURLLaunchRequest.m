/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWURLLaunchRequest.h"

@implementation MWURLLaunchRequest

+ (MWURLLaunchRequest *)requestWindowWithURL:(NSURL *)url {
  MWURLLaunchRequest *wc = [[[self alloc] init] autorelease];
  [wc setURL:url];
  return wc;
}

- (MWURLLaunchRequest *)init {
  if (!(self = [super initWithWindowNibName:@"MWURLLaunchRequest"])) return nil; 
  
  [self retain];
      
  return self;
}

- (void)windowWillClose:(NSNotification *)notif {
  [self autorelease];
}

- (IBAction)openURLAndClose:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlView string]]];
  [[self window] close];
}

- (void)setURL:(NSURL *)url {
  [self window];
  [urlView setString:[url absoluteString]];
}

@end
