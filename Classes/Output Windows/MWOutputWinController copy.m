/*\  
 * MudWalker Source
 * Copyright 2001-2003 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWOutputWinController.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWToolbars.h>

#import "MWAppDelegate.h"
#import "MWConnectionDocument.h"
#import "MWLinkableObjectController.h"
#import "MWBorderlessWindow.h"

#import "MWTriggerFilter.h"

#define AUTOHIDE_SIZE 2

@interface MWOutputWinController (Private)

- (void)updateCharacterMenu;
- (void)updateCharacterSelection;
- (id)selectedCharacter;
- (void)setSelectedCharacter:(id)newVal;
- (void)doneLinkedAlertSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)connectionClosedCallback:(BOOL)didDisconnect;
- (void)releaseWindowFrameAutosaveName;

@end

@implementation MWOutputWinController

// --- Initialization ------------------------------------------------------
- (id)init {
  if (!(self = [super initWithWindowNibName:[self outputWindowNibName]])) return nil;
  
  links = [[NSMutableDictionary allocWithZone:[self zone]] init];
  configLocal = [[MWConfigTree allocWithZone:[self zone]] init];
  configStack = [configLocal retain];

  [NSBundle loadNibNamed:@"OutputWindowFeatures" owner:self];
  
  toolbarItems = [[NSMutableDictionary allocWithZone:[self zone]] init];
  MWTOOLBAR_ITEM(@"mwOpenConnection",       self, @selector(mwOpenConnection:));
  MWTOOLBAR_ITEM(@"mwCloseConnectionHard",  self, @selector(mwCloseConnectionHard:));
  MWTOOLBAR_ITEM(@"mwCloseConnectionNice",  self, @selector(mwCloseConnectionNice:));
  MWTOOLBAR_ITEM(@"mwUnlinkWindow",         self, @selector(mwUnlinkWindow:));
  MWTOOLBAR_ITEM(@"mwSendPing",             self, @selector(mwSendPing:));
  MWTOOLBAR_ITEM(@"mwOpenDocumentSettings", self, @selector(mwOpenDocumentSettings:));
  MWTOOLBAR_ITEM(@"mwSelectCharacter",      self, @selector(mwSelectCharacter:));

  {
    NSMenuItem *mfr;
    NSToolbarItem *item = [toolbarItems objectForKey:@"mwSelectCharacter"];
    [item setView:tbCharacterView];
    [item setMinSize:NSMakeSize(70, [tbCharacterView frame].size.height)];
    [item setMaxSize:NSMakeSize(180, [tbCharacterView frame].size.height)];
    
    mfr = [[[NSMenuItem alloc] init] autorelease];
    [mfr setSubmenu:tbCharacterMenu];
    [item setMenuFormRepresentation:mfr];
  }

  [self setConfig:[[MWRegistry defaultRegistry] config]];
  
  return self;
}

- (void)dealloc {
  // Problem: If this WC is dealloced in an autorelease fashion, the toolbar items dict gets released before the window is released, leading to a crash. So we force the window to close now.
  
  [[self window] close];
  [self releaseWindowFrameAutosaveName];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self unlinkAll];
  
  
  [configParent autorelease]; configParent = nil;
  [configLocal autorelease]; configLocal = nil;
  [configStack autorelease]; configStack = nil;
  [tbCharacterView autorelease]; tbCharacterView = nil;
  [tbCharacterMenu autorelease]; tbCharacterMenu = nil;
  [links autorelease]; links = nil;
  [extInputManager setTarget:nil];
  [extInputManager autorelease]; extInputManager = nil;
  [toolbarItems autorelease]; toolbarItems = nil;
  [originalWindow autorelease]; originalWindow = nil;
  [originalFrameName autorelease]; originalFrameName = nil;
  [super dealloc];
}

- (NSString *)outputWindowNibName {
  [[NSException exceptionWithName:NSGenericException reason:@"-[MWOutputWinController outputWindowNibName] was not overriden!" userInfo:nil] raise];
  return nil; // will never reach here
}

- (void)windowDidLoad {
  NSToolbar *toolbar;
  [super windowDidLoad];
  toolbar = [[[NSToolbar alloc] initWithIdentifier:[[self class] description]] autorelease];
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:YES];
  [toolbar setAutosavesConfiguration:YES];
  [[self window] setToolbar:toolbar];
}

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];

  if (!path || [path hasPrefix:[MWConfigPath pathWithComponent:@"Accounts"]])
    [self updateCharacterMenu];

  if (!path || [path isEqual:[MWConfigPath pathWithComponent:@"SelectedAccount"]])
    [self updateCharacterSelection];
    
  if (!path) {
    NSArray *keys = [[self config] allKeysAtPath:[MWConfigPath pathWithComponent:@"Accounts"]];
    if ([keys count])
      [self setSelectedCharacter:[keys objectAtIndex:0]];
  }
}

// --- Toolbar delegate ---

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  // Note that if we wanted to allow duplicate items, the items must be copied before returning. Otherwise, it's better not to.
  return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:
    @"mwOpenConnection",
    NSToolbarSeparatorItemIdentifier,
    @"mwCloseConnectionNice", @"mwCloseConnectionHard",
    NSToolbarSeparatorItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier,
    @"mwSelectCharacter",
    @"mwOpenDocumentSettings",
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

// --- Character popup menu ---

- (void)updateCharacterSelection {
  MWConfigTree *const config = [[self document] config];
  NSString *const selectedCharacterKey = [self selectedCharacter];
  NSString *selectedCharacterName = selectedCharacterKey ? [config objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", selectedCharacterKey, @"name", nil]] : nil;
  NSToolbarItem *const charTBI = [toolbarItems objectForKey:@"mwSelectCharacter"];
  unsigned const index = selectedCharacterKey ? [[config allKeysAtPath:[MWConfigPath pathWithComponent:@"Accounts"]] indexOfObject:selectedCharacterKey] : ([config countAtPath:[MWConfigPath pathWithComponent:@"Accounts"]] + 1);

  [tbCharacterPopUp selectItemAtIndex:index];
  if (!selectedCharacterName)
    selectedCharacterName = NSLocalizedString(@"_MWOutputWinCharSelect_None",nil);

  NSString *const title = [NSString stringWithFormat:NSLocalizedString(@"CharacterMenu%@",nil), selectedCharacterName];
  [[charTBI menuFormRepresentation] setTitle:title];
  [charTBI setMenuFormRepresentation:[charTBI menuFormRepresentation]];
  
  [self updateWindowTitle];
}

- (void)updateCharacterMenu {
  MWConfigTree *config = [self config];
  NSMutableArray *menuItems = [[[config allKeysAtPath:[MWConfigPath pathWithComponent:@"Accounts"]] mutableCopy] autorelease];
 
  if (!menuItems) menuItems = [NSMutableArray array];
 
  while ([tbCharacterMenu numberOfItems]) {
    [tbCharacterMenu removeItemAtIndex:0];
  }
  [tbCharacterPopUp removeAllItems];
  
  [menuItems addObject:@"-"];
  [menuItems addObject:@"_MWOutputWinCharSelect_None"];
  
  {
    NSMutableDictionary *seen = [NSMutableDictionary dictionary];
    NSEnumerator *e = [menuItems objectEnumerator];
    id key; int i = 0;
    while ((key = [e nextObject])) {
      NSString *charName = [config objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", key, @"name", nil]];
      NSString *displayName = charName ? charName : NSLocalizedString(key, nil);
      if (charName) {
        NSNumber *more;
        if ((more = [seen objectForKey:charName])) {
          more = [NSNumber numberWithInt:[more intValue] + 1];
          displayName = [NSString stringWithFormat:@"%@ (%@)", charName, more];
        } else {
          more = [NSNumber numberWithInt:1];
        }
        [seen setObject:more forKey:charName];
      }
      if ([key isEqual:@"-"]) {
        [tbCharacterMenu addItem:[NSMenuItem separatorItem]];
        [[tbCharacterPopUp menu] addItem:[NSMenuItem separatorItem]];
      } else {
        [[tbCharacterMenu addItemWithTitle:displayName action:@selector(mwSelectCharacter:) keyEquivalent:@""] setTag:i];
        [tbCharacterPopUp addItemWithTitle:displayName];
      }
      i++;
    }
  }
  [self updateCharacterSelection];
}

- (IBAction)mwSelectCharacter:(id)sender {
  MWConfigTree *config = [self config];
  int index;
  if (sender == tbCharacterPopUp) {
    index = [sender indexOfSelectedItem];
  } else if (1) {
    index = [sender tag];
  } else {
    NSLog(@"-mwSelectCharacter: couldn't determine relevant index for sender %@", sender);
    index = 0;
  }

  if (index < [config countAtPath:[MWConfigPath pathWithComponent:@"Accounts"]]) {
    [self setSelectedCharacter:[config keyAtIndex:index inDirectoryAtPath:[MWConfigPath pathWithComponent:@"Accounts"]]];
  } else {
    [self setSelectedCharacter:nil];
  }
}

/* guaranteed to return an existant key or nil */
- (id)selectedCharacter {
  NSString *const sel = [configLocal objectAtPath:[MWConfigPath pathWithComponent:@"SelectedAccount"]];
  
  if ([[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", sel, nil]])
    return sel;
  else
    return nil;
}
- (void)setSelectedCharacter:(NSString *)newVal {
  if (newVal)
    [configLocal setObject:newVal atPath:[MWConfigPath pathWithComponent:@"SelectedAccount"]];
  else
    [configLocal removeItemAtPath:[MWConfigPath pathWithComponent:@"SelectedAccount"] recurse:NO];
  [self updateCharacterSelection];
}


// --- Links ---------------------------------------------

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", nil]; }

- (NSDictionary *)links { return links; }

- (void)registerLink:(MWLink *)link forName:(NSString *)linkName {
  [links setObject:link forKey:linkName];
  if ([self isWindowLoaded]) [self updateWindowTitle];
}

- (NSString *)linkFailureReason { return nil; }
  
- (void)unregisterLinkFor:(NSString *)linkName {
  [links removeObjectForKey:linkName];
  if ([linkName isEqualToString:@"outward"]) {
    [[[self window] toolbar] validateVisibleItems]; // force connect/disconnect state to update
    [self updateWindowTitle];
    [self connectionClosedCallback:YES];
  }
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenConnectionClosed]) {
        [self connectionClosedCallback:YES];
        [self setInputPrompt:nil];
        [[[self window] toolbar] validateVisibleItems];
        return YES;
      } else if ([obj isEqual:MWTokenConnectionOpened]) {
        [[[self window] toolbar] validateVisibleItems];
        return YES;
      } else {
        return NO;
      }
    } else if ([obj isKindOfClass:[NSSound class]]) {
      if (!([(MWAppDelegate *)[NSApp delegate] disabledSound])) [obj play];
      return YES;

    } else if ([obj isKindOfClass:[MWLineString class]] && [[(MWLineString *)obj role] isEqualToString:MWPromptRole]) {
      [self setInputPrompt:[(MWLineString *)obj attributedString]];
      return YES;

    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

- (void)linkPrune {}

// Probe methods

- (id)lpDocument:(NSString *)link { return [self document]; }

- (id)lpThisSessionConfig:(NSString *)link { return configLocal; }

- (id)lpScriptContexts:(NSString *)link { return [[self document] mwScriptContexts]; }

- (NSString *)linkableUserDescription { return [NSString stringWithFormat:@"%@ #%u", MWLocalizedStringHere([[self class] description]), [[self window] windowNumber]]; }

// --- Input/output stuff ---

- (void)inputClientReceive:(id)obj {
  [self send:obj toLinkFor:@"outward"];
}

- (NSString *)inputClientCompleteString:(NSString *)str {
  NSSet *completions = [self probe:@selector(lpCompletionSet:) ofLinkFor:@"outward"];
  NSRange lastspace = [str rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch];
  NSRange lastword = MWMakeABRange(lastspace.length ? lastspace.location + lastspace.length : 0, [str length]);
  NSString *lastWordStr = [str substringWithRange:lastword];
  if (!completions) return nil;
  {
    NSEnumerator *e = [completions objectEnumerator];
    NSString *completion;
    while ((completion = [e nextObject])) {
      if ([completion hasPrefix:lastWordStr]) {
        NSMutableString *ms = [[str mutableCopy] autorelease];
        [ms replaceCharactersInRange:lastword withString:completion];
        [ms appendString:@" "];
        return [[ms copy] autorelease];
      }
    }
  }
  return nil;
}

// --- Window controller stuff ---

- (void)releaseWindowFrameAutosaveName {
  MWConnectionDocument *doc = [self document];
  if ([doc isKindOfClass:[MWConnectionDocument class]]) {
    [(MWConnectionDocument *)doc releaseWindowFrameAutosaveName:originalFrameName ? originalFrameName : [self windowFrameAutosaveName]];
  }
  [self setWindowFrameAutosaveName:@""];
  [self setShouldCascadeWindows:YES];
}

- (void)selectWindowFrameAutosaveName {
  MWConnectionDocument *doc = [self document];
  NSString *name;

  if ([doc isKindOfClass:[MWConnectionDocument class]]) {
    name = [(MWConnectionDocument *)doc acquireWindowFrameAutosaveNameWithPrefix:[NSString stringWithFormat:@"%@ %@", [self class], [self outputWindowGroup]]];
    if (!name) name = @"";
    [self setShouldCascadeWindows:NO];
  } else {
    name = @"";
    [self setShouldCascadeWindows:YES];
  }
  if (originalFrameName) {
    [originalFrameName autorelease];
    originalFrameName = [name retain];
  } else {
    [self setWindowFrameAutosaveName:name];
    if ([self isWindowLoaded]) [[self window] setFrameUsingName:name];
  }
}

- (void)windowWillClose:(NSNotification *)notif {
  [self unlink:@"outward"];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
  if ([self mwHasConnection]) {
    [self askUserToDisconnectWindowWithDelegate:self didDisconnect:@selector(windowShouldCloseContinuation:didDisconnect:contextInfo:) contextInfo:NULL];
    return NO;
  }
  return YES;
}

- (void)windowShouldCloseContinuation:(id <MWOutputWinController>)owc didDisconnect:(BOOL)didDisconnect contextInfo:(void *)contextInfo {
  if (didDisconnect) [[self window] performClose:nil];
}

- (BOOL)mwHasConnection {
  if ([[self links] objectForKey:@"outward"]) {
    id result = [self probe:@selector(lpUsefulConnection:) ofLinkFor:@"outward"];
    return !!result;
  } else {
    return NO;
  }
}

// --- Window title ---

- (void)synchronizeWindowTitleWithDocumentName {
  NSString *fn = [[self document] fileName];
  [[self window] setRepresentedFilename:fn ? fn : @""];
  [self updateWindowTitle]; 
}
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)ddn { return [self computeWindowTitle]; }

- (void)updateWindowTitle {
  [[self window] setTitle:[self computeWindowTitle]];
  [self updateMiniwindowTitle];
}
- (void)updateMiniwindowTitle {
  [[self window] setMiniwindowTitle:[self computeMiniwindowTitle]];
}
- (NSString *)computeWindowTitle {
  NSString *title;
  
  title = [[self document] displayName];
  if (!title) {
    title = [self probe:@selector(lpConnectionDescription:) ofLinkFor:@"outward"];
    if (!title) 
      title = @"";
  }

  NSString *const selectedCharacterKey = [self selectedCharacter];
  if (selectedCharacterKey)
    title = [NSString stringWithFormat:@"%@ - %@", title, [[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", selectedCharacterKey, @"name", nil]]];

  NSString *qualification = [self probe:@selector(lpConnectionQualification:) ofLinkFor:@"outward"];
  if (qualification) title = [NSString stringWithFormat:@"%@ - %@", title, qualification];
  //if (![windowGroup isEqualToString:@"main"]) title = [NSString stringWithFormat:@"%@ - %@", title, windowGroup];

  title = [[self links] objectForKey:@"outward"]
    ? title
    : [title stringByAppendingString:MWLocalizedStringHere(@"UnlinkedWindowSuffix")];

  return title;
}
- (NSString *)computeMiniwindowTitle {
  return [self computeWindowTitle];
}

// --- Fullscreen mode suppport ---

- (NSArray *)fullscreenEdgeRect { return [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], nil]; }

- (IBAction)mwFullScreenToggle:(id)sender {
  NSWindow *oldWindow = [[[self window] retain] autorelease];
  NSWindow *newWindow = nil;
  NSArray *edges = [self fullscreenEdgeRect];

  //---
  if (originalWindow) {
    newWindow = originalWindow;
    [originalWindow autorelease];
    originalWindow = nil;
    
    [self setWindowFrameAutosaveName:originalFrameName];
    [originalFrameName autorelease];
    originalFrameName = nil;
  } else {
    NSRect sr = [[oldWindow screen] frame];

    [originalFrameName autorelease];
    originalFrameName = [[self windowFrameAutosaveName] retain];
    if (!originalFrameName) originalFrameName = [@"" retain];
    [self setWindowFrameAutosaveName:@""];
    
    originalWindow = [oldWindow retain];

    sr.origin.x -= [[edges objectAtIndex:0] intValue];
    sr.origin.y -= [[edges objectAtIndex:1] intValue];
    sr.size.width  += [[edges objectAtIndex:0] intValue] + [[edges objectAtIndex:2] intValue];
    sr.size.height += [[edges objectAtIndex:1] intValue] + [[edges objectAtIndex:3] intValue];

    newWindow = [[[MWBorderlessWindow alloc] initWithContentRect:sr styleMask:0 backing:NSBackingStoreBuffered defer:NO] autorelease];
    [newWindow setLevel:NSStatusWindowLevel];
    [newWindow setHidesOnDeactivate:YES];
  }
  //---
  [oldWindow orderOut:nil];
  //---
  {
    NSView *contentView = [[[oldWindow contentView] retain] autorelease];
    [oldWindow setContentView:[[[NSView alloc] initWithFrame:NSMakeRect(0,0,0,0)] autorelease]];
    [newWindow setContentView:contentView];
  }
  if (0) {
    NSToolbar *tb = [[[oldWindow toolbar] retain] autorelease];
    [oldWindow setToolbar:nil];
    [newWindow setToolbar:tb];
  }
  [oldWindow setDelegate:nil];
  [newWindow setDelegate:self];
  //---
  [self setWindow:newWindow];
  [self synchronizeWindowTitleWithDocumentName];
  //---
  [self showWindow:nil];
  
  // have now set up the window. now arrange auto-hide features.
  if (originalWindow) {
    NSRect sr = [[newWindow screen] frame];
    naturalShift = NSMakePoint([[edges objectAtIndex:0] intValue], [[edges objectAtIndex:1] intValue]);
    autohideRectTag = [[[self window] contentView] addTrackingRect:NSInsetRect(NSMakeRect(naturalShift.x, naturalShift.y, sr.size.width, sr.size.height), AUTOHIDE_SIZE, AUTOHIDE_SIZE) owner:self userData:nil assumeInside:YES];
    [[self window] setFrame:sr display:YES];
  } else {
    [[[self window] contentView] removeTrackingRect:autohideRectTag];
  }
}

// called from tracking rect
- (void)mouseEntered:(NSEvent *)event {
  // do nothing
}

- (void)mouseExited:(NSEvent *)event {
  NSRect screenFrame = [[[self window] screen] frame];
  NSPoint mouseLoc = [event locationInWindow];
  
  NSRect newFrame = [[self window] frame];
  NSPoint newFrameOffset = naturalShift;
  NSRect newTrackingRect = NSMakeRect(0,0,0,0);

  //printf("\nmouseExited %f,%f\n", mouseLoc.x, mouseLoc.y);

  if (mouseLoc.x < naturalShift.x + AUTOHIDE_SIZE) {
    //printf("  left");
    newFrameOffset.x = 0;
    newTrackingRect.origin.x = 0;
    newTrackingRect.size.width = naturalShift.x + AUTOHIDE_SIZE;
  } else if (mouseLoc.x >= naturalShift.x + screenFrame.size.width - AUTOHIDE_SIZE) {
    //printf("  right");
    newFrameOffset.x = screenFrame.size.width - newFrame.size.width;
    newTrackingRect.origin.x = naturalShift.x + screenFrame.size.width - AUTOHIDE_SIZE;
    newTrackingRect.size.width = newFrame.size.width - (naturalShift.x + screenFrame.size.width) + AUTOHIDE_SIZE;
  } else {
    //printf("  center");
    newTrackingRect.origin.x = naturalShift.x + AUTOHIDE_SIZE;
    newTrackingRect.size.width = screenFrame.size.width - AUTOHIDE_SIZE * 2;
  }
  
  if (mouseLoc.y < naturalShift.y + AUTOHIDE_SIZE) {
    //printf(", bottom");
    newFrameOffset.y = 0;
    newTrackingRect.origin.y = 0;
    newTrackingRect.size.height = naturalShift.y + AUTOHIDE_SIZE;
  } else if (mouseLoc.y >= naturalShift.y + screenFrame.size.height - AUTOHIDE_SIZE) {
    //printf(", top");
    newFrameOffset.y = screenFrame.size.height - newFrame.size.height;
    newTrackingRect.origin.y = naturalShift.y + screenFrame.size.height - AUTOHIDE_SIZE;
    newTrackingRect.size.height = newFrame.size.height - (naturalShift.y + screenFrame.size.height) + AUTOHIDE_SIZE;
  } else {
    //printf(", center");
    newTrackingRect.origin.y = naturalShift.y + AUTOHIDE_SIZE;
    newTrackingRect.size.height = screenFrame.size.height - AUTOHIDE_SIZE * 2;
  }
  
  newFrame.origin.x = screenFrame.origin.x + newFrameOffset.x;
  newFrame.origin.y = screenFrame.origin.y + newFrameOffset.y;
  [[self window] setFrame:newFrame display:YES animate:YES];

  [[[self window] contentView] removeTrackingRect:autohideRectTag];
  autohideRectTag = [[[self window] contentView] addTrackingRect:newTrackingRect owner:self userData:nil assumeInside:YES];
}

// --- Actions ---

- (IBAction)mwPrepareConnection:(id)sender {
  if (![[self links] objectForKey:@"outward"]) {
    NSURL *url = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]];
    Class handler = [[MWRegistry defaultRegistry] classForURLScheme:[url scheme]];
    
    if (!handler) {
      NSBeginAlertSheet(
        NSLocalizedString(@"NoClassForSchemeAlert_Title", nil),
        NSLocalizedString(@"NoClassForSchemeAlert_Dismiss", nil),
        nil, nil, [self window], nil, nil, nil, NULL,
        NSLocalizedString(@"NoClassForSchemeAlert_Message%@", nil), [url scheme]
      );
      return;
    }
    
    {
      MWTriggerFilter *trf = [[[MWTriggerFilter alloc] init] autorelease];
      MWTeeFilter *tef = [[[MWTeeFilter alloc] init] autorelease];
      MWLogger *log = [[[MWLogger alloc] init] autorelease];
      NSString *lfn = [[NSString stringWithFormat:@"~/Library/Logs/MudWalker Log %@.txt", [[[[self document] fileName] lastPathComponent] stringByDeletingPathExtension]] stringByExpandingTildeInPath];
      
      [trf setConfig:[self config]];
      [tef setConfig:[self config]];
      
      {
        MWConfigTree *lfnTree = [[[MWConfigTree alloc] init] autorelease];
        MWConfigStacker *logStack = [MWConfigStacker stackerWithSuppliers: lfnTree : [self config]];
        [lfnTree setObject:lfn atPath:[MWConfigPath pathWithComponent:@"LogFileName"]];
        [log setConfig:logStack];
      }
      
      [trf link:@"inward" to:@"outward" of:self];
      [tef link:@"inward" to:@"outward" of:trf];
      [tef link:@"teeInward" to:@"Recv" of:log];
      [tef link:@"teeOutward" to:@"Send" of:log];
      [handler scheme:[url scheme] buildFiltersForInnermost:tef config:[self config]];
    }
  }
}

- (IBAction)mwOpenConnection:(id)sender {
  [self mwPrepareConnection:sender];
  [self send:MWTokenOpenConnection toLinkFor:@"outward"];
}

- (IBAction)mwCloseConnectionHard:(id)sender {
  [self send:MWTokenCloseConnection toLinkFor:@"outward"];
}
 
- (IBAction)mwCloseConnectionNice:(id)sender {
  [self send:MWTokenLogoutConnection toLinkFor:@"outward"];
}

- (IBAction)mwUnlinkWindow:(id)sender {
  [[[self links] objectForKey:@"outward"] unlink];
}

- (IBAction)mwSendPing:(id)sender {
  [self send:MWTokenPingSend toLinkFor:@"outward"];
}

- (IBAction)mwInspectFilters:(id)sender {
  [[MWLinkableObjectController locWithLinkable:self] openViewBesideWindow:[self window]];
}

- (IBAction)mwResetPrompt:(id)sender {
  [self setInputPrompt:nil];
}


// --- Validation ---

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(mwPrepareConnection:)) {
    return [self document] && ![[self links] objectForKey:@"outward"];

  } else if (action == @selector(mwOpenConnection:)) {
    return [self document] && ![self probe:@selector(lpUsefulConnection:) ofLinkFor:@"outward"];

  } else if (action == @selector(mwUnlinkWindow:)
          || action == @selector(mwSendPing:)) {
    return !![[self links] objectForKey:@"outward"];

  } else if (action == @selector(mwCloseConnectionHard:)) {
    return !![[self links] objectForKey:@"outward"] && [self probe:@selector(lpClosableConnection:) ofLinkFor:@"outward"];

  } else if (action == @selector(mwCloseConnectionNice:)) {
    return !![[self links] objectForKey:@"outward"] && [self probe:@selector(lpUsefulConnection:) ofLinkFor:@"outward"];

  } else if (action == @selector(mwOpenServerInfo:)) {
    return !![[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil]];

  } else if (action == @selector(mwOpenServerHelp:)) {
    return !![[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"HelpWebSite", nil]];

  } else {
    return YES;
  }
}

