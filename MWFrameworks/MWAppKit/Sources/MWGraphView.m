/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWGraphView.h"


@implementation MWGraphView

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;

  nodeCell = [[NSImageCell alloc] initImageCell:nil];
  backgroundColor = [[NSColor controlBackgroundColor] retain];

  return self;
}

- (void)dealloc {
  [dataSource autorelease]; dataSource = nil;
  [nodeCell autorelease]; nodeCell = nil;
  [backgroundColor autorelease]; backgroundColor = nil;

  [super dealloc];
}

- (void)reloadData {
  id ds = [self dataSource];
  NSRect b = [ds graphViewDataBounds:self];
  
  [self setFrameSize:b.size];
  [self setBounds:b];

  [self setNeedsDisplay:YES];
}

- (NSCell *)cellForNode:(id)node {
  id ds = [self dataSource];
  if ([ds respondsToSelector:@selector(graphView:cellForNode:)])
    return [ds graphView:self cellForNode:node];
  else
    return [self nodeCell];
}

- (void)prepareCell:(NSCell *)cell toDraw:(id)node {
  id ds = [self dataSource];
  [cell setObjectValue:[ds respondsToSelector:@selector(graphView:cellValueForNode:)]
    ? [ds graphView:self cellValueForNode:node]
    : node
  ];
}

- (NSPoint)centerOfNode:(id)node {
  id ds = [self dataSource];
  if ([ds respondsToSelector:@selector(graphView:centerOfNode:)]) {
    return [ds graphView:self centerOfNode:node];
  } else {
    NSRect frame = [ds graphView:self frameOfNode:node];
    return NSMakePoint(NSMidX(frame), NSMidY(frame));
  }
}

- (NSRect)frameOfNode:(id)node cellReady:(BOOL)cellReady {
  id ds = [self dataSource];
  
  if ([ds respondsToSelector:@selector(graphView:frameOfNode:)])
    return [ds graphView:self frameOfNode:node];
  else {
    NSCell *cell = [self cellForNode:node];
    NSRect r;

    if (!cellReady)
      [self prepareCell:cell toDraw:node];
    
    r.origin = [ds graphView:self centerOfNode:node];
    r.size = [cell cellSize];
    r.origin.x -= r.size.width / 2;
    r.origin.y -= r.size.height / 2;
    
    return r;
  }
}

// for the sake of scrollviews
- (BOOL)isFlipped { return YES; }

- (BOOL)isOpaque { return [[self backgroundColor] alphaComponent] >= 1.0; }

- (void)mouseDown:(NSEvent *)event {
  id ds = [self dataSource];
  NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
  NSRect r = NSMakeRect(p.x, p.y, 1, 1);
  NSSet *nodes = [ds graphView:self nodesInRectangle:r];
  NSEnumerator *nodeE = [nodes objectEnumerator];
  id node;
    
  while ((node = [nodeE nextObject])) {
    NSRect frame = [self frameOfNode:node cellReady:NO];
    if (NSPointInRect(p, frame)) {
      // ...
      NSBeep();
    }
  }
}

- (void)drawRect:(NSRect)destRect {
  id ds = [self dataSource];
  NSSet *nodes = [ds graphView:self nodesInRectangle:destRect];
  NSEnumerator *nodeE = nil;
  NSMutableSet *edgeAccum = [NSMutableSet set];
  id node;
  
  [[self backgroundColor] set];
  NSRectFill(destRect);
  
  // Find all visible edges
  if ([ds respondsToSelector:@selector(graphView:nodesAdjacentToNode:)]) {
    nodeE = [nodes objectEnumerator];
    while ((node = [nodeE nextObject])) {
      NSEnumerator *adjE = [[ds graphView:self nodesAdjacentToNode:node] objectEnumerator];
      id adj;
      while ((adj = [adjE nextObject])) {
        [edgeAccum addObject:[NSSet setWithObjects:node, adj, nil]];
      }
    }
  }
  
  // Draw visible edges
  {
    NSEnumerator *edgeE = [edgeAccum objectEnumerator];
    NSSet *edge;
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
    [NSBezierPath setDefaultLineWidth:1];
    while ((edge = [edgeE nextObject])) {
      NSEnumerator *edgeSubE = [edge objectEnumerator];
      id a = [edgeSubE nextObject], b = [edgeSubE nextObject];
      NSPoint centerA = [self centerOfNode:a];
      NSPoint centerB = [self centerOfNode:b];
      [NSBezierPath strokeLineFromPoint:centerA toPoint:centerB];
    }
  }
    
  // Draw visible nodes
  nodeE = [nodes objectEnumerator];
  while ((node = [nodeE nextObject])) {
    NSCell *cell = [self cellForNode:node];
    NSRect frame;

    [self prepareCell:cell toDraw:node];
    
    frame = [self frameOfNode:node cellReady:YES];
    if (NSIntersectsRect(frame, destRect)) {
      // want hook like NSTableView's tableView:willDisplayCell...
      [cell drawWithFrame:frame inView:self];
    }
  }
}

// --- Accessors ---

- (id)dataSource { return dataSource; }
- (void)setDataSource:(id)newVal {
  [dataSource autorelease];
  dataSource = [newVal retain];
  [self reloadData];
}

- (id)nodeCell { return nodeCell; }
- (void)setNodeCell:(id)newVal {
  [nodeCell autorelease];
  nodeCell = [newVal retain];
  [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor { return backgroundColor; }
- (void)setBackgroundColor:(NSColor *)newVal {
  [backgroundColor autorelease];
  backgroundColor = [newVal retain];
  [self setNeedsDisplay:YES];
}

@end
