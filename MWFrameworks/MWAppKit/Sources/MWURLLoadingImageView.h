/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * Subclass of NSImageCell which implements loading an image from an arbitrary URL.
\*/

#import <AppKit/AppKit.h>

@interface MWURLLoadingImageView : NSImageView <NSURLHandleClient> {
  NSURL *theURL;
  NSURLHandle *urlHandle;
}

- (NSURL *)URL;
- (void)setURL:(NSURL *)newVal;

@end
