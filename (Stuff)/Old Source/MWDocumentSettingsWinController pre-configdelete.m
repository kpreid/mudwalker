/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWDocumentSettingsWinController.h"

#import <MudWalker/MWConstants.h>
#import <MudWalker/MWUtilities.h>
#import <MWAppKit/MWAppKit.h>

#import "MWConnectionDocument.h"
#import "MWDocumentSettings.h"
#import "MWAppDelegate.h"

#import <PreferencePanes/PreferencePanes.h>

#define LINE_ENDING_POP_CR 0
#define LINE_ENDING_POP_LF 1
#define LINE_ENDING_POP_CRLF 2
#define LINE_ENDING_POP_LFCR 3

#define COLOR_WELL_TAG_BASE 100

#define CT_obj 1
#define CT_check 2
#define CT_popupTag 3
#define CT_plainTextView 4
#define CT_attrTextView 5
#define CT_integer 6
#define CT_spColorItem 101
#define CT_spColorSet 102
#define CT_spLineEnding 103

@interface MWDocumentSettingsWinController (Private)

  - (void)registerControl:(NSView *)control key:(NSString *)key type:(int)type;
  - (void)fillEncodingsMenu;
  - (void)preparePanes;
  
  // Updating controls
  - (void)updateWindow;
  
  - (void)updateControlsForSettingNotification:(NSNotification *)notif;
  - (void)updateControlsForSetting:(NSString *)key;
  - (void) registerNotificationObservers;
  
  - (MWConfigTree *)config;
  - (MWDocumentSettings *)settings;
  
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
  [dURLFormatter release]; dURLFormatter = nil;
  [dSplitDelegate release]; dSplitDelegate = nil;
  
  [panes release]; panes = nil;
  [currentPane release]; currentPane = nil;
  
  [super dealloc];
}

- (void)windowDidLoad {
  keyToCTypeDict   = [[NSMutableDictionary allocWithZone:[self zone]] init];
  keyToControlDict = [[NSMutableDictionary allocWithZone:[self zone]] init];
  controlToKeyDict = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  [self registerControl:cAddress	key:@"Address"		type:CT_obj];
  [self registerControl:cAutoConnect	key:@"AutoConnect"	type:CT_check];
  [self registerControl:cLineEnding	key:@"LineEnding"	type:CT_spLineEnding];
  [self registerControl:cCharEncoding	key:@"CharEncoding"	type:CT_popupTag];
  [self registerControl:cScrollbackLength key:@"ScrollbackCharacters" type:CT_obj];
  [self registerControl:cPromptTimeout  key:MWConfigureTelnetPromptTimeout type:CT_obj];
  [self registerControl:cLoginScript	key:MWConfigureLoginScript type:CT_attrTextView];
  [self registerControl:cLogoutScript	key:MWConfigureLogoutScript type:CT_attrTextView];
  [self registerControl:cColorsContainer key:@"Colors"		type:CT_spColorItem];
  [self registerControl:cColorBrightColor key:@"ColorBrightColor" type:CT_check];
  [self registerControl:cColorBrightBold key:@"ColorBrightBold" type:CT_check];
  [self registerControl:cLineIndent key:@"TextWrapIndent" type:CT_integer];

  [self fillEncodingsMenu];
  {
    int tag;
    for (tag = 0; tag <= MWCOLOR_MAXINDEX; tag++) {
      [[cColorsContainer viewWithTag:COLOR_WELL_TAG_BASE + tag] setContinuous:YES];
    }
  }

  [self registerNotificationObservers];
  [self updateWindow];
  [self preparePanes];

  [super windowDidLoad];
}

- (void)registerControl:(NSView *)control key:(NSString *)key type:(int)type {
  if (!control) {
    NSLog(@"control outlet for key %@ not connected\n", key);
    return;
  }
  [keyToControlDict setObject:control forKey:key];
  [keyToCTypeDict setObject:[NSNumber numberWithInt:type] forKey:key];
  [controlToKeyDict setObject:key forKey:MWKeyFromObjectIdentity(control)];
}

static int encodingSort(id a, id b, void *context) {
  return [
    [NSString localizedNameOfStringEncoding:[a unsignedIntValue]]
    compare:
    [NSString localizedNameOfStringEncoding:[b unsignedIntValue]]
  ];
}

- (void)fillEncodingsMenu {
  NSMutableArray *sortedEncodings = [NSMutableArray array];
  const NSStringEncoding *encoding;
  
  for (encoding = [NSString availableStringEncodings]; *encoding != 0; encoding++) {
    [sortedEncodings addObject:[NSNumber numberWithUnsignedInt:*encoding]];
  }
  [sortedEncodings sortUsingFunction:encodingSort context:NULL];
  
  {
    NSEnumerator *e = [sortedEncodings objectEnumerator];
    NSNumber *encNum;
    while ((encNum = [e nextObject])) {
      NSStringEncoding enc = [encNum unsignedIntValue];
       
      if ([cCharEncoding indexOfItemWithTag:enc] == -1) {
        [cCharEncoding addItemWithTitle:[NSString localizedNameOfStringEncoding:enc]];
        [[cCharEncoding lastItem] setTag:enc];
      }
    }
  }
  
  [cCharEncoding setAutoenablesItems:NO];
}

