/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * Subclass of NSTextFieldCell which can display text and an image simultaneously. This is based on the ImageAndTextCell included in Apple's DragNDropOutlineView example project.
\*/

#import <AppKit/NSTextFieldCell.h>

@interface MWImageAndTextCell : NSTextFieldCell {
  @private
    NSImage *image;
}

- (void)setImage:(NSImage *)newVal;
- (NSImage *)image;

@end