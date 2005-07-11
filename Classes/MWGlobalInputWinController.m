/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWGlobalInputWinController.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

#import "MWInputTextView.h"
#import "MWAppDelegate.h"
#import "MWExtInputManagerForGIW.h"

#define CMD_HISTORY_SIZE 10000

#define IM_FIRST 0
#define IM_MAIN 0
#define IM_PASSWORD 1
#define IM_LAST 1

static NSString *MWGlobalInputWindowFontDefaultKey = @"MWGlobalInputWindowFontDefault";

@interface MWGlobalInputWinController (Private)

- (void)updateHistoryFromView;
- (void)updateViewFromHistory;
- (void)mainWindowFrameChanged:(id)notif;
- (void)startFading;
- (void)stepFading:(NSTimer *)t;
- (MWExtInputManagerForGIW *)extInputManagerForClient:(id <MWExtInputClient>)client;

@end

@implementation MWGlobalInputWinController

// --- initialization ---

- (id)init {
  if (!(self = [self initWithWindowNibName:@"InputPanel"])) return nil;
  
  [self setWindowFrameAutosaveName:@"InputPanel"];
  [self setShouldCascadeWindows:NO];
  
  undoManager = [[NSUndoManager allocWithZone:[self zone]] init];
  
  toolbarItems = [[NSMutableDictionary allocWithZone:[self zone]] init];
  MWTOOLBAR_ITEM(@"selectHistoryNext",  self, @selector(selectHistoryNext:));
  MWTOOLBAR_ITEM(@"selectHistoryPrev",  self, @selector(selectHistoryPrev:));
  MWTOOLBAR_ITEM(@"selectHistoryFirst", self, @selector(selectHistoryFirst:));
  MWTOOLBAR_ITEM(@"selectHistoryLast",  self, @selector(selectHistoryLast:));
  MWTOOLBAR_ITEM(@"mwModeMain",         self, @selector(mwModeMain:));
  MWTOOLBAR_ITEM(@"mwModePassword",     self, @selector(mwModePassword:));
  
  return self;
}

- (void)dealloc {
  NSFont *inputFont = [[inputTextView typingAttributes] objectForKey:NSFontAttributeName];

  [[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObjects:[inputFont fontName], [NSNumber numberWithFloat: [inputFont pointSize]], nil] forKey:MWGlobalInputWindowFontDefaultKey];
  [[NSUserDefaults standardUserDefaults] synchronize]; // needed as this apparently happens after the regular sync

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [undoManager release]; undoManager = nil;
  [toolbarItems release]; toolbarItems = nil;

  [super dealloc];
}

- (void)windowDidLoad {
  {
    NSToolbar *const toolbar = [[NSToolbar alloc] initWithIdentifier:[[self class] description]];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeLabelOnly];
    [toolbar setVisible:NO];
    [[self window] setToolbar:toolbar];
  }

  {
    NSArray *fontInfo = [[NSUserDefaults standardUserDefaults] objectForKey:MWGlobalInputWindowFontDefaultKey];
    NSFont *inputFont;
  
    inputFont = [NSFont fontWithName: fontInfo ? [fontInfo objectAtIndex:0] : @"Monaco"
      size: fontInfo ? [[fontInfo objectAtIndex:1] floatValue] : 11.0];
  
    [inputTextView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
      inputFont, NSFontAttributeName,
      nil
    ]];
    [inputTextView setRichText:NO];
    [inputTextView setAllowsUndo:YES];
  }
  
  [passwordField setNextKeyView:passwordField];
  
  targetWindowOffset = NSMakePoint(0, -([[self window] frame].size.height + 1));
  [self considerMainWindow];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];

  [[self window] setAlphaValue:0];

  [super windowDidLoad];
}

// --- Toolbar delegate ---

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  // Note that if we wanted to allow duplicate items, the items must be copied before returning. Otherwise, it's better not to.
  return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:
    @"selectHistoryFirst", @"selectHistoryPrev", @"selectHistoryNext", @"selectHistoryLast",
    NSToolbarFlexibleSpaceItemIdentifier,
    @"mwModeMain", @"mwModePassword",
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

// --- Validation ---

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL const action = [item action];
  MWExtInputManagerForGIW *eim = [self extInputManagerForClient:targetWindowController];
  if (action == @selector(selectHistoryFirst:)) {
    return [eim historyIndex] > 0;
  } else if (action == @selector(selectHistoryPrev:)) {
    return [eim historyIndex] > 0;
  } else if (action == @selector(selectHistoryNext:)) {
    return [eim historyIndex] < [[eim mutableHistory] count]-1;
  } else if (action == @selector(selectHistoryLast:)) {
    return [eim historyIndex] < [[eim mutableHistory] count]-1;
  } else if (action == @selector(mwModeMain:)) {
    return [inputTabs indexOfTabViewItem:[inputTabs selectedTabViewItem]] != IM_MAIN;
  } else if (action == @selector(mwModePassword:)) {
    return [inputTabs indexOfTabViewItem:[inputTabs selectedTabViewItem]] != IM_PASSWORD;
  } else {
    // would call super if super implemented the protocol
    return NO;
  }
}

