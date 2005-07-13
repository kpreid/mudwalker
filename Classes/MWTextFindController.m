/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * Structure (and some code) of this implementation is based on the TextFinder class in the TextEdit source.
\*/

#import "MWTextFindController.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWValidatedButton.h>
#import "MWGlobalInputWinController.h"

static MWTextFindController *sharedInstance = nil;

@interface NSString (MWStringTextFinding)

- (NSRange)mwFindString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)mask wrap:(BOOL)wrapFlag;

@end

@interface MWTextFindController (Private)

- (NSString *)findString;
- (void)setFindString:(NSString *)string;
- (void)setFindString:(NSString *)string writeToPasteboard:(BOOL)doWrite;
- (NSString *)replaceString;
- (void)setReplaceString:(NSString *)string;

- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

- (void)updateFromFields;
- (void)performFind:(MWCursorMotionAction)direction;

- (void)updateControls;

@end

@implementation MWTextFindController

// --- initialization ---

// Slightly different than our other 'pseudo-singleton' classes since we want to instantiate it from a nib file, so the shared instance must be stashed in -init:.

+ (MWTextFindController *)sharedInstance { return sharedInstance ? sharedInstance : [[[self alloc] init] autorelease]; }

- (id)init {
  if (sharedInstance) { [super dealloc]; return sharedInstance; }
  if (!(self = [self initWithWindowNibName:@"TextFindWindow"])) return nil;
  
  [self setWindowFrameAutosaveName:@"TextFind"];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoSetTarget:) name:NSWindowDidBecomeKeyNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoSetTarget:) name:NSWindowWillCloseNotification object:nil];

  [self setFindString:@"" writeToPasteboard:NO];
  [self loadFindStringFromPasteboard];
  replaceString = [@"" retain];
  
  sharedInstance = self;
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [originalWindowTitle release]; originalWindowTitle = nil;
  [findString release]; findString = nil;
  [replaceString release]; replaceString = nil;
  [targetWindow autorelease]; targetWindow = nil;
  [super dealloc];
}

