/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWAppDelegate.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

#import "MWApplication.h"
#import "MWMudLibrary.h"
#import "MWLibraryMenuController.h"

#import "MWConnectionDocument.h"
#import "MWTextDocument.h"
#import "MWLinkTraceConsole.h"
#import "MWLinkableInspectorWinController.h"

#import "MWOutputWinController.h"
#import "MWTextOutputWinController.h"
#import "MWGlobalInputWinController.h"
#import "MWLibraryWindowController.h"
#import "MWPreferencesWinController.h"
#import "MWDocumentSettingsWinController.h"
#import "MWTextFindController.h"
#import "MWTriggerEnablePanelWinController.h"

#import "MWAccountConfigPane.h"
#import "MWTriggerConfigPane.h"
#import "MWAliasConfigPane.h"
#import "MWConnectionConfigPane.h"
#import "MWDisplayConfigPane.h"
#import "MWKeyMacroConfigPane.h"
#import "MWInputConfigPane.h"
#import "MWColorSetConfigPane.h"

#import "MWColorConverter.h"

// --- Debug ---

@interface MWBreakpointAssertionHandler : NSAssertionHandler
@end

@implementation MWBreakpointAssertionHandler

void MWInvokeBreakpoint(void) {
  NSLog(@"MWInvokeBreakpoint() called\n");
}

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(int)line description:(NSString *)format,... {
  va_list varg;
  va_start(varg, format);
  MWInvokeBreakpoint();
  [super handleFailureInFunction:functionName file:fileName lineNumber:line description:[[[NSString alloc] initWithFormat:format arguments:varg] autorelease]];
  va_end(varg);
}

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(int)line description:(NSString *)format,... {
  va_list varg;
  va_start(varg, format);
  MWInvokeBreakpoint();
  [super handleFailureInMethod:selector object:object file:fileName lineNumber:line description:[[[NSString alloc] initWithFormat:format arguments:varg] autorelease]];
  va_end(varg);
}

@end

// ---

@interface MWAppDelegate (Private)

- (void)openLibraryIfNoWindows;

@end

@implementation MWAppDelegate

- (MWAppDelegate *)init {
  if (!(self = [super init])) return nil;

  [MWRegistry createDefaultRegistry];
  [[MWRegistry defaultRegistry] loadPlugins];

  // Set up default defaults
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithBool:YES], @"MWInputWindowFollows",
    [NSNumber numberWithInt:MWStartupNewDocument], @"MWStartupAction",
    nil
  ]];
  
  // make substituted Lua our script language if it's available
  if ([[MWRegistry defaultRegistry] handlerForCapability:[NSArray arrayWithObjects:@"MWScriptLanguage", @"SubstitutedLua", nil]])
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"SubstitutedLua" forKey:@"MWDefaultScriptLanguageIdentifier"]];


  [NSColor setIgnoresAlpha:NO];

  [[MWRegistry defaultRegistry] registerPreferencePane:[MWAccountConfigPane class] forScope:MWConfigScopeDocument];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWTriggerConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWAliasConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWConnectionConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWDisplayConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWKeyMacroConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWRawConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWInputConfigPane class] forScope:MWConfigScopeAll];
  [[MWRegistry defaultRegistry] registerPreferencePane:[MWColorSetConfigPane class] forScope:MWConfigScopeAll];

  // Set our custom assertion handler
  [[[NSThread currentThread] threadDictionary] setObject:[[[MWBreakpointAssertionHandler alloc] init] autorelease] forKey:@"NSAssertionHandler"];

  {
    NSColor *black = [NSColor blackColor];
    NSColor *white = [NSColor whiteColor];
    MWConfigTree *builtinDefaults = [[MWRegistry defaultRegistry] defaultConfig];
    id o;
   
    [builtinDefaults setObject:[NSNumber numberWithInt:NO] atPath:[MWConfigPath pathWithComponent:@"AutoConnect"]];
    [builtinDefaults setObject:[NSNumber numberWithInt:20000] atPath:[MWConfigPath pathWithComponent:@"ScrollbackCharacters"]];
    [builtinDefaults setObject:[NSNumber numberWithFloat:0] atPath:[MWConfigPath pathWithComponent:@"TextWrapIndent"]];
    [builtinDefaults setObject:[NSFont fontWithName:@"Monaco" size:9.0] atPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]];
    [builtinDefaults setObject:(o = [NSFont fontWithName:@"Futura-Medium" size:10.5]) ? o : [NSFont systemFontOfSize:10.5] atPath:[MWConfigPath pathWithComponent:@"TextFontProportional"]];
    [builtinDefaults setObject:[NSURL URLWithString:@""] atPath:[MWConfigPath pathWithComponent:@"Address"]];
    [builtinDefaults setObject:@"\r\n" atPath:[MWConfigPath pathWithComponent:@"LineEnding"]];
    [builtinDefaults setObject:[NSNumber numberWithUnsignedInt:0x8000020F /* Latin-9 */] atPath:[MWConfigPath pathWithComponent:@"CharEncoding"]];
    [builtinDefaults setObject:[NSNumber numberWithFloat:0.7] atPath:[MWConfigPath pathWithComponent:MWConfigureTelnetPromptTimeout]];
    [builtinDefaults setObject:[[[MWScript alloc] initWithSource:@"" languageIdentifier:nil] autorelease] atPath:[MWConfigPath pathWithComponent:@"LoginScript"]];
    [builtinDefaults setObject:[[[MWScript alloc] initWithSource:@"@quit\nquit\n" languageIdentifier:@"BaseIdentity"] autorelease] atPath:[MWConfigPath pathWithComponent:@"LogoutScript"]];
    