// Specific behavior

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
  float newHeight = defaultFrame.size.height / 5;

  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MWInputWindowFollows"]) {
    NSRect trackedFrame = [[targetWindowController window] frame];
    return NSMakeRect(
      trackedFrame.origin.x,
      trackedFrame.origin.y - (newHeight + 1),
      trackedFrame.size.width,
      newHeight
    );
  } else {
    defaultFrame.size.height = newHeight;
    return defaultFrame;
  }
}

- (void)windowDidBecomeKey:(NSNotification *)notif {
  NSResponder *thing = nil;
  switch ([inputTabs indexOfTabViewItem:[inputTabs selectedTabViewItem]]) {
    case IM_MAIN: thing = inputTextView; break;
    case IM_PASSWORD: thing = passwordField; break;
    default: break;
  }
  if (thing) [[self window] makeFirstResponder:thing];
  [self startFading];
}

- (IBAction)showWindow:(id)sender {
  [super showWindow:sender];
  [self startFading];
}

- (void)chooseInputMethodTab:(int)tab {
  [inputTabs selectTabViewItemAtIndex:tab];
  [self windowDidBecomeKey:nil]; // focus the right thing
}

// --- Input entering and history ---

- (MWExtInputManagerForGIW *)extInputManagerForClient:(id <MWExtInputClient>)client {
  MWExtInputManagerForGIW *eim;
  
  eim = (MWExtInputManagerForGIW *)[client extInputManager];
  
  if (!eim || ![eim isKindOfClass:[MWExtInputManagerForGIW class]]) {
    eim = [[[MWExtInputManagerForGIW alloc] init] autorelease];
    [eim setTarget:client];
    [client setExtInputManager:eim];
  }
  
  return eim;
}

- (void)privatePassInputString:(NSString *)str role:(NSString *)role {
  if ([str length]) {
    NSEnumerator *lineE = [[str componentsSeparatedByLineTerminators] objectEnumerator];
    NSString *line;
    while ((line = [lineE nextObject]))
      [targetWindowController inputClientReceive:[MWLineString lineStringWithString:line role:role]];
  } else {
    [targetWindowController inputClientReceive:[MWLineString lineStringWithString:@"" role:role]];
  }
}

- (void)updateViewFromHistory {
  MWExtInputManagerForGIW *eim = [self extInputManagerForClient:targetWindowController];
  NSString *hItem = ([eim historyIndex] >= [[eim mutableHistory] count]) ? @"" : [[eim mutableHistory] objectAtIndex:[eim historyIndex]];
  
  //NSLog(@"updating view from history: %@", history);
  
  [[self undoManager] removeAllActionsWithTarget:inputTextView];
  [inputTextView setString:hItem];
  [inputTextView setSelectedRange:NSMakeRange(0, [hItem length])];
}
- (void)updateHistoryFromView {
  MWExtInputManagerForGIW *eim = [self extInputManagerForClient:targetWindowController];
  if ([eim historyIndex] == [[eim mutableHistory] count]-1) {
    [[eim mutableHistory] replaceObjectAtIndex:[eim historyIndex] withObject:[[[inputTextView string] copy] autorelease]];
    //printf("matched: %i == %i\n", historyIndex, [history count]-1);
  } else {
    //printf("unmatching: %i != %i\n", historyIndex, [history count]-1);
  }
}

- (void)inputTextViewEnteredText:(id)sender shouldKeep:(BOOL)shouldKeep {
  MWExtInputManagerForGIW *eim = [self extInputManagerForClient:targetWindowController];
  NSString *text = [inputTextView string];

  shouldKeep = shouldKeep || [[NSUserDefaults standardUserDefaults] boolForKey:@"MWInputKeepEntry"];

  [self privatePassInputString:text role:nil];
  
  [eim setHistoryIndex:[[eim mutableHistory] count] - 1];
  [self updateHistoryFromView];
  [[eim mutableHistory] addObject:shouldKeep ? [[text copy] autorelease] : @""];
  
  if ([[eim mutableHistory] count] > CMD_HISTORY_SIZE) {
    [[eim mutableHistory] removeObjectsInRange:NSMakeRange(0, [[eim mutableHistory] count] - CMD_HISTORY_SIZE)];
  }
  
  [eim setHistoryIndex:[[eim mutableHistory] count] - 1];
  [self updateViewFromHistory];
}

- (IBAction)enterPassword:(NSTextField *)field {
  [self privatePassInputString:[field stringValue] role:MWPasswordRole];
  [field setStringValue:@""];
  [[self window] makeFirstResponder:field];
}

