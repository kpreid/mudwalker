/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWOutputTextView.h"

#import "MWExtInput.h"

static BOOL eventRedirectRecurse = NO;

@implementation MWOutputTextView

+ (void)initialize {
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:1 green:0.5 blue:0 alpha:0.5]], @"MWOutputTextViewScrollLockMarkerColor",
    nil
  ]];

}

// ---

- (IBAction)autoScrollLock:(id)sender {
  [self setAutoScrollLock:![self autoScrollLock]];
}

- (IBAction)toggleShowsControlCharacters:(id)sender {
  [[self layoutManager] setShowsControlCharacters:![[self layoutManager] showsControlCharacters]];
}

// --- 

- (BOOL)shouldDrawInsertionPoint { return NO; }

- (void)drawRect:(NSRect)rect {
  [super drawRect:rect];
  if ([self autoScrollToEnd] && [self autoScrollLock]) {
    NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"MWOutputTextViewScrollLockMarkerColor"]];
    if (!color) color = [NSColor grayColor];
    [color set];
    [NSBezierPath setDefaultLineWidth:4];
    [NSBezierPath strokeRect:NSInsetRect([self bounds], 2, 2)];
  }
}

- (void)performScrollToEnd {
  NSClipView *const clipView = (NSClipView *)[self superview];
  //NSLog(@"performScrollToEnd");
  if (![clipView isKindOfClass:[NSClipView class]]) return;
  [clipView scrollToPoint:[clipView constrainScrollPoint:NSMakePoint(0,[self frame].size.height)]];
  [[clipView superview] reflectScrolledClipView:clipView];
}

- (void)layoutManager:(NSLayoutManager *)aLayoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer atEnd:(BOOL)flag {
  unsigned length = [[self textStorage] length];
  //NSLog(@"layout done, flag %i lengthN %u lengthP %u ase %i asl %i", flag, length, lastAutoscrollTextLength, autoScroll, autoScrollLock);
  if (
    flag
    && length != lastAutoscrollTextLength
    && [self autoScrollToEnd]
    && ![self autoScrollLock]
  )
    [self performScrollToEnd];
  lastAutoscrollTextLength = length;
}

- (BOOL)changeFocus {
  NSWindowController *const wc = [[self window] windowController];
  
  id <MWExtInputManager> const eim = [wc conformsToProtocol:@protocol(MWExtInputClient)]
    ? [(id<MWExtInputClient>)wc extInputManager]
    : nil;
  
  if (!eim || ![eim isActive]) {
    NSBeep();
    return NO;
  }
  [eim makeKey];
  // FIXME: check if we actually lost focus
  return YES;
}

- (void)myForwardInput:(id)sender selector:(SEL)sel {
  if (eventRedirectRecurse) { NSBeep(); return; }
  
  if (![self changeFocus]) return;
  
  NS_DURING
    eventRedirectRecurse = YES;
    [NSApp sendAction:sel to:nil from:sender];
  NS_HANDLER
    eventRedirectRecurse = NO;
    [localException raise];
  NS_ENDHANDLER
  eventRedirectRecurse = NO;
}

#define CHANGE(sel) - (void)sel(id)sender { [self changeFocus]; }
#define FORWARD_INPUT(sel) - (void)sel(id)sender { [self myForwardInput:sender selector:@selector(sel)]; }

FORWARD_INPUT(insertText:);

FORWARD_INPUT(cut:);
// keep copy:
FORWARD_INPUT(paste:);
FORWARD_INPUT(clear:);
FORWARD_INPUT(undo:);

FORWARD_INPUT(moveForward:);
FORWARD_INPUT(moveRight:);
FORWARD_INPUT(moveBackward:);
FORWARD_INPUT(moveLeft:);
FORWARD_INPUT(moveUp:);
FORWARD_INPUT(moveDown:);
FORWARD_INPUT(moveWordForward:);
FORWARD_INPUT(moveWordBackward:);
FORWARD_INPUT(moveToBeginningOfLine:);
FORWARD_INPUT(moveToEndOfLine:);
FORWARD_INPUT(moveToBeginningOfParagraph:);
FORWARD_INPUT(moveToEndOfParagraph:);
// keep pageDown: pageUp: centerSelectionInVisibleArea:

