/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWMCPMappingWinController.h"

#import "MWMCPPackages.h"
#import <MWAppKit/MWGraphView.h>
#import <MWAppKit/MWToolbars.h>

@implementation MWMCPMappingWinController

- (id)initWithOwner:(MWMCP_dns_com_awns_visual *)owner {
  if (!(self = [super initWithWindowNibName:@"MWMCPMappingWindow"])) return nil;
  
  owningMCP = [owner retain];
  scaleFactor = rangeFactor = 1.0;

  toolbarItems = [[NSMutableDictionary allocWithZone:[self zone]] init];
  MWTOOLBAR_ITEM(@"clearMap", self, @selector(clearMap:));
  MWTOOLBAR_ITEM(@"zoomInScale", self, @selector(zoomInScale:));
  MWTOOLBAR_ITEM(@"zoomOutScale", self, @selector(zoomOutScale:));
  MWTOOLBAR_ITEM(@"zoomInRange", self, @selector(zoomInRange:));
  MWTOOLBAR_ITEM(@"zoomOutRange", self, @selector(zoomOutRange:));
  MWTOOLBAR_ITEM(@"centerHere", self, @selector(centerHere:));
  MWTOOLBAR_ITEM(@"relayout", self, @selector(relayout:));
  MWTOOLBAR_ITEM(@"fetchAll", self, @selector(fetchAll:));
  
  return self;
}

- (void)dealloc {
  [owningMCP autorelease]; owningMCP = nil;
  [toolbarItems autorelease]; toolbarItems = nil;
  [super dealloc];
}

- (void)windowDidLoad {
  NSToolbar *toolbar;

  [graph setNodeCell:[[[NSTextFieldCell alloc] initTextCell:@""] autorelease]];

  [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];

  toolbar = [[[NSToolbar alloc] initWithIdentifier:[[self class] description]] autorelease];
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:YES];
  [toolbar setAutosavesConfiguration:YES];
  [[self window] setToolbar:toolbar];
  
  [super windowDidLoad];
}

// ---

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  // Note that if we wanted to allow duplicate items, the items must be copied before returning. Otherwise, it's better not to.
  return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:
    @"zoomInScale", @"zoomOutScale", @"zoomInRange", @"zoomOutRange", NSToolbarSeparatorItemIdentifier, @"centerHere",
    NSToolbarFlexibleSpaceItemIdentifier,
    @"relayout", @"clearMap", @"fetchAll",
    nil
  ];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
  return [[[toolbarItems allKeys] sortedArrayUsingSelector:@selector(compare:)] arrayByAddingObjectsFromArray:
    [NSArray arrayWithObjects:
      NSToolbarSeparatorItemIdentifier,
      NSToolbarSpaceItemIdentifier,
      NSToolbarFlexibleSpaceItemIdentifier,
      nil
    ]
  ];
}

// ---

- (void)beginRepositioning {
  NSClipView *const clipView = (NSClipView *)[graph superview];
  NSRect viewBounds = [clipView bounds];
  NSPoint const viewCenter = NSMakePoint(NSMidX(viewBounds), NSMidY(viewBounds));

  NSPoint herePoint = {0, 0};
  NSValue *herePointV = [[[owningMCP topoCache] objectForKey:[owningMCP playerLocation]] objectForKey:@"position"];
  if (herePointV) {
    herePoint = [herePointV pointValue];
  }
  
  repositionMark = NSMakePoint(viewCenter.x / rangeFactor - herePoint.x, viewCenter.y / rangeFactor - herePoint.y);
}
- (void)endRepositioning {
  NSClipView *const clipView = (NSClipView *)[graph superview];
  NSSize viewSize = [clipView bounds].size;

  NSPoint herePoint = {0, 0};
  NSValue *herePointV = [[[owningMCP topoCache] objectForKey:[owningMCP playerLocation]] objectForKey:@"position"];
  if (herePointV) {
    herePoint = [herePointV pointValue];
  }
  
  [clipView setBoundsOrigin:NSMakePoint((repositionMark.x + herePoint.x) * rangeFactor - viewSize.width / 2, (repositionMark.y + herePoint.y) * rangeFactor - viewSize.height / 2)];
}

// ---

- (IBAction)clearMap:(id)sender {
  [owningMCP clearMap];
}

- (IBAction)zoomInScale:(id)sender {
  [self beginRepositioning];

  NSClipView *clipView = (NSClipView *)[graph superview];
  NSSize curFrame = [clipView frame].size;

  scaleFactor *= 1.2;

  [clipView setBoundsSize:NSMakeSize(
    curFrame.width / scaleFactor,
    curFrame.height / scaleFactor
  )];

  [self endRepositioning];
}
- (IBAction)zoomOutScale:(id)sender {
  [self beginRepositioning];

  NSClipView *clipView = (NSClipView *)[graph superview];
  NSSize curFrame = [clipView frame].size;

  scaleFactor /= 1.2;

  [clipView setBoundsSize:NSMakeSize(
    curFrame.width / scaleFactor,
    curFrame.height / scaleFactor
  )];
  [clipView setNeedsDisplay:YES];

  [self endRepositioning];
}
- (IBAction)zoomInRange:(id)sender {
  [self beginRepositioning];

  rangeFactor *= 1.2;
  [graph reloadData];

  [self endRepositioning];
}
- (IBAction)zoomOutRange:(id)sender {
  [self beginRepositioning];

  rangeFactor /= 1.2;
  [graph reloadData];
  
  [self endRepositioning];
}