- (BOOL)inputTextView:(id)sender specialKeyEvent:(NSEvent *)event {
  if ([[event characters] length] == 1) {
    const unichar character = [[event characters] characterAtIndex:0];
    switch (character) {
      case NSHomeFunctionKey: case NSEndFunctionKey: case NSPageUpFunctionKey: case NSPageDownFunctionKey:
        [[targetWindowController window] makeKeyWindow];
        [NSApp postEvent:event atStart:YES];
        return YES;
      case NSUpArrowFunctionKey: case NSDownArrowFunctionKey: case NSLeftArrowFunctionKey: case NSRightArrowFunctionKey: case MWEnterKey:
        // arrows and enter are considered numpad keys - exclude them from special handling
        return NO;
      default:
        break;
    }
  }
  return NO;
}

- (NSString *)inputTextView:(MWInputTextView *)sender completeString:(NSString *)str {
  return [targetWindowController inputClientCompleteString:str];
}

- (void)focusChange {
  [[targetWindowController window] makeKeyWindow];
}

- (IBAction)selectHistoryFirst:(id)sender {
  [self updateHistoryFromView];
  [[self extInputManagerForClient:targetWindowController] setHistoryIndex:0];
  [self updateViewFromHistory];
}
- (IBAction)selectHistoryPrev:(id)sender {
  MWExtInputManagerForGIW *const eim = [self extInputManagerForClient:targetWindowController];
  [self updateHistoryFromView];
  if ([eim historyIndex] > 0) [eim setHistoryIndex:[eim historyIndex] - 1]; else NSBeep();
  [self updateViewFromHistory];
}
- (IBAction)selectHistoryNext:(id)sender {
  MWExtInputManagerForGIW *const eim = [self extInputManagerForClient:targetWindowController];
  [self updateHistoryFromView];
  if ([eim historyIndex] < [[eim mutableHistory] count]-1) [eim setHistoryIndex:[eim historyIndex] + 1]; else NSBeep();
  [self updateViewFromHistory];
}
- (IBAction)selectHistoryLast:(id)sender {
  MWExtInputManagerForGIW *const eim = [self extInputManagerForClient:targetWindowController];
  [self updateHistoryFromView];
  [eim setHistoryIndex:[[eim mutableHistory] count] - 1];
  [self updateViewFromHistory];
}

- (IBAction)mwModeMain:(id)sender { [self chooseInputMethodTab:IM_MAIN]; }
- (IBAction)mwModePassword:(id)sender { [self chooseInputMethodTab:IM_PASSWORD]; }

- (void)updatePromptString:(NSNotification *)notif {
  NSString *prompt = [[[self extInputManagerForClient:targetWindowController] inputPrompt] string];
  
  if (!prompt) prompt = MWLocalizedStringHere(@"DefaultInputPanelTitle");
  [[self window] setTitle:[NSString stringWithFormat:@"[%@] %@", [[targetWindowController window] title], prompt]];
  
  if ([prompt rangeOfString:@"Password" options:NSCaseInsensitiveSearch].length) [self chooseInputMethodTab:IM_PASSWORD];
  else if ([inputTabs indexOfTabViewItem:[inputTabs selectedTabViewItem]] == IM_PASSWORD) [self chooseInputMethodTab:IM_MAIN];
}

// --- Target window tracking ---

- (void)setTargetSheet:(NSWindow *)newSheet {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  if (targetWindowSheet) {
    [center removeObserver:self name:nil object:targetWindowSheet];
    targetWindowSheet = nil; // NONRELEASED
  }
  if (newSheet) {
    targetWindowSheet = newSheet; // NONRETAINED
    [center addObserver:self selector:@selector(sheetMoved:) name:NSWindowDidMoveNotification object:newSheet];
    [center addObserver:self selector:@selector(sheetMoved:) name:NSWindowDidResizeNotification object:newSheet];
    // grr. sheets don't send NSWindowWillCloseNotification...but we catch NSWindowDidEndSheetNotification on the main window instead
  }
  [self mainWindowFrameChanged:nil];
}

- (void)considerMainWindow:(id)unused { [self considerMainWindow]; }

