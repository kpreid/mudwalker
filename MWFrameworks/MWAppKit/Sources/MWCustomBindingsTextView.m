/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCustomBindingsTextView.h"

@implementation MWCustomBindingsTextView

// replace this with a custom keybinding dictionary once Apple makes an API for doing so public.

- (void)interpretKeyEvents:(NSArray *)eventArray {
  NSEnumerator *eventE = [eventArray objectEnumerator];
  NSMutableArray *pass = [NSMutableArray arrayWithCapacity:[eventArray count]];
  NSEvent *event;
  while ((event = [eventE nextObject])) {
    int character = [[event charactersIgnoringModifiers] characterAtIndex:0];
    int modifiers = [event modifierFlags];
    SEL sel = 0;
    switch (character) {
      case '\r': // return key
        if ([event modifierFlags] & NSShiftKeyMask) {
          //printf("shift-return\n");
          sel = @selector(insertNewlineIgnoringFieldEditor:);
        }
        break;
        
      // for TF-ies
      case 'p': case 'P':
        if (modifiers & NSControlKeyMask)
          sel = @selector(selectHistoryPrev:);
        break;
      case 'n': case 'N':
        if (modifiers & NSControlKeyMask)
          sel = @selector(selectHistoryNext:);
        break;
      case 'u': case 'U':
        if (modifiers & NSControlKeyMask)
          sel = @selector(deleteAllText:);
        break;
      
      case NSUpArrowFunctionKey:
        if (modifiers & NSCommandKeyMask) {
          //printf("upward history move\n");
          sel = modifiers & NSAlternateKeyMask
            ? @selector(selectHistoryFirst:)
            : @selector(selectHistoryPrev:);
        }
        break;
            
      case NSDownArrowFunctionKey:
        if (modifiers & NSCommandKeyMask) {
          //printf("downward history move\n");
          sel = modifiers & NSAlternateKeyMask
            ? @selector(selectHistoryLast:)
            : @selector(selectHistoryNext:);
        }
        break;
        
      case NSPrevFunctionKey:
        sel = @selector(selectHistoryPrev:);
        break;
        
      case NSNextFunctionKey:
        sel = @selector(selectHistoryNext:);
        break;
        
      case NSScrollLockFunctionKey:
      case NSF14FunctionKey:
        sel = @selector(autoScrollLock:);
        break;
        
      default:
        break;
    }
    if (sel) {
      [super interpretKeyEvents:pass];
      [pass removeAllObjects];
      [self tryToPerform:sel with:nil];
    } else {
      [pass addObject:event];
    }
  }
  [super interpretKeyEvents:pass];
}

- (IBAction)deleteAllText:(id)sender {
  [self selectAll:sender];
  [self deleteBackward:sender];
}

@end