FORWARD_INPUT(moveForwardAndModifySelection:);
FORWARD_INPUT(moveBackwardAndModifySelection:);
FORWARD_INPUT(moveWordForwardAndModifySelection:);
FORWARD_INPUT(moveWordBackwardAndModifySelection:);
FORWARD_INPUT(moveUpAndModifySelection:);
FORWARD_INPUT(moveDownAndModifySelection:);

FORWARD_INPUT(transpose:);
FORWARD_INPUT(transposeWords:);

FORWARD_INPUT(indent:);
CHANGE(insertTab:);
CHANGE(insertBacktab:);
FORWARD_INPUT(insertNewline:);
FORWARD_INPUT(insertParagraphSeparator:);
FORWARD_INPUT(insertNewlineIgnoringFieldEditor:);
FORWARD_INPUT(insertTabIgnoringFieldEditor:);

FORWARD_INPUT(changeCaseOfLetter:);
FORWARD_INPUT(uppercaseWord:);
FORWARD_INPUT(lowercaseWord:);
FORWARD_INPUT(capitalizeWord:);

FORWARD_INPUT(deleteForward:);
FORWARD_INPUT(deleteBackward:);
FORWARD_INPUT(deleteWordForward:);
FORWARD_INPUT(deleteWordBackward:);
FORWARD_INPUT(deleteToBeginningOfLine:);
FORWARD_INPUT(deleteToEndOfLine:);
FORWARD_INPUT(deleteToBeginningOfParagraph:);
FORWARD_INPUT(deleteToEndOfParagraph:);

FORWARD_INPUT(yank:);
FORWARD_INPUT(yankAndModifySelection:);

FORWARD_INPUT(complete:);

FORWARD_INPUT(setMark:);
FORWARD_INPUT(deleteToMark:);
FORWARD_INPUT(selectToMark:);
FORWARD_INPUT(swapWithMark:);

// MW custom action methods
FORWARD_INPUT(selectHistoryFirst:);
FORWARD_INPUT(selectHistoryPrev:);
FORWARD_INPUT(selectHistoryNext:);
FORWARD_INPUT(selectHistoryLast:);
#undef CHANGE
#undef FORWARD_INPUT

// ---


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(autoScrollLock:)) {
    if ([(id <NSObject>)item isKindOfClass:[NSMenuItem class]]) {
      [(NSMenuItem *)item setState:(![self autoScrollToEnd] || [self autoScrollLock]) ? NSOnState : NSOffState];
    }
    return [self autoScrollToEnd];
  } else if (action == @selector(toggleShowsControlCharacters:)) {
    if ([(id <NSObject>)item isKindOfClass:[NSMenuItem class]]) {
      [(NSMenuItem *)item setState:[[self layoutManager] showsControlCharacters] ? NSOnState : NSOffState];
    }
    return YES;
  } else {
    // NSTextView does not conform to NSUserInterfaceValidations
    //return [super validateUserInterfaceItem:item];
    return YES;
  }
}

// --- Accessors ---

- (BOOL)autoScrollToEnd { return autoScroll; }
- (void)setAutoScrollToEnd:(BOOL)newVal {
  if (autoScroll == newVal) return;

  autoScroll = newVal;

  [self setNeedsDisplay:YES];
  [[self layoutManager] setDelegate:autoScroll ? self : nil];
  if (autoScroll && ![self autoScrollLock]) [self performScrollToEnd];
}

- (BOOL)autoScrollLock { return autoScrollLock; }
- (void)setAutoScrollLock:(BOOL)newVal {
  if (autoScrollLock == newVal) return;

  autoScrollLock = newVal;

  [self setNeedsDisplay:YES];
}

@end