- (void)considerMainWindow {
  NSWindow *const mainWindow = [NSApp mainWindow];
  NSWindowController *controller = [mainWindow windowController];
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  //NSLog(@"considering %@ %@", mainWindow, controller);

  if (targetWindowController) {
    [center removeObserver:self name:nil object:targetWindowController];
    [center removeObserver:self name:nil object:[targetWindowController window]];
    [targetWindowController autorelease];
    targetWindowController = nil;
  }
  if (controller && [controller conformsToProtocol:@protocol(MWExtInputClient)] && [[self extInputManagerForClient:(id <MWExtInputClient>)controller] isActive]) {
  
    [center addObserver:self selector:@selector(mainWindowFrameChanged:) name:NSWindowDidMoveNotification object:mainWindow];
    [center addObserver:self selector:@selector(mainWindowFrameChanged:) name:NSWindowDidResizeNotification object:mainWindow];
    [center addObserver:self selector:@selector(mainWindowOpeningSheet:) name:NSWindowWillBeginSheetNotification object:mainWindow];
    [center addObserver:self selector:@selector(sheetClosing:) name:NSWindowDidEndSheetNotification object:mainWindow];
    
    targetWindowController = [controller retain];
    [self setTargetSheet:[mainWindow attachedSheet]];
    [self mainWindowFrameChanged:nil];
    [[self window] setLevel:[[targetWindowController window] level] + 1];
    [[self window] orderFront:nil];
    //NSLog(@"is active");
  } else {
    targetWindowController = nil;
    [self setTargetSheet:nil];
    //NSLog(@"is not active");
  }
  [self updatePromptString:nil];
  [self startFading];
}

// --- Window frame changes ---

- (void)mainWindowFrameChanged:(NSNotification *)notif {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MWInputWindowFollows"]) {
    if (targetWindowController && (!notif || [notif object] == [targetWindowController window])) {
      NSWindow *mainWindow = [targetWindowController window];
      NSPoint mainOrigin = [mainWindow frame].origin;
      NSPoint sheetOrigin = [targetWindowSheet frame].origin;
      if (targetWindowSheet) {
        if (sheetOrigin.y < mainOrigin.y) mainOrigin.y = sheetOrigin.y;
      }
      wasAutoMove = YES;
      [[self window] setFrameOrigin:NSMakePoint(
        mainOrigin.x + targetWindowOffset.x,
        mainOrigin.y + targetWindowOffset.y
      )];
      wasAutoMove = NO;
    }
  }
  [self startFading]; // delete unless we keep the alpha-from-coverage code
}

- (void)myWindowFrameChanged:(id)notif {
  if (wasAutoMove) return;
  if (targetWindowController) {
    NSWindow *mainWindow = [targetWindowController window];
    NSPoint my = [[self window] frame].origin,
            their = [mainWindow frame].origin;
    targetWindowOffset = NSMakePoint(my.x - their.x, my.y - their.y);
  }
  [self startFading]; // delete unless we keep the alpha-from-coverage code
}

// --- Notification methods ----

- (void)mainWindowOpeningSheet:(NSNotification *)notif {
  [self performSelector:@selector(mainWindowOpenedSheet:) withObject:nil afterDelay:0];
}

- (void)mainWindowOpenedSheet:(NSNotification *)notif {
  [self setTargetSheet:[[targetWindowController window] attachedSheet]];
}

- (void)sheetMoved:(NSNotification *)notif {
  [self mainWindowFrameChanged:nil];
}

- (void)sheetClosing:(NSNotification *)notif {
  [self setTargetSheet:nil];
}

- (void)mainWindowChanged:(NSNotification *)notif {
  [self performSelector:@selector(considerMainWindow:) withObject:nil afterDelay:0.0];
}

- (void)mainWindowResigned:(NSNotification *)notif {
  [self performSelector:@selector(considerMainWindow:) withObject:nil afterDelay:0.0];
}

// --- Delegate methods ---

- (void)windowDidMove:(NSNotification *)notif {
  [self myWindowFrameChanged:notif];
}

- (void)windowDidResize:(NSNotification *)notif {
  [self myWindowFrameChanged:notif];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return undoManager;
}

// --- Fancy window fading ---

- (void)startFading {
  if (!isFading) {
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(stepFading:) userInfo:nil repeats:YES];
    isFading = YES;
  }
}

- (float)calcNormalAlpha {
  NSRect fa = [[self window] frame];
  NSRect fb = [[targetWindowController window] frame];
  NSRect inter = NSIntersectionRect(fa, fb);
  float myArea = fa.size.width * fa.size.height;
  float iArea = inter.size.width * inter.size.height;
  float covering = iArea / myArea;
  return 0.5 + (1-covering) * 0.5;
}

- (void)stepFading:(NSTimer *)t {
  NSWindow *w = [self window];
  float maxAlpha = [self calcNormalAlpha]; 
  float alpha = [w alphaValue];
  BOOL finish = NO;
  
  if (targetWindowController) {
    if (alpha <= 0) [w orderFront:self];
    alpha += 0.24;
    if (alpha >= maxAlpha) {
      finish = YES;
      alpha = maxAlpha;
    }
  } else {
    alpha -= 0.12;
    if (alpha <= 0) {
      [w orderOut:self];
      finish = YES;
      alpha = 0;
    }
  }
  
  if (finish) {
    [t invalidate];
    isFading = NO;
  }
  [w setAlphaValue:alpha];
}

@end
