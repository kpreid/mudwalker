/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLinearLayoutView.h"

#import "MWConstants.h"

@implementation MWLinearLayoutView

- (void)performLayout:(NSString *)reason {
  NSArray *subviews = [self subviews];
  NSEnumerator *e = nil;
  NSView *view = nil;
  float totalLength = padding, curLength = 0, maxWidth = 0;
  
  e = [subviews objectEnumerator];
  if (vertical) {
    while ((view = [e nextObject])) {
      NSRect f = [view frame];
      if (f.size.width > maxWidth) maxWidth = f.size.width;
      totalLength += f.size.height + padding;
    }
  } else {
    while ((view = [e nextObject])) {
      NSRect f = [view frame];
      if (f.size.height > maxWidth) maxWidth = f.size.height;
      totalLength += f.size.width + padding;
    }
  }
  maxWidth += padding * 2;
  
  e = [subviews objectEnumerator];
  if (vertical) {
    // special handling since we want top-to-bottom ordering
    curLength = totalLength;
    while ((view = [e nextObject])) {
      NSRect f = [view frame];
      int widPos;
      curLength -= f.size.height + padding;
      switch (alignment) {
        default:
        case MWAlignmentMin: widPos = 0; break;
        case MWAlignmentMid: widPos = maxWidth / 2 - f.size.width / 2; break;
        case MWAlignmentMax: widPos = maxWidth - f.size.width - padding; break;
      }
      [view setFrameOrigin:NSMakePoint(widPos, curLength)];
    }
    [self setFrameSize:NSMakeSize(maxWidth, totalLength)];
  } else {
    while ((view = [e nextObject])) {
      NSRect f = [view frame];
      int widPos;
      switch (alignment) {
        default:
        case MWAlignmentMin: widPos = 0; break;
        case MWAlignmentMid: widPos = maxWidth / 2 - f.size.height / 2; break;
        case MWAlignmentMax: widPos = maxWidth - f.size.height - padding; break;
      }
      [view setFrameOrigin:NSMakePoint(curLength + padding, widPos)];
      curLength += f.size.width + padding;
    }
    [self setFrameSize:NSMakeSize(totalLength, maxWidth)];
  }
}

- (BOOL)vertical { return vertical; }
- (void)setVertical:(BOOL)val {
  vertical = val;
  [self performLayout:MWLayoutAttributesChanged];
}
- (int)alignment { return alignment; }
- (void)setAlignment:(int)val {
  alignment = val;
  [self performLayout:MWLayoutAttributesChanged];
}
- (int)padding { return padding; }
- (void)setPadding:(int)val {
  padding = val;
  [self performLayout:MWLayoutAttributesChanged];
}

@end