// --- Close-while-linked sheet, and callbacks ---

- (void)askUserToDisconnectWindowWithDelegate:(id)delegate didDisconnect:(SEL)didDisconnectSelector contextInfo:(void *)contextInfo {
  NSInvocation *callback;
  NSParameterAssert(delegate != nil);
  NSParameterAssert(didDisconnectSelector != NULL);
  NSParameterAssert([delegate respondsToSelector:didDisconnectSelector]);
  
  callback = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didDisconnectSelector]];
  [callback setTarget:delegate];
  [callback setSelector:didDisconnectSelector];
  [callback setArgument:&self atIndex:2];
  [callback setArgument:&contextInfo atIndex:4];
  
  if ([self probe:@selector(lpUsefulConnection:) ofLinkFor:@"outward"]) {
    [callback retainArguments];
    connectionClosedCallback = [callback retain];
    [self askUserToUnlinkWindow];
  } else {
    BOOL yes = YES;
    [callback setArgument:&yes atIndex:3];
    [callback invoke];
  }
}

- (void)closeConnectionNiceWithDelegate:(id)delegate didDisconnect:(SEL)didDisconnectSelector contextInfo:(void *)contextInfo {
  NSParameterAssert(delegate != nil);
  NSParameterAssert(didDisconnectSelector != NULL);
  NSParameterAssert([delegate respondsToSelector:didDisconnectSelector]);
  
  connectionClosedCallback = [[NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didDisconnectSelector]] retain];
  [connectionClosedCallback setTarget:delegate];
  [connectionClosedCallback setSelector:didDisconnectSelector];
  [connectionClosedCallback setArgument:&self atIndex:2];
  [connectionClosedCallback setArgument:&contextInfo atIndex:4];
  [self mwCloseConnectionNice:self];
}