// --- Prefpanes ---

- (void)preparePanes {
  NSEnumerator *classE = [[[MWRegistry defaultRegistry] preferencePanesForScope:MWConfigScopeDocument] objectEnumerator];
  Class class;
  NSMutableArray *failedPanes = [NSMutableArray array];
  
  while ((class = [classE nextObject])) {
    NSPreferencePane *pane = [
      [class alloc]
      initWithBundle:[NSBundle bundleForClass:class] 
      mwConfigTarget:[(MWConnectionDocument *)[self document] configLocalStore]
      configParent:[(MWAppDelegate *)[NSApp delegate] globalConfig]
    ];
    
    if (![pane loadMainView]) {
      [failedPanes addObject:pane];
    } else {
      [panes addObject:pane];
    }
  }
  if ([failedPanes count]) {
    // FIXME: nicer list of panes that failed
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

- (int)numberOfRowsInPaneTableView {
  return [panes count];
}

- (id)paneTableViewObjectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  return [[panes objectAtIndex:rowIndex] displayName];
}

- (void)paneTableViewSelectionDidChange:(NSNotification *)notif {
  [self paneChosen:nil];
}

// --- First responder quirks ----------------------------------------------------

// Explanation: If the window is closed, or loses key, we want to save the changes to the preferences and also enforce formatter restrictions. Solution originally from Jim DiPalma <jdipalma@mac.com> on MacOSX-dev list @ omnigroup.com.

- (BOOL)windowShouldClose:(NSNotification*)notif {
  return [[self window] makeFirstResponder:nil] && [self paneSwitch:nil];
}

- (void)windowDidResignKey:(NSNotification *)notif {
  NSResponder *fr = [[self window] firstResponder];
  if ([fr respondsToSelector:@selector(validateEditing)])
    [(id)fr validateEditing];
  else if ([fr isKindOfClass:[NSText class]])
    [[(NSText *)fr delegate] textDidEndEditing:[NSNotification notificationWithName:NSTextDidEndEditingNotification object:fr]]; // fake it
}

// And we need to do the same for tab views.

- (BOOL)tabView:(NSTabView *)view shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
  // don't touch anything if the tab view is the first responder itself because that messes up keyboard navigation
  return (NSResponder *)view == [[self window] firstResponder] ? YES : [[self window] makeFirstResponder:nil];
}

// --- Misc window controller stuff ---

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)str {
  return [NSString stringWithFormat:NSLocalizedString(@"%@ Document Settings", nil), str];
}

// --- View updating ---

- (void)updateWindow {
  NSEnumerator *enumerator = [keyToControlDict keyEnumerator];
  id key;
  while ((key = [enumerator nextObject])) [self updateControlsForSetting:key];
}

- (void)updateControlsForSettingNotification:(NSNotification *)notif {
  [self updateControlsForSetting: [[notif userInfo] objectForKey:@"key"]];
}

- (void)updateControlsForSetting:(NSString *)key {
  NSView *control = [keyToControlDict objectForKey:key];
  int type = [[keyToCTypeDict objectForKey:key] intValue];
  id value = [[self settings] objectForKey:key];
  if (!control) {
    NSLog(@"Warning: No user controls for setting %@!\n", key);
    return;
  }
  
  switch (type) {
    case CT_check:
      [(NSButton *)control setState:[value boolValue]];
      break;
    case CT_plainTextView: {
      [(NSTextView *)control setString:value];
      break;
    }
    case CT_attrTextView: {
      [[(NSTextView *)control textStorage] setAttributedString:value];
      break;
    }
    case CT_spColorItem: {
      unsigned int tag;
      for (tag = 0; tag <= MWCOLOR_MAXINDEX; tag++) {
        NSColorWell *well = [cColorsContainer viewWithTag:COLOR_WELL_TAG_BASE + tag];
        if (well) [well setColor:[value objectAtIndex:tag]];
      }
      break;
    }
    case CT_spLineEnding: {
      int tag;
      if      ([value isEqualToString:@"\r"]) tag = LINE_ENDING_POP_CR;
      else if ([value isEqualToString:@"\n"]) tag = LINE_ENDING_POP_LF;
      else if ([value isEqualToString:@"\r\n"]) tag = LINE_ENDING_POP_CRLF;
      else if ([value isEqualToString:@"\n\r"]) tag = LINE_ENDING_POP_LFCR;
      else tag = -1;
      value = [NSNumber numberWithInt:tag];
      /* FALL THROUGH */
    }
    case CT_popupTag:
      [(NSPopUpButton *)control selectItemAtIndex:[(NSPopUpButton *)control indexOfItemWithTag:[value unsignedIntValue]]];
      break;
    default:
      [(NSControl *)control setObjectValue:value];
      break;
  }
}