- (void)windowDidLoad {
  [findField setStringValue:[self findString]];
  [replaceField setStringValue:[self replaceString]];
  [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
  originalWindowTitle = [[[self window] title] copy];

  [super windowDidLoad];
}

- (void)windowDidResignKey:(NSNotification *)notif {
  [self updateFromFields];
}

- (IBAction)showWindow:(id)sender {
  [[self window] makeFirstResponder:findField];
  [[self window] makeKeyAndOrderFront:nil];
}

// --- Utilities ---

- (void)autoSetTarget:(NSNotification *)notif {
  NSWindow *win = [notif object];
  
  
  if ([[notif name] isEqual:NSWindowDidBecomeKeyNotification] && win != [self window] && ![[win delegate] isKindOfClass:[MWGlobalInputWinController class]] && ![win isSheet]) {
    [targetWindow autorelease];
    targetWindow = [win retain];
  } else if ([[notif name] isEqual:NSWindowWillCloseNotification] && win == targetWindow) {
    [targetWindow autorelease];
    targetWindow = nil;
  }
  [self updateControls];
}

- (NSTextView *)target {
  NSResponder *t = [targetWindow firstResponder];
  return [t isKindOfClass:[NSTextView class]] ? (NSTextView *)t : nil;
}

- (void)updateFromFields {
  [[self window] makeFirstResponder:nil];
  [self setFindString:[findField stringValue]];
  [self setReplaceString:[replaceField stringValue]];
}

// --- Find string and pasteboard management ---

- (NSString *)findString {
  return findString;
}

- (void)setFindString:(NSString *)string {
  [self setFindString:string writeToPasteboard:YES];
}

- (void)setFindString:(NSString *)string writeToPasteboard:(BOOL)doWrite {
  if ([string isEqualToString:findString]) return;
  [findString autorelease];
  findString = [string copyWithZone:[self zone]];
  [findField setStringValue:string];
  [findField selectText:nil];
  if (doWrite) [self loadFindStringToPasteboard];
}

- (NSString *)replaceString {
  return replaceString;
}

- (void)setReplaceString:(NSString *)string {
  [replaceString autorelease];
  replaceString = [string copyWithZone:[self zone]];
  [replaceField setStringValue:string];
}

- (void)appDidActivate:(NSNotification *)notif {
  [self loadFindStringFromPasteboard];
}

- (void)loadFindStringFromPasteboard {
  NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
  if ([[pasteboard types] containsObject:NSStringPboardType]) {
    NSString *string = [pasteboard stringForType:NSStringPboardType];
    if (string && [string length]) {
      [self setFindString:string writeToPasteboard:NO];
    }
  }
}

- (void)loadFindStringToPasteboard {
  NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
  [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
  [pasteboard setString:[self findString] forType:NSStringPboardType];
}

// --- Find engine ---

- (void)performFind:(MWCursorMotionAction)direction {
  NSTextView *text = [self target];
  lastFindWasSuccessful = NO;
  if (text) {
    NSString *textContents = [text string];
    unsigned textLength = [textContents length];
    if (textLength) {
        NSRange range;
        unsigned options = 0;
        if (direction < 0) options |= NSBackwardsSearch;
        if ([ignoreCaseBtn state]) options |= NSCaseInsensitiveSearch;
        range = [textContents mwFindString:[self findString] selectedRange:[text selectedRange] options:options wrap:YES];
        if (range.length) {
          [text setSelectedRange:range];
          [text scrollRangeToVisible:range];
          lastFindWasSuccessful = YES;
        }
    }
  }
  if (!lastFindWasSuccessful) NSBeep();
}


// --- Actions ---

- (IBAction)useSelectionForFind:(id)sender {
  NSTextView *target = [self target];
  [self setFindString:[[[target textStorage] string] substringWithRange:[target selectedRange]]];
}

- (IBAction)findNext:(id)sender {
  [self updateFromFields];
  [self performFind:MWCursorMotionNext];
}
- (IBAction)findNextOnce:(id)sender {
  [findNextBtn performClick:nil];
  if (lastFindWasSuccessful) {
    [[self window] orderOut:sender];
  } else {
    [findField selectText:nil];
  }
}
- (IBAction)findPrevious:(id)sender {
  [self updateFromFields];
  [self performFind:MWCursorMotionPrev];
}

- (IBAction)replaceFound:(id)sender {
   NSTextView *text = [self target];
  [self updateFromFields];
  // shouldChangeTextInRange:... should return NO if !isEditable, but doesn't...
  if (text && [text isEditable] && [text shouldChangeTextInRange:[text selectedRange] replacementString:[self replaceString]]) {
    [[text textStorage] replaceCharactersInRange:[text selectedRange] withString:[self replaceString]];
    [text didChangeText];
  } else {
    NSBeep();
  }
}
- (IBAction)replaceAndFind:(id)sender {
  [self replaceFound:sender];
  [self findNext:sender];
}
- (IBAction)replaceAll:(id)sender {
  [self updateFromFields];
  NSBeep();
}

// --- Goto ---

- (IBAction)showGotoLineControls:(id)sender {
  [self showWindow:sender];
  [[self window] makeFirstResponder:gotoField];
}

- (IBAction)gotoPerform:(id)sender {
  NSTextView *text = [self target];
  int specPos = [gotoField intValue];
  NSRange charPos;
  
  switch ([gotoModeRadio selectedTag]) {
    case 0: /* line */
      charPos = [[[text textStorage] string] mwCharacterRangeForLineNumbers:NSMakeRange(specPos, 1)];
      break;
    case 1: /* character */
      charPos = NSMakeRange(specPos, 1);
      break;
    default:
      NSLog(@"%@ can't happen: [gotoModeRadio selectedTag] has bad value: %i", self, [gotoModeRadio selectedTag]);
      NSBeep();
      lastGotoWasSuccessful = NO;
      return; 
  }
  
  if (charPos.location < 0 || NSMaxRange(charPos) > [[text textStorage] length]) {
    NSBeep();
    lastGotoWasSuccessful = NO;
  } else {
    [text setSelectedRange:charPos];
    [text scrollRangeToVisible:charPos];
    lastGotoWasSuccessful = YES;
  }
}
- (IBAction)gotoPerformOnce:(id)sender {
  [gotoBtn performClick:nil];
  if (lastGotoWasSuccessful) {
    [[self window] orderOut:sender];
  } else {
    [gotoField selectText:nil];
  }
}

// --- Validation ---

- (void)updateControls {
  NSString *targetText = [[self target] string];
  NSString *sampleText = targetText ? [NSString stringWithFormat:@": \"%@...\"", [targetText substringWithRange:NSMakeRange(0, [targetText length] > 20 ? 20 : [targetText length])]] : @"";
  [[self window] setTitle:targetWindow ? [NSString stringWithFormat:@"%@: %@%@", originalWindowTitle, [targetWindow title], sampleText] : originalWindowTitle];
  [findNextBtn validate];
  [findPrevBtn validate];
  [replaceBtn validate];
  [replaceAndFindBtn validate];
  [replaceAllBtn validate];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  //NSLog(@"validating %@ in tfc", item);
  if (action == @selector(useSelectionForFind:)) {
    return !![self target];
  } else if (action == @selector(showGotoLineControls:)) {
    return !![self target];
  } else if (action == @selector(findNext:) || action == @selector(findNextOnce:) || action == @selector(findPrevious:) || action == @selector(gotoPerform:) || action == @selector(gotoPerformOnce:)) {
    return !![self target];
  } else if (action == @selector(replaceFound:) || action == @selector(replaceAndFind:) || action == @selector(replaceAll:)) {
    NSTextView *text = [self target];
    return (text && [text isEditable]);
  } else {
    return YES;
  }
}

// ---

@end

// Yick. This should not really be a category. (borrowed from TextEdit)

@implementation NSString (MWStringTextFinding)

- (NSRange)mwFindString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap {
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
	    searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
     searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}        

@end