- (void)connectionClosedCallback:(BOOL)didDisconnect {
  //printf("connectionClosedCallback caller %i\n", (int)didDisconnect);
  if (connectionClosedCallback) {
    [connectionClosedCallback setArgument:&didDisconnect atIndex:3];
    //printf("invoking\n");
    [connectionClosedCallback invoke];
    [connectionClosedCallback autorelease];
    connectionClosedCallback = nil;
  }
}

- (void)askUserToUnlinkWindow {
  NSString *dest = [self probe:@selector(lpConnectionDescription:) ofLinkFor:@"outward"];
  NSBeginAlertSheet(
    [NSString  stringWithFormat:MWLocalizedStringHere(@"OutputWinCloseConfirm_Title%@"), dest],
    MWLocalizedStringHere(@"OutputWinCloseConfirm_NiceButton"),
    MWLocalizedStringHere(@"OutputWinCloseConfirm_CloseButton"),
    MWLocalizedStringHere(@"OutputWinCloseConfirm_CancelButton"),
    [self window], /*modalDelegate*/ self,
    /*didEndSelector*/ nil,
    /*didDismissSelector*/ @selector(doneLinkedAlertSheet:returnCode:contextInfo:),
    /*contextInfo*/ NULL,
    MWLocalizedStringHere(@"OutputWinCloseConfirm_Message")
  );
}

