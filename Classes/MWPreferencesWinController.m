/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWPreferencesWinController.h"

#import <MudWalker/MWRegistry.h>
#import <MudWalker/MWScriptLanguage.h>
#import <MudWalker/MWUtilities.h>
#import <MWAppKit/MWOutputTextView.h>

@interface MWPreferencesWinController (Private)

- (void)updateWindow;

@end

@implementation MWPreferencesWinController

static NSArray *boolDefaultKeys = nil;

+ (void)initialize {
  if (!boolDefaultKeys) boolDefaultKeys = [[NSArray alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"MWPreferencesWindowBoolDefaults" ofType:@"plist"]];
}

- (id)init {
  if (!(self = [super initWithWindowNibName:@"Preferences"])) return self; 
  
  [cScrollLockColor setContinuous:YES];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)windowDidLoad {
  [cScriptLanguage removeAllItems];
  
  MWenumerate([[[MWRegistry defaultRegistry] allHandlersForCapability:@"MWScriptLanguage"] objectEnumerator], id <MWScriptLanguage>, lang) {
    NSMenuItem *const item = [[[NSMenuItem alloc] initWithTitle:[lang localizedLanguageName] action:NULL keyEquivalent:@""] autorelease];
    [item setRepresentedObject:[lang languageIdentifier]];
    [[cScriptLanguage menu] addItem:item];
  }

  [MWOutputTextView class]; // cause initialization

  [self updateWindow];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateControlsForDefaultsNotification:) name:NSUserDefaultsDidChangeNotification
 object:nil];
  [super windowDidLoad];
}

// --- First responder quirks ---

- (void) windowWillClose:(NSNotification*)notif {
  // make sure any text field is committed if the window closes
  [[self window] makeFirstResponder:nil];
}

// --- View management ---

- (void)updateControlsForDefaultsNotification:(NSNotification *)notif {
  if (delayUpdate) {
    if (!queuedUpdate) {
      [self performSelector:@selector(updateWindow) withObject:nil afterDelay:0];
      queuedUpdate = YES;
    }
  } else {
    [self updateWindow];
  }
}

- (void)updateLanguageSelection {
  NSString *newVal = [[NSUserDefaults standardUserDefaults] stringForKey:@"MWDefaultScriptLanguageIdentifier"];
  NSEnumerator *const itemE = [[[cScriptLanguage menu] itemArray] objectEnumerator];
  NSMenuItem *item;
  while ((item = [itemE nextObject])) {
    if ([[item representedObject] isEqual:newVal]) {
      [cScriptLanguage selectItem:item];
      return;
    }
  }
  [cScriptLanguage selectItem:nil];
}

- (void)updateWindow {
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  int i;
  for (i = 0; i < [boolDefaultKeys count]; i++) {
    //NSLog(@"update %i %@ to %@ %i", i, [cSwitches cellWithTag:i], [boolDefaultKeys objectAtIndex:i], [def boolForKey:[boolDefaultKeys objectAtIndex:i]]);
    [[cSwitches cellWithTag:i] setState:[def boolForKey:[boolDefaultKeys objectAtIndex:i]]];
  }

  [cScrollLockColor setColor:[NSUnarchiver unarchiveObjectWithData:[def dataForKey:@"MWOutputTextViewScrollLockMarkerColor"]]];
  
  [cStartupAction selectCellWithTag:[def integerForKey:@"MWStartupAction"]];

  [self updateLanguageSelection];

  queuedUpdate = NO;
}

- (IBAction)cSwitchesChanged:(id)sender {
  int i;
  delayUpdate = YES;
  for (i = 0; i < [boolDefaultKeys count]; i++) {
    //NSLog(@"set %@ to %i %@ %i", [boolDefaultKeys objectAtIndex:i], i, [cSwitches cellWithTag:i], [[cSwitches cellWithTag:i] state]);
    [[NSUserDefaults standardUserDefaults] setBool:[[cSwitches cellWithTag:i] state] forKey:[boolDefaultKeys objectAtIndex:i]];
  }
  delayUpdate = NO;
}

- (IBAction)cScrollLockColorChanged:(id)sender {
  [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:[cScrollLockColor color]] forKey:@"MWOutputTextViewScrollLockMarkerColor"];
}

- (IBAction)cStartupActionChanged:(id)sender {
  [[NSUserDefaults standardUserDefaults] setInteger:[sender selectedTag] forKey:@"MWStartupAction"];
}

- (IBAction)cScriptLanguageChanged:(id)sender {
  [[NSUserDefaults standardUserDefaults] setObject:[[cScriptLanguage selectedItem] representedObject] forKey:@"MWDefaultScriptLanguageIdentifier"];
}


@end
