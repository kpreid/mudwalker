/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <Cocoa/Cocoa.h>

@interface MWURLLaunchRequest : NSWindowController {
  IBOutlet NSTextView *urlView;
}

+ (MWURLLaunchRequest *)requestWindowWithURL:(NSURL *)url;
- (void)setURL:(NSURL *)url;

- (IBAction)openURLAndClose:(id)sender;

@end
