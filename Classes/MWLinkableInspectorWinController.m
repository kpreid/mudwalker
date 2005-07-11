/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLinkableInspectorWinController.h"

#import <MudWalker/MWUtilities.h>
#import "MWLinkableObjectController.h"

#import <MWAppKit/MWOutputTextView.h>

static const float LargeNumberForText = 1.0e7; // borrowed from TextSizingExample

static NSMutableDictionary *linkablesToInspectors;

@interface MWLinkableInspectorWinController (Private)

- (void)updateAllControls;

@end

@implementation MWLinkableInspectorWinController

+ (void)initialize {
  if (!linkablesToInspectors) linkablesToInspectors = [[NSMutableDictionary alloc] init];
}

+ (void)checkImportant:(NSNotification *)notif {
  if ([[[notif userInfo] objectForKey:@"important"] boolValue] && ![[linkablesToInspectors objectForKey:MWKeyFromObjectIdentity([notif object])] count]) {
    id wc = [[self alloc] init];
    [wc setLOC:[MWLinkableObjectController locWithLinkable:[notif object]]];
    [wc makeTraceVisible];
    
    // ew fixme: the LOC is not otherwise created in time to get the notification, so we fake it:
    [[wc LOC] lnTrace:notif];
    
    [[wc window] orderFront:nil];
  }
}

- (MWLinkableInspectorWinController *)init {
  if (!(self = [super initWithWindowNibName:@"FilterInspector"])) return nil; 
  
  [self retain]; // balances the autorelease in windowWillClose:
  linkOrderings = [[NSMutableDictionary alloc] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lnChanged:) name:MWLinkChangedNotification object:nil];
  [cTraceText setAutoScrollToEnd:YES];
    
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [LOC autorelease]; LOC = nil;
  [linkOrderings autorelease]; linkOrderings = nil;
  [super dealloc];
}