- (IBAction)centerHere:(id)sender {
  NSSize pickSize = [[graph superview] bounds].size;

  NSValue *herePointV = [[[owningMCP topoCache] objectForKey:[owningMCP playerLocation]] objectForKey:@"position"];
  if (herePointV) {
    NSPoint herePoint = [herePointV pointValue];
    herePoint.x *= rangeFactor;
    herePoint.y *= rangeFactor;
    [graph scrollRectToVisible:NSMakeRect((int)herePoint.x - pickSize.width / 2, (int)herePoint.y - pickSize.height / 2, pickSize.width, pickSize.height)];
  }
}

- (IBAction)relayout:(id)sender {
  [owningMCP visualLayoutAllNodes];
  [owningMCP visualStartAutolayout];
}

- (IBAction)fetchAll:(id)sender {
  [owningMCP sendMCPMessage:@"dns-com-awns-visual-gettopology" args:[NSDictionary dictionaryWithObjectsAndKeys:
    [owningMCP playerLocation], @"location",
    @"200", @"distance",
    nil
  ]];
}

// ---


- (MWGraphView *)graph { return graph; }


- (NSDictionary *)normalNodeAttrs {
  static NSDictionary *d;
  if (!d) d = [[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
  return d;
}

// --- Graph view delegate ---

- (NSSet *)graphView:(MWGraphView *)sender nodesInRectangle:(NSRect)r {
  NSMutableDictionary *tdb = [owningMCP topoCache];
  
  NSRect testRect = NSInsetRect(r, -300, -25);
  
  NSMutableSet *ret = [NSMutableSet set];
  NSEnumerator *roomE = [tdb keyEnumerator];
  NSString *room;
  
  while ((room = [roomE nextObject])) {
    NSMutableDictionary *roomDict = [tdb objectForKey:room];
    NSPoint rp = [[roomDict objectForKey:@"position"] pointValue];
    rp.x *= rangeFactor;
    rp.y *= rangeFactor;
    // we'll just discard anything obviously not-here
    if (NSPointInRect(rp, testRect)) {
      [ret addObject:room];
    } else {
      // also use nodes that have edges potentially onscreen
      NSEnumerator *adjE = [[roomDict objectForKey:@"exits"] objectEnumerator];
      NSString *adj;
      NSMutableDictionary *adjDict;
      while ((adj = [adjE nextObject]))
        if ((adjDict = [tdb objectForKey:adj])) {
          NSValue *apv = [adjDict objectForKey:@"position"];
          NSPoint ap = [apv pointValue];
          ap.x *= rangeFactor;
          ap.y *= rangeFactor;
          if (apv && NSIntersectsRect(NSUnionRect(NSMakeRect(ap.x, ap.y, 1, 1), NSMakeRect(rp.x, rp.y, 1, 1)), testRect))
            [ret addObject:room];
        }
    }
  }

  return ret;
}

- (NSSet *)graphView:(MWGraphView *)sender nodesAdjacentToNode:(id)node {
  NSMutableDictionary *tdb = [owningMCP topoCache];
  
  NSMutableSet *adj = [NSMutableSet setWithCapacity:4];
  // return only adjacent nodes which we currently know about
  NSEnumerator *destE = [[[tdb objectForKey:node] objectForKey:@"exits"] objectEnumerator];
  NSString *dest;
  while ((dest = [destE nextObject])) {
    if ([tdb objectForKey:dest]) [adj addObject:dest];
  }

  return adj;
}

- (NSPoint)graphView:(MWGraphView *)sender centerOfNode:(id)node {
  NSDictionary *tdb = [owningMCP topoCache];
  NSValue *pv = [[tdb objectForKey:node] objectForKey:@"position"];
  NSPoint p = [pv pointValue];
  return pv ? NSMakePoint(p.x * rangeFactor, p.y * rangeFactor) : NSZeroPoint;
}

- (id)graphView:(MWGraphView *)sender cellValueForNode:(NSString *)node {
  NSDictionary *tdb = [owningMCP topoCache];
  NSString *here = [owningMCP playerLocation];
  NSDictionary *nodeDict = [tdb objectForKey:node];
  NSMutableDictionary *attrs = [[[self normalNodeAttrs] mutableCopy] autorelease];
  
  if ([node isEqual:here]) [attrs setObject:[NSNumber numberWithInt:1] forKey:NSUnderlineStyleAttributeName];
  if (![nodeDict objectForKey:@"gotNeighbors"]) [attrs setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
  
  //return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [nodeDict objectForKey:@"name"], NSStringFromPoint([[nodeDict objectForKey:@"position"] pointValue])] attributes:attrs] autorelease];
  return [[[NSAttributedString alloc] initWithString:[nodeDict objectForKey:@"name"] attributes:attrs] autorelease];
}

- (NSRect)graphViewDataBounds:(MWGraphView *)sender {
  NSRect r = [owningMCP extentRect];
  return NSMakeRect(r.origin.x * rangeFactor, r.origin.y * rangeFactor, r.size.width * rangeFactor, r.size.height * rangeFactor);
}


@end
