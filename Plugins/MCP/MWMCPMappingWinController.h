/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWGraphView, MWMCP_dns_com_awns_visual;

@interface MWMCPMappingWinController : NSWindowController {
  MWMCP_dns_com_awns_visual *owningMCP;
  IBOutlet MWGraphView *graph;
  NSMutableDictionary *toolbarItems;
  double scaleFactor, rangeFactor;
  NSPoint repositionMark;
}

- (id)initWithOwner:(MWMCP_dns_com_awns_visual *)owner;
- (MWGraphView *)graph;

- (void)beginRepositioning;
- (void)endRepositioning;

- (IBAction)clearMap:(id)sender;
- (IBAction)zoomInScale:(id)sender;
- (IBAction)zoomOutScale:(id)sender;
- (IBAction)zoomInRange:(id)sender;
- (IBAction)zoomOutRange:(id)sender;
- (IBAction)centerHere:(id)sender;

@end
