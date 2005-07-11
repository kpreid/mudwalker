/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWRemoteTextHolder.h"

#import <MudWalker/MudWalker.h>
#import "MWRemoteTextWinController.h"

NSString *MWRemoteTextHolderDirtyChangedNotification = @"MWRemoteTextHolderDirtyChangedNotification";

@implementation MWRemoteTextHolder

- (MWRemoteTextHolder *)init {
  if (!(self = (MWRemoteTextHolder *)[super init])) return nil;

  rtMetadata = [[NSMutableDictionary alloc] init];
  rtStorage = [[NSTextStorage alloc] init];
  [rtStorage setDelegate:self];
  rtUndoManager = [[NSUndoManager alloc] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoManagerChangeUndone:) name:NSUndoManagerDidUndoChangeNotification object:[self undoManager]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoManagerChangeRedone:) name:NSUndoManagerDidRedoChangeNotification object:[self undoManager]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoManagerChangeDone:) name:NSUndoManagerWillCloseUndoGroupNotification object:[self undoManager]];

  return self;
}

- (void)dealloc {
  //printf("text holder %p dealloced\n", self);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [rtUndoManager autorelease]; rtUndoManager = nil;
  [delegate autorelease]; delegate = nil;
  [rtMetadata autorelease]; rtMetadata = nil;
  [rtStorage autorelease]; rtStorage = nil;
  [rtTitle autorelease]; rtTitle = nil;
  [super dealloc];
}


- (void)openView {
  MWRemoteTextWinController *wc = [[[MWRemoteTextWinController alloc] init] autorelease];
  
  [wc setTextHolder:self];
  
  [wc showWindow:nil];
}

// --- Saving ---

- (BOOL)canSave {
  return [[self delegate] respondsToSelector:@selector(remoteTextHolderShouldSave:)];
}

- (void)performSave {
  [[self delegate] remoteTextHolderShouldSave:self];
}

- (BOOL)canRefresh {
  return [[self delegate] respondsToSelector:@selector(remoteTextHolderShouldRefresh:)];
}

- (void)performRefresh {
  [[self delegate] remoteTextHolderShouldRefresh:self];
}

// --- Undo tracking ---

/* A subtle issue to note: If the change count is less than zero (implying that the text was changed, saved, then undone), and a change is performed, then the currently saved state has been lost from the undo manager. Therefore, the flag rtLostOriginalState is set, causing the document to always be dirty until saved or reverted. */

- (void)privateChangeCountChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName:MWRemoteTextHolderDirtyChangedNotification object:self userInfo:nil];
}

- (void)hasBeenSaved {
  rtChangeCount = 0;
  rtLostOriginalState = NO;
  [self privateChangeCountChanged];
}

- (void)undoManagerChangeDone:(NSNotification *)notification {
  if (rtChangeCount < 0)
    rtLostOriginalState = YES;
  else
    rtChangeCount++;
  [self privateChangeCountChanged];
}

- (void)undoManagerChangeRedone:(NSNotification *)notification {
  rtChangeCount++;
  [self privateChangeCountChanged];
}

- (void)undoManagerChangeUndone:(NSNotification *)notification {
  rtChangeCount--;
  [self privateChangeCountChanged];
}

- (BOOL)dirty { return !!rtChangeCount || rtLostOriginalState; }

// --- Accessors ---

- (NSTextStorage *)textStorage { return rtStorage; }
- (NSUndoManager *)undoManager { return rtUndoManager; }

- (id)delegate { return delegate; }
- (void)setDelegate:(id)newVal {
  [delegate autorelease];
  delegate = [newVal retain];
}
- (NSString *)title { return rtTitle; }
- (void)setTitle:(NSString *)newVal {
  [rtTitle autorelease];
  rtTitle = [newVal copy];
}
- (NSString *)string { return [[[rtStorage string] copy] autorelease]; }
- (void)setString:(NSString *)newVal {
  [rtStorage setAttributedString:[[[NSAttributedString alloc] initWithString:newVal attributes:[NSDictionary dictionaryWithObjectsAndKeys:
    [[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]], NSFontAttributeName,
    nil
  ]] autorelease]];
  // instead consider the setting of the string an undoable action ...?
  [[self undoManager] removeAllActions];
  [self hasBeenSaved];
}
- (NSMutableDictionary *)metadata { return rtMetadata; }

@end
