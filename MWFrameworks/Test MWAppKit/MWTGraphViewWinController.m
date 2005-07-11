/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTGraphViewWinController.h"

@implementation MWTGraphViewWinController

static NSSet *demoNodes, *otherNodes;
static id centerNode;

- (void)awakeFromNib {
  id a = [[NSImage imageNamed:@"NSApplicationIcon"] retain],
     b = [[NSWorkspace sharedWorkspace] iconForFile:@"/"],
     c = [[[NSAttributedString alloc] initWithString:@"abcdef" attributes:nil] autorelease];

  centerNode = [a retain];
  demoNodes = [[NSSet setWithObjects:a, b, c, nil] retain];
  otherNodes = [[NSSet setWithObjects:b, c, nil] retain];
}

- (NSSet *)graphView:(MWGraphView *)sender nodesInRectangle:(NSRect)r {
  return demoNodes;
}

- (NSCell *)graphView:(MWGraphView *)sender cellForNode:(id)node {
  if ([node isKindOfClass:[NSImage class]]) {
    static NSImageCell *ic = nil;
    if (!ic) ic = [[NSImageCell alloc] init];
    return ic;
  } else {
    static NSTextFieldCell *ic = nil;
    if (!ic) ic = [[NSTextFieldCell alloc] init];
    return ic;
  }
}

- (NSSet *)graphView:(MWGraphView *)sender nodesAdjacentToNode:(id)node {
  return node == centerNode ? otherNodes : [NSSet setWithObject:centerNode];
}

- (NSRect)graphView:(MWGraphView *)sender frameOfNode:(id)node {
  if ([node isKindOfClass:[NSImage class]]) {
    NSSize isize = [(NSImage *)node size];
    return NSMakeRect(100.0 - isize.width / 2 + isize.width, 100.0 - isize.height / 2 + isize.width, isize.width, isize.height);
  } else {
    NSSize isize = [(NSAttributedString *)node size];
    return NSMakeRect(200, 100, isize.width, isize.height);
  }
}

- (NSRect)graphViewDataBounds:(MWGraphView *)sender {
  return NSMakeRect(-100, 0, 300, 800);
}

@end
