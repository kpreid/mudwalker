/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <AppKit/AppKit.h>

@interface MWGraphView : NSView {
  id dataSource;
  NSCell *nodeCell;
  NSColor *backgroundColor;
}

- (void)reloadData;

- (NSCell *)cellForNode:(id)node;

- (id)dataSource;
- (void)setDataSource:(id)newVal;
- (NSCell *)nodeCell;
- (void)setNodeCell:(NSCell *)newVal;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newVal;

@end

@interface NSObject (MWGraphViewDataSource)

/* NOTE: The node objects returned by the data source must not be -isEqual: to any other node. */

- (NSSet *)graphView:(MWGraphView *)sender nodesInRectangle:(NSRect)r; // alternate 1
//- (id)graphView:(MWGraphView *)sender nodeInRectangleForDiscovery:(NSRect)r; // alternate 2

- (NSSet *)graphView:(MWGraphView *)sender nodesAdjacentToNode:(id)node; // optional but required if you want edges drawn

- (NSRect)graphView:(MWGraphView *)sender frameOfNode:(id)node;
// alternate 1
- (NSPoint)graphView:(MWGraphView *)sender centerOfNode:(id)node; // alternate 2, uses cell's -cellSize

- (NSCell *)graphView:(MWGraphView *)sender cellForNode:(id)node; // optional
- (id <NSCopying>)graphView:(MWGraphView *)sender cellValueForNode:(id)node; // optional

- (NSRect)graphViewDataBounds:(MWGraphView *)sender; // required

@end

