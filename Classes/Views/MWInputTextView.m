/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWInputTextView.h"

#import "MWGlobalInputWinController.h"

@implementation MWInputTextView

- (void)interpretKeyEvents:(NSArray *)eventArray {
  id delegate = (MWGlobalInputWinController *)[self delegate];
  NSEnumerator *eventE = [eventArray objectEnumerator];
  NSMutableArray *pass = [NSMutableArray arrayWithCapacity:[eventArray count]];
  NSEvent *event;
  while ((event = [eventE nextObject])) {
    if ([(MWGlobalInputWinController *)delegate inputTextView:self specialKeyEvent:event]) {
      [super interpretKeyEvents:pass];
      [pass removeAllObjects];
    } else {
      [pass addObject:event];
    }
  }
  [super interpretKeyEvents:pass];
}

- (void)insertTab:(id)sender {
  [(MWGlobalInputWinController *)[self delegate] focusChange];
}
- (void)insertBacktab:(id)sender {
  [(MWGlobalInputWinController *)[self delegate] focusChange];
}

- (void)insertNewline:(id)sender {
  BOOL isCR = [[[NSApp currentEvent] characters] characterAtIndex:0] == '\r';
  [(MWGlobalInputWinController *)[self delegate] inputTextViewEnteredText:self shouldKeep:!isCR];
}

- (void)complete:(id)sender {
  NSRange selection = [self selectedRange];
  NSRange toComplete = selection.length ? selection : NSMakeRange(0, selection.location);
  NSString *original = [[self string] substringWithRange:toComplete];
  NSString *new;
  if ((new = [(MWGlobalInputWinController *)[self delegate] inputTextView:self completeString:original])) {
    [[self textStorage] replaceCharactersInRange:toComplete withString:new];
  } else {
    if (![[self nextResponder] tryToPerform:@selector(complete:) with:sender]) NSBeep();
  }
}
	 
@end