#define DC(c) [[NSColor c##Color] blendedColorWithFraction:0.5 ofColor:black]
#define NC(c) [[NSColor c##Color] blendedColorWithFraction:0.3 ofColor:black]
#define LC(c) [NSColor c##Color]
#define XLC(c) [[NSColor c##Color] blendedColorWithFraction:0.5 ofColor:white]
#define XC    [NSColor grayColor]

    [builtinDefaults addDirectoryAtPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-black", nil] recurse:YES insertIndex:-1];
    [builtinDefaults setObject:@"White on Black" atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-black", @"Name", nil]];
    [builtinDefaults setObject:MWColorDictionaryFromArray([NSArray arrayWithObjects:
      /* normal, bright, dim, special */
      /* See MWConstants.h for what these mean */
      NC(black), NC(red), NC(green), NC(yellow), NC(blue), NC(magenta), NC(cyan), NC(white), NC(white), NC(black),
      LC(black), LC(red), LC(green), LC(yellow), LC(blue), LC(magenta), LC(cyan), LC(white), LC(white), LC(black),
      DC(black), DC(red), DC(green), DC(yellow), DC(blue), DC(magenta), DC(cyan), DC(white), DC(white), DC(black),
      [NSColor orangeColor],NC(green),XLC(blue),XC,         XC,       XC,          XC,       XC,        XC,        XC,        
      nil
    ]) atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-black", @"ColorDictionary", nil]];


    [builtinDefaults addDirectoryAtPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-white", nil] recurse:YES insertIndex:-1];
    [builtinDefaults setObject:@"Black on White" atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-white", @"Name", nil]];
    [builtinDefaults setObject:MWColorDictionaryFromArray([NSArray arrayWithObjects:
      /* normal, bright, dim, special */
      /* See MWConstants.h for what these mean */
      NC(black), NC(red), NC(green), NC(yellow), NC(blue), NC(magenta), NC(cyan), NC(white), NC(black), LC(white),
      LC(black), LC(red), LC(green), LC(yellow), LC(blue), LC(magenta), LC(cyan), LC(white), LC(black), LC(white),
      DC(black), DC(red), DC(green), DC(yellow), DC(blue), DC(magenta), DC(cyan), DC(white), DC(black), NC(white),
      DC(orange),DC(green),DC(blue),XC,         XC,       XC,          XC,       XC,        XC,        XC,        
      nil
    ]) atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-white", @"ColorDictionary", nil]];

#undef DC
#undef NC
#undef LC
#undef XLC
#undef XC
    [builtinDefaults setObject:@"builtin-on-white" atPath:[MWConfigPath pathWithComponents:@"SelectedColorSet", nil]];


    [builtinDefaults setObject:[NSNumber numberWithInt:YES] atPath:[MWConfigPath pathWithComponent:@"ColorBrightBold"]];
    
    {
      NSEnumerator *rowE = [[NSArray arrayWithObjects:
        [NSArray arrayWithObjects:@"#'7", @"northwest", nil],
        [NSArray arrayWithObjects:@"#'8", @"north", nil],
        [NSArray arrayWithObjects:@"#'9", @"northeast", nil],
        [NSArray arrayWithObjects:@"#'4", @"west", nil],
        [NSArray arrayWithObjects:@"#'5", @"look", nil],
        [NSArray arrayWithObjects:@"#'6", @"east", nil],
        [NSArray arrayWithObjects:@"#'1", @"southwest", nil],
        [NSArray arrayWithObjects:@"#'2", @"south", nil],
        [NSArray arrayWithObjects:@"#'3", @"southeast", nil],
        [NSArray arrayWithObjects:@"#'+", @"up", nil],
        [NSArray arrayWithObjects:@"#'-", @"down", nil],
        [NSArray arrayWithObjects:@"#'*", @"in", nil],
        [NSArray arrayWithObjects:@"#'/", @"out", nil],
        nil
      ] objectEnumerator];
      NSArray *row;
      
      MWConfigPath *dir = [MWConfigPath pathWithComponent:@"KeyCommands"];
      
      while ((row = [rowE nextObject])) {
        MWConfigPath *entry = [dir pathByAppendingComponent:[row objectAtIndex:0]];
        [builtinDefaults addDirectoryAtPath:entry recurse:YES insertIndex:-1];
        [builtinDefaults setObject:[row objectAtIndex:1] forKey:@"command" atPath:entry];
      }
    }
    
    {
      MWConfigPath *rdir = [MWConfigPath pathWithComponent:@"Reconnect"];
      [builtinDefaults addDirectoryAtPath:rdir recurse:YES insertIndex:-1];
      [builtinDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"OnFailedConnect" atPath:rdir];
      [builtinDefaults setObject:[NSNumber numberWithFloat:10.0] forKey:@"Delay" atPath:rdir];
      [builtinDefaults setObject:[NSNumber numberWithInt:0] forKey:@"DelayExponentMinusOne" atPath:rdir];
    }

    [builtinDefaults setObject:[NSNumber numberWithInt:YES] atPath:[MWConfigPath pathWithComponent:@"InputLocalEcho"]];
    [builtinDefaults setObject:[NSNumber numberWithInt:YES] atPath:[MWConfigPath pathWithComponent:@"InputPromptInOutput"]];
    [builtinDefaults setObject:[NSNumber numberWithInt:NO] atPath:[MWConfigPath pathWithComponent:@"ReceivePromptShow"]];
    [builtinDefaults setObject:[NSNumber numberWithInt:NO] atPath:[MWConfigPath pathWithComponent:@"ReceivePromptShowDifferent"]];
    
    [builtinDefaults addDirectoryAtPath:[MWConfigPath pathWithComponent:@"ServerInfo"] recurse:YES insertIndex:-1];
  }

  [[NSNotificationCenter defaultCenter] addObserver:[MWLinkableInspectorWinController class] selector:@selector(checkImportant:) name:MWLinkableTraceNotification object:nil];

  return self;
}

- (void)awakeFromNib {
  // Add menu items for plugins
  {
    NSSet *cmds = [[MWRegistry defaultRegistry] userInterfaceCommandsForContext:@"global"];
    NSEnumerator *cmdE = [cmds objectEnumerator];
    NSDictionary *cmd;
    if ([cmds count]) {
      [globalCommandMenu addItem:[NSMenuItem separatorItem]];
    }
    while ((cmd = [cmdE nextObject])) {
      [[globalCommandMenu addItemWithTitle:[cmd objectForKey:@"name"] action:NSSelectorFromString([cmd objectForKey:@"performSelector"]) keyEquivalent:@""] setTarget:[cmd objectForKey:@"handler"]];
    }
  }
  
  // Hook up library menu
  MWLibraryMenuController *lmc = [[MWLibraryMenuController alloc] init];
  [lmc setLibrary:[self mudLibrary]];
  [lmc setMenu:libraryMenu];
}

- (void)discardGlobals {
  [globalInputWC autorelease]; globalInputWC = nil;
  [mudLibraryWC autorelease]; mudLibraryWC = nil;
  [prefsWC autorelease]; prefsWC = nil;
  [appConfigWC autorelease]; appConfigWC = nil;
  [mudLibrary autorelease]; mudLibrary = nil;
  [triggerEnableWC autorelease]; triggerEnableWC = nil;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[MWRegistry defaultRegistry] saveConfig];
  [self discardGlobals];
}

- (void)dealloc {
  [self discardGlobals];
  [super dealloc];
}

// --- Application launch and document opening ---

- (void)applicationDidFinishLaunching:(NSNotification *)notif {
  [self showTextInput:nil];

  // Open library if appropriate
  if ([[NSUserDefaults standardUserDefaults] integerForKey:@"MWStartupAction"] == MWStartupOpenLibrary)
    [self performSelector:@selector(openLibraryIfNoWindows) withObject:nil afterDelay:0];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (flag) return YES;
  if ([[NSUserDefaults standardUserDefaults] integerForKey:@"MWStartupAction"] == MWStartupOpenLibrary) {
    [self showLibraryWindow:self];
    return NO;
  } else {
    return YES;
  }
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return [[NSUserDefaults standardUserDefaults] integerForKey:@"MWStartupAction"] == MWStartupNewDocument;
}

- (NSApplicationTerminateReply)applicationMWPresaveHook:(MWApplication *)sender {
  BOOL dontAskBeforeLogout = [[NSUserDefaults standardUserDefaults] boolForKey:@"MWDontAskBeforeLogout"];
  NSEnumerator *e = [[NSApp windows] objectEnumerator];
  NSWindow *w;
  id <NSObject, MWOutputWinController> wc;
  NSMutableArray *windowsBusy = [NSMutableArray array];

  while ((w = [e nextObject])) {
    wc = [w delegate];
    if (!wc || ![wc conformsToProtocol:@protocol(MWOutputWinController)]) continue;
    if ([wc mwHasConnection]) {
      [windowsBusy addObject:wc];
    }
  }
  
  busyWindowCounter = [windowsBusy count];
  
  if ([windowsBusy count] == 0) {
    return NSTerminateNow;
  
  } else if ([windowsBusy count] == 1 && !dontAskBeforeLogout) {
    [[windowsBusy objectAtIndex:0] askUserToDisconnectWindowWithDelegate:self didDisconnect:@selector(busyWindow:didDisconnect:contextInfo:) contextInfo:NULL];
    return NSTerminateLater;
  } else {
    switch (
      dontAskBeforeLogout
      ? NSAlertDefaultReturn
      : NSRunAlertPanel(
        MWLocalizedStringHere(@"AppQuitUnlinkPanel_Title"), 
        MWLocalizedStringHere(@"AppQuitUnlinkPanel_Message"), 
        MWLocalizedStringHere(@"AppQuitUnlinkPanel_LogoutButton"), 
        MWLocalizedStringHere(@"AppQuitUnlinkPanel_CancelButton"), 
        MWLocalizedStringHere(@"AppQuitUnlinkPanel_QuitButton")
      )
    ) {
      case NSAlertDefaultReturn: {
        NSEnumerator *winE = [windowsBusy objectEnumerator];
        id <MWOutputWinController> win;
        while ((win = [winE nextObject])) {
          [win closeConnectionNiceWithDelegate:self didDisconnect:@selector(busyWindow:didDisconnect:contextInfo:) contextInfo:NULL];
        }
        return NSTerminateLater;
      }
      case NSAlertAlternateReturn:
        return NSTerminateCancel;
        
      case NSAlertOtherReturn:
        return NSTerminateNow;
        
      case NSAlertErrorReturn: default:
        return NSTerminateCancel;
    }
  }
}

- (void)busyWindow:(id <MWOutputWinController>)owc didDisconnect:(BOOL)didDisconnect contextInfo:(void *)contextInfo {
  //printf("busyWindow:didDisconnect:contextInfo: counter = %i didDisconnect = %i\n", busyWindowCounter, didDisconnect);
  if (busyWindowCounter <= 0) return;
  if (didDisconnect) {
    busyWindowCounter--;
    if (busyWindowCounter <= 0) {
      [(MWApplication *)NSApp replyToApplicationMWPresaveHook:YES];
    }
  } else {
    [(MWApplication *)NSApp replyToApplicationMWPresaveHook:NO];
  }
}

- (void)openLibraryIfNoWindows {
  NSEnumerator *e = [[NSApp windows] objectEnumerator];
  NSWindow *w;

  while ((w = [e nextObject])) {
    //NSLog(@"olinw: %@ \"%@\" (%@, %@) %i %i", w, [w title], [w delegate], [w windowController], [w isVisible], [w canBecomeMainWindow]);
    if ([w isVisible] && [w canBecomeMainWindow]) {
      //NSLog(@"Cancelled library open because of window: %@ %@", w, [w title]);
      return;
    }
  }
  [self performSelector:@selector(showLibraryWindow:) withObject:nil afterDelay:0];
}

- (IBAction)newConnectionDocument:(id)sender {
  [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:MWConnectionDocument_Type display:YES];
}

- (IBAction)newTextDocument:(id)sender {
  [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:NSStringPboardType display:YES];
}

- (void)makeDocumentForURL:(NSURL *)url connect:(BOOL)connect {
  MWConnectionDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:MWConnectionDocument_Type display:NO];
    
  // the new document should appear un-modified
  [[doc undoManager] disableUndoRegistration];
  [[doc configLocalStore] setObject:url atPath:[MWConfigPath pathWithComponent:@"Address"]];
  [[doc undoManager] enableUndoRegistration];
    
  [doc showWindows];
  
  if (connect) [doc mwOpenConnection:nil];
}


// --- Actions ---

- (IBAction)showTextInput:(id)sender {
  [[self globalInputWinController] showWindow:sender];
}

- (IBAction)showLibraryWindow:(id)sender {
  if (!mudLibraryWC) mudLibraryWC = [[MWLibraryWindowController alloc] init];
  [mudLibraryWC showWindow:sender];
}

- (IBAction)showPreferencesWindow:(id)sender {
  if (!prefsWC) prefsWC = [[MWPreferencesWinController alloc] init];
  [prefsWC showWindow:sender];
}

- (IBAction)showAppConfigWindow:(id)sender {
  if (!appConfigWC) appConfigWC = [[MWDocumentSettingsWinController alloc] init];
  [appConfigWC showWindow:sender];
}

- (IBAction)showLinkTraceConsole:(id)sender {
  MWLinkTraceConsole *c = [[[MWLinkTraceConsole alloc] init] autorelease];
  MWTextOutputWinController *tw = [[[MWTextOutputWinController alloc] init] autorelease];
  
  [tw link:@"outward" to:@"inward" of:c];
  [tw showWindow:nil];
}

- (IBAction)showLicense:(id)sender {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"txt"];
  MWTextDocument *doc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:path display:YES];
  [doc setReadOnly:YES];
  if (!doc) NSBeep();
}

