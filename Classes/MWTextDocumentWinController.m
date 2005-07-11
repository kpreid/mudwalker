/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTextDocumentWinController.h"
#import "MWTextDocument.h"

@implementation MWTextDocumentWinController

- (id)init {
  if (!(self = [super initWithWindowNibName:@"TextDocument"])) return self;
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)windowDidLoad {
  [[textView layoutManager] replaceTextStorage:[(MWTextDocument *)[self document] textStorage]];
  [super windowDidLoad];
}

// ---

- (void)windowDidBecomeKey:(NSNotification *)notif {
  // IB initialFirstResponder outlet doesn't actually work
  [[self window] makeFirstResponder:textView];
}

- (void)windowDidBecomeMain:(NSNotification *)notif {
  [[self window] makeFirstResponder:textView];
}

// ---

- (void)setReadOnly:(BOOL)newVal {
  [textView setEditable:!newVal];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
  return [[self document] undoManager];
}

@end