- (void)windowDidLoad {
  NSTextContainer *textCon = [cTraceText textContainer];

  [cLinkBrowser setMaxVisibleColumns:3];
  [cLinkBrowser setMinColumnWidth:100];
  [cLinkBrowser setTakesTitleFromPreviousColumn:NO];
  [cLinkBrowser setTarget:self];
  [cLinkBrowser setAction:@selector(browserSingleClick:)];
  [cLinkBrowser setDoubleAction:@selector(browserDoubleClick:)];
  [[cLinkBrowser cellPrototype] setScrollable:YES];
  
  [cTraceText setAutoScrollToEnd:YES];
  
  // setup for horizontal scrollability
  [textCon setWidthTracksTextView:NO];
  [textCon setHeightTracksTextView:NO];
  [textCon setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
  [cTraceText setHorizontallyResizable:YES];
  [cTraceText setVerticallyResizable:YES];
  [cTraceText setMinSize:NSMakeSize(5,5)];
  [cTraceText setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];

  [cTraceScrollView setHasHorizontalScroller:YES];
  [cTraceScrollView setHasVerticalScroller:YES];
  
  [self updateAllControls];
  [super windowDidLoad];
}

- (void)windowWillClose:(NSNotification *)notif {
  [self setLOC:nil];
  [self autorelease];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return nil;
}

// --- Specific stuff ---

- (void)updateAllControls {
  id <MWLinkable>lo = [LOC target];
  if (!lo) return;
  if (![self window]) return;
  [[self window] setTitle:[lo linkableUserDescription]];
  [cLinkBrowser loadColumnZero];
}

- (void)updateTiedControls {
  if (![self window]) return;
  if (!LOC) return;
  [[cTraceText layoutManager] replaceTextStorage:[LOC traceStorage]];
}

- (void)showWindowBesideWindow:(NSWindow *)theirWindow {
  NSWindow *myWindow = [self window];
  NSSize mySize = [myWindow frame].size;
  NSRect theirFrame = [theirWindow frame];
 
  float myY = NSMaxY(theirFrame) - mySize.height - 20;
  float myStartX, myEndX;
 
  if (NSMidX(theirFrame) < ([[theirWindow screen] visibleFrame].size.width / 2)) {
    myStartX = NSMaxX(theirFrame) - mySize.width;
    myEndX = NSMaxX(theirFrame) + 1;
  } else {
    myStartX = NSMinX(theirFrame);
    myEndX = NSMinX(theirFrame) - mySize.width - 1;
  }
  
  [myWindow setFrameOrigin:NSMakePoint(myStartX, myY)];
  [myWindow orderWindow:NSWindowBelow relativeTo:[theirWindow windowNumber]];
  [myWindow setFrame:NSMakeRect(myEndX, myY, mySize.width, mySize.height) display:YES animate:YES];

  [myWindow makeKeyAndOrderFront:self];
}

- (void)makeTraceVisible {
  [self window];
  //[cTabs selectTabViewItem:cTraceTab];
}

// --- Notifications ---

- (void)lnChanged:(NSNotification *)notif {
  id <MWLinkable>changed = [notif object];
  NSEnumerator *e = [[[cLinkBrowser path] componentsSeparatedByString:[cLinkBrowser pathSeparator]] objectEnumerator];
  NSString *elem;
  id <MWLinkable>viewing = [LOC target];
  int column = -1;
  //printf("%s listening to change %s %s\n", [[self description] cString], [[changed description] cString], [[[[notif userInfo] objectForKey:@"link"] description] cString]);
  [e nextObject]; // skip initial /
  while ((column++, elem = [e nextObject])) {
    NSString *linkName = [[elem componentsSeparatedByString:@":"] objectAtIndex:0];
    //printf("%s checking %s at %i\n", [[self description] cString], [[viewing description] cString], column);
    if (changed == viewing) {
      //printf("  -- changed\n");
      [cLinkBrowser reloadColumn:column];
      break;
    } else {
      viewing = [[[viewing links] objectForKey:linkName] otherObject:viewing];
    }
  }
  //printf("  -- found nothing\n");
  [cLinkBrowser reloadColumn:0];
}

// --- Browser delegate ---

// Currently there is only one table view and one browser.

- (id <MWLinkable>)objectForColumnPath:(NSString *)colPath {
  NSEnumerator *e = [[colPath componentsSeparatedByString:[cLinkBrowser pathSeparator]] objectEnumerator];
  NSString *elem;
  id <MWLinkable>thing = [LOC target];
  [e nextObject]; // skip initial /
  while ((elem = [e nextObject])) {
    NSString *linkName = [[elem componentsSeparatedByString:@":"] objectAtIndex:0];
    thing = [[[thing links] objectForKey:linkName] otherObject:thing];
  }
  return thing;
}

- (NSArray *)linkOrderingForObject:(id <MWLinkable>)lo {
  NSArray *ordering;
  if (!lo) return [NSArray array];
  if (!(ordering = [linkOrderings objectForKey:MWKeyFromObjectIdentity(lo)])) {
    ordering = [[lo linkNames] allObjects];
    [linkOrderings setObject:ordering forKey:MWKeyFromObjectIdentity(lo)];
  }
  return ordering;
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
  id <MWLinkable>lo = [self objectForColumnPath:[sender pathToColumn:column]];
  //id <MWLinkable>loPrev = column > 0 ? [self objectForColumnPath:[sender pathToColumn:column-1]] : nil;
  
  return [[self linkOrderingForObject:lo] count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
  id <MWLinkable>lo = [self objectForColumnPath:[sender pathToColumn:column]];
  id <MWLinkable>loPrev = column > 0 ? [self objectForColumnPath:[sender pathToColumn:column-1]] : nil;
  
  NSString *linkName = [[self linkOrderingForObject:lo] objectAtIndex:row];
  id <MWLinkable>linkTarget = [[[lo links] objectForKey:linkName] otherObject:lo];
  BOOL notUseful = !linkTarget || loPrev == linkTarget;
  
  NSColor *color = notUseful ? [NSColor disabledControlTextColor] : [NSColor controlTextColor];
  
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont labelFontOfSize:[NSFont labelFontSize]], NSFontAttributeName,
    color, NSForegroundColorAttributeName,
    nil
  ];
  
  [cell setLeaf:notUseful];
  [cell setWraps:NO];
  [cell setAttributedStringValue:[[[NSAttributedString alloc] initWithString:(
    linkTarget
    ? [NSString stringWithFormat:@"%@: %@", linkName, [linkTarget linkableUserDescription]]
    : linkName
  ) attributes:attrs] autorelease]];
}

- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column {
  return [[self objectForColumnPath:[sender pathToColumn:column]] linkableUserDescription];
}

- (IBAction)mwBrowserAction:(id)sender {} // stub for IB

- (IBAction)browserSingleClick:(id)sender {
}

- (IBAction)browserDoubleClick:(id)sender {
  id <MWLinkable>lo = [self objectForColumnPath:[sender path]];
  if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
    [self setLOC:[MWLinkableObjectController locWithLinkable:lo]];
  else
    [[MWLinkableObjectController locWithLinkable:lo] openViewBesideWindow:[self window]];
}

// --- Accessors ---

- (MWLinkableObjectController *)LOC { return LOC; }
- (void)setLOC:(MWLinkableObjectController *)newLOC {
  [[linkablesToInspectors objectForKey:MWKeyFromObjectIdentity([LOC target])] removeObject:self];

  [LOC autorelease];
  LOC = [newLOC retain];
  [self updateAllControls];
  [self updateTiedControls];
  
  if (![linkablesToInspectors objectForKey:MWKeyFromObjectIdentity([LOC target])]) {
    [linkablesToInspectors setObject:[NSMutableSet set] forKey:MWKeyFromObjectIdentity([LOC target])];
  }
  [[linkablesToInspectors objectForKey:MWKeyFromObjectIdentity([LOC target])] addObject:self];
}

@end