- (void)doneLinkedAlertSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  switch (returnCode) {
    case NSAlertDefaultReturn: /* Nice close */
      [self mwCloseConnectionNice:self]; // when logout succeeds, will call callback
      break;
    case NSAlertOtherReturn: /* Cancel */
    default:
      [self connectionClosedCallback:NO];
      break;
    case NSAlertAlternateReturn: /* Immediate close */
      [[[self links] objectForKey:@"outward"] unlink];
      [self connectionClosedCallback:YES];
      break;
  }
}

// --- Accessors ------------------------------------------------------------

- (void)setDocument:(NSDocument *)doc {
  [self releaseWindowFrameAutosaveName];

  [super setDocument:doc];

  if ([doc isKindOfClass:[MWConnectionDocument class]]) [self setConfig:[(MWConnectionDocument *)doc config]];
  
  [[toolbarItems objectForKey:@"settings"] setTarget:doc ? (id)doc : (id)self];
  [self selectWindowFrameAutosaveName];

}

// NOTE: mismatched accessors
- (id <MWConfigSupplier>)config { return configStack; }
- (void)setConfig:(id <MWConfigSupplier>)newVal {
  [configParent autorelease];
  configParent = [newVal retain];
    
  // ---
  
  if (configStack) [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:configStack];

  [configStack autorelease];
  configStack = [[MWConfigStacker alloc] initWithSuppliers:configLocal :configParent];

  if (configStack) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:configStack];

  [self configChanged:[NSNotification notificationWithName:MWConfigSupplierChangedNotification object:configStack]];
}

- (MWConfigTree *)configLocalStore { return configLocal; }

- (NSString *)outputWindowGroup { return windowGroup; }
- (void)setOutputWindowGroup:(NSString *)newVal {
  [windowGroup autorelease];
  windowGroup = [newVal retain];
  [self selectWindowFrameAutosaveName];
}

- (id <MWExtInputManager>)extInputManager { return extInputManager; }
- (void)setExtInputManager:(id <MWExtInputManager>)newVal {
  [extInputManager autorelease];
  extInputManager = [newVal retain];
}

- (void)setInputPrompt:(NSAttributedString *)string {
  [extInputManager setInputPrompt:string];
}

@end
