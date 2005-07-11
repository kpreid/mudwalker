/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWAddressEntryWinController.h"

#import <MudWalker/MudWalker.h>

#import "MWAppDelegate.h"
#import "MWMudLibrary.h"
#import "MWLibraryItem.h"

#import "MWConnectionDocument.h"

@implementation MWAddressEntryWinController

- (id)init {
  if (!(self = [super initWithWindowNibName:@"ConnectByAddress"])) return self;
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:[[self document] config]];
  [super dealloc];
}

- (IBAction)openSettingsWindow:(id)sender {
  [(MWConnectionDocument *)[self document] mwOpenDocumentSettings:sender];
}

- (IBAction)performConnect:(id)sender {
  NSURL *url = [entryComboBox objectValue];

  if (!url) {
    NSBeep();
    return;
  }

  if ([[self window] firstResponder] != entryComboBox || [[self window] makeFirstResponder:nil]) {
  
    NSDocument *doc = [self document];

    if (doc && [doc respondsToSelector:@selector(configLocalStore)]) {
      const BOOL keep_clean = ![doc fileName] && ![doc isDocumentEdited];
      
      if (keep_clean) [[doc undoManager] disableUndoRegistration];
      [[(MWConnectionDocument *)doc configLocalStore] setObject:url atPath:[MWConfigPath pathWithComponent:@"Address"]];
      if (keep_clean) [[doc undoManager] enableUndoRegistration];
      
      [(MWConnectionDocument *)doc outputWindowOfClass:nil group:@"main" reuse:NO connect:YES display:YES];
      
    } else {
  
      [(MWAppDelegate *)[NSApp delegate] makeDocumentForURL:url connect:YES];
    }

    [[self window] performClose:nil];
  }  
}

// --- Document ---

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];
  
  if (!path || [path isEqual:[MWConfigPath pathWithComponent:@"Address"]]) {
    [self window];
    [entryComboBox setObjectValue:[[[(MWConnectionDocument *)[self document] config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]] absoluteString]];
  }
}

- (void)setDocument:(NSDocument *)doc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:[(MWConnectionDocument *)doc config]];

  [super setDocument:doc];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:[(MWConnectionDocument *)doc config]];

  [self configChanged:[NSNotification notificationWithName:MWConfigSupplierChangedNotification object:[(MWConnectionDocument *)doc config]]];
}

// --- Combo box data source ---

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString {
  MWMudLibrary *lib = [(MWAppDelegate *)[NSApp delegate] mudLibrary];
  int i, max = [lib libItemNumberOfChildren];
  for (i = 0; i < max; i++) {
    MWLibraryAddressItem *const item = [lib libItemChildAtIndex:i];
    NSURL *url = [item serverURL];
    NSString *s;
    if ([(s = [url absoluteString]) hasPrefix:uncompletedString])
      return s;
    if ([(s = [NSString stringWithFormat:@"%@:%@", [url host], [url port]]) hasPrefix:uncompletedString] && [[url scheme] isEqualToString:@"telnet"])
      return s;
  }
  return nil;
}

- (unsigned int)comboBox:(NSComboBox *)sender indexOfItemWithStringValue:(NSString *)aString {
  MWMudLibrary *lib = [(MWAppDelegate *)[NSApp delegate] mudLibrary];
  int i, max = [lib libItemNumberOfChildren];
  for (i = 0; i < max; i++) {
    if ([[self comboBox:sender objectValueForItemAtIndex:i] isEqualToString:aString])
      return i;
  }
  return NSNotFound;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index {
  MWMudLibrary *lib = [(MWAppDelegate *)[NSApp delegate] mudLibrary];
  MWLibraryAddressItem *const item = [lib libItemChildAtIndex:index];
  NSURL *url = [item serverURL];
  if ([[url scheme] isEqualToString:@"telnet"])
    return [NSString stringWithFormat:@"%@:%@", [url host], [url port]];
  else
    return [url absoluteString];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
  MWMudLibrary *lib = [(MWAppDelegate *)[NSApp delegate] mudLibrary];
  return [lib libItemNumberOfChildren];
}

- (IBAction)showWindow:(id)sender {
  [entryComboBox reloadData];
  [super showWindow:nil];
}

@end