- (IBAction)showMudWalkerWebSite:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MWLocalizedStringHere(@"MudWalkerWebSite")]];
}

- (IBAction)disableSound:(id)sender {
  [self setDisabledSound:![self disabledSound]];
}

- (IBAction)disableSpeech:(id)sender {
  [self setDisabledSpeech:![self disabledSpeech]];
}

- (IBAction)disableKeyMacros:(id)sender {
  [self setDisabledKeyMacros:![self disabledKeyMacros]];
}

- (IBAction)synchronizeDefaults:(id)sender {
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showGotoLineControls:(id)sender {
  [[MWTextFindController sharedInstance] showGotoLineControls:sender];
}

- (IBAction)showTriggerEnablePanel:(id)sender {
  if (!triggerEnableWC) {
    triggerEnableWC = [[MWTriggerEnablePanelWinController alloc] init];
  }
    
  [triggerEnableWC showWindow:sender];
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  BOOL hasState = [(id <NSObject>)item respondsToSelector:@selector(setState:)];
  if (action == @selector(disableSound:)) {
    if (hasState) [(NSMenuItem *)item setState:[self disabledSound] ? NSOnState : NSOffState];
    return YES;
  } else if (action == @selector(disableSpeech:)) {
    if (hasState) [(NSMenuItem *)item setState:[self disabledSpeech] ? NSOnState : NSOffState];
    return YES;
  } else if (action == @selector(disableKeyMacros:)) {
    if (hasState) [(NSMenuItem *)item setState:[self disabledKeyMacros] ? NSOnState : NSOffState];
    return YES;
  } else {
    return YES;
  }
}

// --- Disables ---

- (BOOL)disabledSound { return disabledSound; }
- (BOOL)disabledSpeech { return disabledSpeech; }
- (BOOL)disabledKeyMacros { return disabledKeyMacros; }
- (void)setDisabledSound:(BOOL)newVal { disabledSound = newVal; }
- (void)setDisabledSpeech:(BOOL)newVal { disabledSpeech = newVal; }
- (void)setDisabledKeyMacros:(BOOL)newVal { disabledKeyMacros = newVal; }

// --- Accessors ---

- (MWMudLibrary *)mudLibrary {
  if (!mudLibrary) mudLibrary = [[MWMudLibrary alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
  return mudLibrary;
}
- (MWGlobalInputWinController *)globalInputWinController {
  if (!globalInputWC) globalInputWC = [[MWGlobalInputWinController alloc] init];
  return globalInputWC;  
}

- (NSMenu *)terminalAccountMenu { return terminalAccountMenu; }

@end
