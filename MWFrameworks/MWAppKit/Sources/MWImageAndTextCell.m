/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWImageAndTextCell.h"

#import <Foundation/Foundation.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>

@implementation MWImageAndTextCell

- (void)dealloc {
  [image autorelease]; image = nil;
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  MWImageAndTextCell *copy = [super copyWithZone:zone];
  copy->image = [image retain];
  return copy;
}

- (NSRect)privateImageFrameForCellFrame:(NSRect)cellFrame {
  NSSize isize = [image size];
  float extra = image && isize.height ? ceil(isize.width / isize.height * cellFrame.size.height) : 0;
  return NSMakeRect(cellFrame.origin.x + 3, cellFrame.origin.y, extra, cellFrame.size.height);
}
- (NSRect)privateTextFrameForCellFrame:(NSRect)cellFrame {
  NSSize isize = [image size];
  float extra = image && isize.height ? ceil(isize.width / isize.height * cellFrame.size.height + 5) : 0;
  cellFrame.origin.x += extra;
  cellFrame.size.width -= extra;
  return cellFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
  NSRect textFrame = [self privateTextFrameForCellFrame:aRect];
  //NSLog(@"orig %@ adj %@", NSStringFromRect(aRect), NSStringFromRect(textFrame));
  [super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
  NSRect textFrame = [self privateTextFrameForCellFrame:aRect];
  [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if (image) {
    NSSize imageSize = [image size];
    NSRect imageFrame = [self privateImageFrameForCellFrame:cellFrame];
    
    if ([self drawsBackground]) {
      [[self backgroundColor] set];
      NSRectFill(imageFrame);
    }

    [image setFlipped:[controlView isFlipped]];
    [image drawInRect:imageFrame fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    [super drawWithFrame:[self privateTextFrameForCellFrame:cellFrame] inView:controlView];
  } else {
    [super drawWithFrame:cellFrame inView:controlView];
  }
}

- (NSSize)cellSize {
  NSSize cellSize = [super cellSize];
  cellSize.width += (image ? [image size].width : 0) + 3;
  return cellSize;
}


- (NSImage *)image { return image; }
- (void)setImage:(NSImage *)newVal {
  [image autorelease];
  image = [newVal retain];
}

@end