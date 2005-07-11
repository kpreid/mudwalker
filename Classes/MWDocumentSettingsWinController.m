/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWDocumentSettingsWinController.h"

#import <MudWalker/MWConstants.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWUtilities.h>
#import <MWAppKit/MWAppKit.h>

#import "MWConnectionDocument.h"
#import "MWAppDelegate.h"

#import <PreferencePanes/PreferencePanes.h>

@interface MWDocumentSettingsWinController (Private)

  - (void)preparePanes;
  
@end

@implementation MWDocumentSettingsWinController

- (id)init {
  if (!(self = [super initWithWindowNibName:@"DocumentSettings"])) return self;
  [self setWindowFrameAutosaveName:@"DocumentSettings"];
  
  panes = [[NSMutableArray allocWithZone:[self zone]] init];
    
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [panes autorelease]; panes = nil;
  [currentPane autorelease]; currentPane = nil;
  
  [super dealloc];
}

- (void)windowDidLoad {
  [self preparePanes];

  [super windowDidLoad];
}

// --- Prefpanes ---

- (void)preparePanes {
  MWConnectionDocument *const doc = (MWConnectionDocument *)[self document];
  MWConfigTree *const target = doc
    ? [doc configLocalStore]
    : [[MWRegistry defaultRegistry] userConfig];
  id <MWConfigSupplier> const parent = doc
    ? [[MWRegistry defaultRegistry] config]
    : [[MWRegistry defaultRegistry] defaultConfig];

  NSMutableArray *failedPanes = [NSMutableArray array];  
  
  NSEnumerator *classE = [[[MWRegistry defaultRegistry] preferencePanesForScope:doc ? MWConfigScopeDocument : MWConfigScopeUser] objectEnumerator];
  Class class;
  while ((class = [classE nextObject])) {
    NSPreferencePane *pane = [
      [class alloc]
      initWithBundle:[NSBundle bundleForClass:class] 
      mwConfigTarget:target
      configParent:parent
    ];
    
    if (![pane loadMainView]) {
      [failedPanes addObject:pane];
    } else {
      [panes addObject:pane];
    }
  }
  if ([failedPanes count]) {
    // fixme: nicer list of panes that failed
#if 1
    NSRunCriticalAlertPanel(
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Title",nil),
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Message%@",nil), 
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Dismiss",nil),
      nil, nil,
      failedPanes
    );
#else
    NSBeginCriticalAlertSheet(
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Title",nil),
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Dismiss",nil),
      nil, nil, [self window], nil, NULL, NULL, NULL, 
      NSLocalizedString(@"MWConfigPaneViewLoadFail_Message%@",nil), failedPanes
    );
#endif
  }
}

- (BOOL)paneSwitch:(NSPreferencePane *)pane {
  NSView *mainView;
  
  // assumes the pane's main view has already been loaded
  if (currentPane) {
    if (currentPane == pane) return YES;
    
    switch ([currentPane shouldUnselect]) {
      case NSUnselectCancel:
        [paneList selectRow:[panes indexOfObject:currentPane] byExtendingSelection:NO];
        return NO;
      case NSUnselectLater:
        return NO;
      case NSUnselectNow:
        break;
      default:
        [NSException raise:NSInternalInconsistencyException format:@"Preference pane %@ gave bad reply to shouldUnselect", currentPane];
    }
  
    // FIXME: catch notifications from NSUnselectLater
    
    [paneList setNextKeyView:nil];
    
    [currentPane willUnselect];
    [[currentPane mainView] removeFromSuperview];
    [currentPane didUnselect];
    [currentPane autorelease];
    currentPane = nil;
  }
  
  if (pane) {
    currentPane = [pane retain];
    
    [pane willSelect];
    mainView = [pane mainView];
    [mainView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
   
    {
      NSSize paneSize = [mainView frame].size;
      NSRect windowFrame = [[self window] frame];
      NSSize windowSize = windowFrame.size;
      NSRect containerInWinCoords = [paneContainer convertRect:[paneContainer bounds] toView:nil];
      NSSize chromeSize = {
        windowSize.width - containerInWinCoords.size.width,
        windowSize.height - containerInWinCoords.size.height,
      };
      NSSize newWindowSize = {
        chromeSize.width + paneSize.width,
        chromeSize.height + paneSize.height,
      };
      NSSize sizeDifference = {
        newWindowSize.width - windowSize.width,
        newWindowSize.height - windowSize.height,
      };
      NSRect newWindowFrame = {
        {
          windowFrame.origin.x,
          windowFrame.origin.y - sizeDifference.height,
        },
        newWindowSize,
      };
      [[self window] setFrame:newWindowFrame display:YES animate:YES];
    }
      
    [paneContainer addSubview:mainView];

    [paneList setNextKeyView:[pane firstKeyView]];
    [[pane lastKeyView] setNextKeyView:paneList];
    // this is bad for pane selection by arrow keys
    //[[self window] makeFirstResponder:[pane initialKeyView]];
    [pane didSelect];
  }
  return YES;
}
  
- (IBAction)paneChosen:(id)sender {
  NSEnumerator *e = [paneList selectedRowEnumerator];
  unsigned selectedRows = 0;
  while ([e nextObject]) selectedRows++;
  
  if (selectedRows == 1)
    [self paneSwitch:[panes objectAtIndex:[paneList selectedRow]]];
  else
    [self paneSwitch:nil];
}

- (int)numberOfRowsInTableView:(NSTableView *)sender {
  return [panes count];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  return [[panes objectAtIndex:rowIndex] displayName];
}

- (IBAction)tableViewSelectionDidChange:(NSNotification *)notif {
  [self paneChosen:nil];
}

// --- Misc window controller stuff ---

- (BOOL)windowShouldClose:(NSNotification*)notif {
  return [[self window] makeFirstResponder:nil] && [self paneSwitch:nil];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)str {
  return [NSString stringWithFormat:NSLocalizedString(@"%@ Document Settings", nil), str];
}

- (void)showWindow:(id)sender {
  [self paneChosen:nil];
  [[self window] makeFirstResponder:[[self window] initialFirstResponder]];
  [super showWindow:sender];
}

// --- Accessors -----------------------------------------------

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return nil; // ... uncertain what we should return, since document model handles all the actual undo tracking
  return [[self document] undoManager];
}

@end
