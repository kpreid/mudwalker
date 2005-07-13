/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWRemoteTextWinController.h"

#import "MWRemoteTextHolder.h"
#import <MWAppKit/MWToolbars.h>
#import <MudWalker/MudWalker.h>

@implementation MWRemoteTextWinController

- (MWRemoteTextWinController *)init {
  if (!(self = [super initWithWindowNibName:@"RemoteTextWindow"])) return nil;

  // this would be better if we could classify what we're editing
  [self setWindowFrameAutosaveName:@"RemoteTextWindow"];

  toolbarItems = [[NSMutableDictionary allocWithZone:[self zone]] init];
  MWTOOLBAR_ITEM(@"saveDocument", self, @selector(saveDocument:));
  MWTOOLBAR_ITEM(@"revertDocumentToSaved", self, @selector(revertDocumentToSaved:));
  MWTOOLBAR_ITEM(@"mwEditImport", self, @selector(mwEditImport:));
  MWTOOLBAR_ITEM(@"mwEditExport", self, @selector(mwEditExport:));
  MWTOOLBAR_ITEM(@"mwEditMeta", self, @selector(mwEditMeta:));
  MWTOOLBAR_ITEM(@"showGotoLineControls", nil, @selector(showGotoLineControls:));

  [self retain]; // so we don't vanish from onscreen

  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [textHolder autorelease]; textHolder = nil;
  [toolbarItems autorelease]; toolbarItems = nil;
  [super dealloc];
}

// --- Toolbar delegate ---

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  // Note that if we wanted to allow duplicate items, the items must be copied before returning. Otherwise, it's better not to.
  return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:
    @"saveDocument", @"revertDocumentToSaved",
    NSToolbarSeparatorItemIdentifier,
    @"mwEditImport", @"mwEditExport",
    NSToolbarSeparatorItemIdentifier,
    @"showGotoLineControls",
    NSToolbarFlexibleSpaceItemIdentifier,
    @"mwEditMeta",
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

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(saveDocument:)) {
    return [textHolder canSave];
  } else if (action == @selector(revertDocumentToSaved:)) {
    return [textHolder canRefresh];
  } else {
    return YES;
  }
}

- (void)updateLineNumber {
  NSToolbarItem *item = [toolbarItems objectForKey:@"showGotoLineControls"];
  NSRange lineRange = [[[[self textHolder] textStorage] string] mwLineNumbersForCharacterRange:[textView selectedRange]];

  if (lineRange.length <= 1)
    [item setLabel:[NSString stringWithFormat:@"Line: %u", lineRange.location]];
  else
    [item setLabel:[NSString stringWithFormat:@"Line: %u-%u", lineRange.location, NSMaxRange(lineRange) - 1]];
}

// --- Actions ---

- (void)saveDocument:(id)sender {
  [textHolder performSave];
}

- (void)revertDocumentToSaved:(id)sender {
  [textHolder performRefresh];
}

- (void)mwEditImport:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setTitle:NSLocalizedString(@"MWRemoteTextImportTitle", @"")];
  [oPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(importOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)importOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    [[textHolder textStorage] setAttributedString:[[[NSAttributedString alloc] initWithPath:[[sheet filenames] objectAtIndex:0] documentAttributes:NULL] autorelease]];
  }
}


- (void)mwEditExport:(id)sender {
  NSSavePanel *sPanel = [NSSavePanel savePanel];
  [sPanel setTitle:NSLocalizedString(@"MWRemoteTextExportTitle", @"")];
  [sPanel beginSheetForDirectory:nil file:[textHolder title] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(exportSavePanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)exportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    [[[[textHolder textStorage] string] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[sheet filename] atomically:YES];
  }
}


/*- (void)mwEditMeta:(id)sender {
  ...create a MWRemoteTextMetadataWinController
}*/

// --- Misc stuff ---

- (void)windowDidBecomeKey:(NSNotification *)notif {
  [[self window] makeFirstResponder:[[self window] initialFirstResponder]];
}

- (void)textViewDidChangeSelection:(NSNotification *)notif {
  [self updateLineNumber];
}

- (void)windowWillClose:(NSNotification *)notif {
  [self release];
}

- (void)updateDirty:(NSNotification *)notif {
  BOOL dirty = [textHolder dirty];
  [[self window] setDocumentEdited:dirty];
  [[[self window] toolbar] validateVisibleItems];
}

- (void)openDirtySheet {
  NSBeginAlertSheet(
    MWLocalizedStringHere(@"RemoteTextCloseConfirm_Title"),
    MWLocalizedStringHere(@"RemoteTextCloseConfirm_SaveButton"),
    MWLocalizedStringHere(@"RemoteTextCloseConfirm_DontSaveButton"),
    MWLocalizedStringHere(@"RemoteTextCloseConfirm_CancelButton"),
    [self window], /*modalDelegate:*/ self,
    /*didEndSelector:*/ nil,
    /*didDismissSelector:*/ @selector(doneDirtySheet:returnCode:contextInfo:),
    /*contextInfo:*/ NULL,
    MWLocalizedStringHere(@"RemoteTextCloseConfirm_Message")
  );
}

- (void)doneDirtySheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  switch (returnCode) {
    case NSAlertDefaultReturn: /* Send */
      [textHolder performSave];
      /* fallthru */
    case NSAlertAlternateReturn: /* Don't Send */
      [[self window] close];
      break;
    case NSAlertOtherReturn: /* Cancel */
    default:
      break;
  }
}

- (void)windowDidLoad {
  NSToolbar *toolbar;

  [[self window] setTitle:[textHolder title]];

  [[textView layoutManager] replaceTextStorage:[[self textHolder] textStorage]];
  [textView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
    [[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]], NSFontAttributeName,
    nil
  ]];
  
  toolbar = [[[NSToolbar alloc] initWithIdentifier:[[self class] description]] autorelease];
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:YES];
  [toolbar setAutosavesConfiguration:YES];
  [[self window] setToolbar:toolbar];
  
  
  [self updateLineNumber];
}

- (BOOL)windowShouldClose:(id)sender {
  if ([textHolder dirty]) {
    [self openDirtySheet];
    return NO;
  }
  return YES;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return [textHolder undoManager];
}

- (MWRemoteTextHolder *)textHolder { return textHolder; }
- (void)setTextHolder:(MWRemoteTextHolder *)newVal {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWRemoteTextHolderDirtyChangedNotification object:textHolder];

  [textHolder autorelease];
  textHolder = [newVal retain];

  [[textView layoutManager] replaceTextStorage:[[self textHolder] textStorage]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirty:) name:MWRemoteTextHolderDirtyChangedNotification object:textHolder];
  [self updateDirty:nil];
}

@end