- (void)registerNotificationObservers {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(updateControlsForSettingNotification:) name:MWConfigNodeChangedNotification object:[self settings]];
  //[center addObserver:self selector:@selector(configDidChange:) name:MWConfigSupplierChangedNotification object:[self config]];
}

// --- Actions, view entry -----------------------------------------------

- (void)textDidEndEditing:(NSNotification *)notif {
  [self settingControlChanged:[notif object]];
}

- (IBAction)settingControlChanged:(id)sender {
  id newValue;
  NSString *key = [controlToKeyDict objectForKey:MWKeyFromObjectIdentity(sender)];
  int type = [[keyToCTypeDict objectForKey:key] intValue];
  id<NSObject> oldValue = [[self settings] objectForKey:key];
  NSString *changeDescKey;

  if (![self document] || !key) return;

  NSAssert([self settings], @"Oops, no document settings!");
    
  switch (type) {
    case CT_obj: newValue = [sender objectValue]; break;
    case CT_check: newValue = [NSNumber numberWithInt: [sender state] == NSOnState]; break;
    case CT_popupTag: newValue = [NSNumber numberWithInt: [[sender selectedItem] tag]]; break;
    case CT_plainTextView: newValue = [sender string]; break;
    case CT_attrTextView: newValue = [[sender textStorage] copy]; break;
    case CT_integer: newValue = [NSNumber numberWithInt:[sender intValue]]; break;
    case CT_spColorItem: {
      unsigned int tag;
      newValue = [NSMutableArray arrayWithCapacity:MWCOLOR_MAXINDEX + 1];
      for (tag = 0; tag <= MWCOLOR_MAXINDEX; tag++) {
        NSColorWell *well = [cColorsContainer viewWithTag:COLOR_WELL_TAG_BASE + tag];
        [newValue addObject:well ? [well color] : [NSColor grayColor]];
      }
      break; }
    case CT_spLineEnding: {
      switch ([[sender selectedItem] tag]) {
        case LINE_ENDING_POP_CR: newValue = @"\r"; break;
        case LINE_ENDING_POP_LF: newValue = @"\n"; break;
        case LINE_ENDING_POP_CRLF: newValue = @"\r\n"; break;
        case LINE_ENDING_POP_LFCR: newValue = @"\n\r"; break;
        default: newValue = @"\n"; break;
      }
      break; }
    default: NSLog(@"Can't read this control change type: %i!\n", type); newValue = nil;
  }
# if 0
  if (type == CT_spColorItem) {
    printf("control change: %s (type %i)\n", [key cString], type);
  } else {
    printf("control change: %s to %s, formerly %s (type %i)\n", [key cString], [[newValue description] cString], [[oldValue description] cString], type);
  }
# endif
  
  // if the value didn't actually change, we should return before exiting this switch and not call setObject:forKey:, so that no undo entry is made
  switch (type) {
    default:
      if ([(NSObject*)newValue isEqual:oldValue]) return;
      [[self settings] setObject:newValue forKey:key];
      break;
  }

  switch (type) {
    case CT_check:
      changeDescKey = [newValue boolValue] ? @"ChangeBoolSet%@" : @"ChangeBoolClear%@";
      break;
    default:
      changeDescKey = @"ChangeObject%@";
      break;
  }
  [[[self document] undoManager] setActionName:[NSString stringWithFormat:NSLocalizedString(changeDescKey,0), NSLocalizedString(key,0)]];
} 

- (IBAction)settingColorWellChanged:(id)sender {
  [self settingControlChanged:cColorsContainer];
}

// --- Generic table view delegate ---

- (int)numberOfRowsInTableView:(NSTableView *)sender {
  if (sender == paneList)
    return [self numberOfRowsInPaneTableView];
  else
    return 0;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  if (sender == paneList)
    return [self paneTableViewObjectValueForTableColumn:column row:rowIndex];
  else
    return nil;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  if (sender == paneList)
    /*[self paneTableViewSetObjectValue:newVal forTableColumn:column row:rowIndex]*/;
  else
    ;
}

- (BOOL)tableView:(NSTableView *)sender writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  if (sender == paneList)
    return /*[self paneTableViewWriteRows:rows toPasteboard:pboard]*/ NO;
  else
    return NO;
}

- (IBAction)tableViewSelectionDidChange:(NSNotification *)notif {
  if ([notif object] == paneList)
    [self paneTableViewSelectionDidChange:notif];
  else
    ;
}

// --- Accessors -----------------------------------------------

- (MWDocumentSettings *)settings {return [(MWConnectionDocument *)[self document] settings];}
- (MWConfigTree *)config {return [(MWConnectionDocument *)[self document] configLocalStore];}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return [[self document] undoManager];
}

@end
