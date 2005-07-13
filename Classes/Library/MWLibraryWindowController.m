/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLibraryWindowController.h"

#import "MWMudLibrary.h"
#import "MWLibraryItem.h"
#import "MWAppDelegate.h"
#import "MWConnectionDocument.h"
#import <MWAppKit/MWImageAndTextCell.h>

@implementation MWLibraryWindowController

// --- initialization ---

- (id)init {
  if (!(self = [self initWithWindowNibName:@"LibraryWindow"])) return nil;
  
  [self setWindowFrameAutosaveName:@"LibraryWindow"];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDidChange:) name:MWLibraryDidChangeNotification object:nil]; 
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWLibraryDidChangeNotification object:nil]; 
  [super dealloc];
}

- (void)windowDidLoad {
  [libOutline setDataSource:[self dataSource]];
  [libOutline setTarget:self];
  [libOutline setAction:@selector(doClickWaitMode:)];
  [libOutline setDoubleAction:@selector(mwOpenConnection:)];
  [libOutline setVerticalMotionCanBeginDrag:NO];

  [libOutline setAutosaveName:@"Library Data Outline"];
  [libOutline setAutosaveTableColumns:YES];
  //[libOutline setAutosaveExpandedItems:YES];
  
  {
    NSTableColumn *col = [[libOutline tableColumns] objectAtIndex:[libOutline columnWithIdentifier:@"name"]];
    NSCell *oldCell = [col dataCell];
    MWImageAndTextCell *newCell = [[[MWImageAndTextCell alloc] initTextCell:@""] autorelease];
    
    [newCell setFont:[oldCell font]];
    [newCell setEditable:[oldCell isEditable]];
    [col setDataCell:newCell];
  }

  [libOutline reloadData];
  
  [[self window] makeFirstResponder:[[self window] initialFirstResponder]];
  
  [super windowDidLoad];
}

- (void)libraryDidChange:(NSNotification *)notif {
  [libOutline reloadData];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
  NSRect farthestRect = [libOutline rectOfRow:[libOutline numberOfRows] - 1];
  NSSize tableContentBestSize = NSMakeSize(
    farthestRect.origin.x + farthestRect.size.width,
    farthestRect.origin.y + farthestRect.size.height + [[libOutline headerView] frame].size.height
  );
  NSSize tableFrameBestSize = [NSScrollView frameSizeForContentSize:tableContentBestSize hasHorizontalScroller:[libScroller hasHorizontalScroller] hasVerticalScroller:[libScroller hasVerticalScroller] borderType:[libScroller borderType]];
  NSSize tableFrameSize = [libScroller frame].size;
  NSSize winContentSize = [NSWindow contentRectForFrameRect:[sender frame] styleMask:[sender styleMask]].size;
  
  NSRect r = {
    [sender frame].origin, 
    NSMakeSize(
      tableFrameBestSize.width + (winContentSize.width - tableFrameSize.width),
      tableFrameBestSize.height + (winContentSize.height - tableFrameSize.height)
    ),
  };
  
  return [NSWindow frameRectForContentRect:r styleMask:[sender styleMask]];
}

- (void)doClickWaitMode:(id)sender {
  //NSEvent *clickEvent = [NSApp currentEvent];
  //NSLog(@"waiting");
  //{
  NSEvent *abortEvent = [NSApp nextEventMatchingMask:NSAnyEventMask & ~(NSFlagsChangedMask | NSPeriodicMask | NSCursorUpdateMask | NSSystemDefinedMask)  untilDate:[NSDate dateWithTimeIntervalSinceNow:0.7] inMode:NSEventTrackingRunLoopMode dequeue:NO];
  
  //NSLog(@"got %@ (click event %@)", abortEvent, clickEvent);
  if (!abortEvent && [libOutline numberOfSelectedRows] == 1) {
    if ([[self dataSource] isEditableItem:[libOutline itemAtRow:[libOutline clickedRow]] atKey:[[[libOutline tableColumns] objectAtIndex:[libOutline clickedColumn]] identifier]]) {
      [libOutline editColumn:[libOutline clickedColumn] row:[libOutline clickedRow] withEvent:nil select:YES];
    }
    //NSLog(@"edit");
  } else {
    //NSLog(@"abort %@", abortEvent);
  }
  //}
}

- (void)mwOpenConnection:(id)sender {
  NSEnumerator *e = [libOutline selectedRowEnumerator];
  NSNumber *index;
  unsigned int windowCount = [[NSApp windows] count];
  
  while ((index = [e nextObject])) {
    [[libOutline itemAtRow:[index intValue]] performOpenAction:nil];
  }
  
  // FIXME: this no longer works due to MWConnectionDocument's trickery
  if ([[NSApp windows] count] > windowCount)
    [[self window] performClose:nil];
}

- (IBAction)mwOpenServerInfo:(id)sender {
  NSEnumerator *e = [libOutline selectedRowEnumerator];
  NSNumber *index;
  while ((index = [e nextObject])) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[libOutline itemAtRow:[index intValue]] objectForKey:@"web"]]];
  }
}

- (IBAction)mwForgetLibraryItem:(id)sender {
  NSMutableArray *items = [NSMutableArray array];
  NSEnumerator *e = [libOutline selectedRowEnumerator];
  NSNumber *index;
  
  while ((index = [e nextObject])) {
    [items addObject:[libOutline itemAtRow:[index intValue]]];
  }
  [items makeObjectsPerformSelector:@selector(removeFromLibrary)];
  [libOutline deselectAll:nil];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(mwOpenConnection:)) {
    NSEnumerator *e = [libOutline selectedRowEnumerator];
    NSNumber *index;
    
    while ((index = [e nextObject])) {
      if ([[libOutline itemAtRow:[index intValue]] canPerformOpenAction]) return YES;
    }
    return NO;
  } else if (action == @selector(mwOpenServerInfo:)) {
    NSEnumerator *e = [libOutline selectedRowEnumerator];
    NSNumber *index;
    
    while ((index = [e nextObject])) {
      NSString *ustr = [[libOutline itemAtRow:[index intValue]] objectForKey:@"web"];
      if (ustr && [[NSURL URLWithString:ustr] scheme]) return YES;
    }
    return NO;

  } else if (action == @selector(mwForgetLibraryItem:)) {
    return YES;

  } else {
    return NO;
  }
}

// --- Outline view delegate ---

- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)col item:(id)item {    
  if ([cell isKindOfClass:[MWImageAndTextCell class]]) {
    MWImageAndTextCell *itcell = (MWImageAndTextCell *)cell;
    [itcell setImage:[item libItemImage]]; 
  }
}

- (BOOL)outlineView:(NSOutlineView *)sender shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  return NO;
 }

- (BOOL)outlineView:(NSOutlineView *)sender shouldSelectItem:(id)item {
  //return ![item isKindOfClass:[MWLibraryCategory class]];
  return YES;
}

// --- Accessors ---

- (MWMudLibrary *)dataSource {return [(MWAppDelegate *)[NSApp delegate] mudLibrary]; }

@end
