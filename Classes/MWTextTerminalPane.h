/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MWConcreteLinkable.h>
#import <AppKit/AppKit.h>
#import <MWAppKit/MWTerminalPane.h>

@class MWOutputTextView, MWTerminalPane;
@protocol MWExtInputManager, MWTerminalPaneDelegate;

@interface MWTextTerminalPane : MWTerminalPane {
  IBOutlet MWOutputTextView *mainTextView;
  IBOutlet NSScrollView *mainScrollView;

  NSString *lastLineReceived; // for window title
  BOOL hasCompleteLine;
  BOOL promptExistsInOutput;

  NSDictionary *defaultOutputAttributes;
  NSParagraphStyle *defaultParagraphStyle;
  NSArray *displayColorCache;

  NSMutableArray *statusBars; // array of NSTextFields
  NSDictionary *statusBarAttributes;
  NSFont *statusBarFont;
  
}

- (NSString *)lastLineReceived; // public till refactored
- (void)setLastLineReceived:(NSString *)str; // public till refactored
- (void)adjustAndDisplayAttributedString:(NSAttributedString *)input completeLine:(BOOL)completeLine; // public till refactored
- (unsigned)lengthOfInputSectionInTextStorage; // public till refactored

- (NSParagraphStyle *)defaultParagraphStyle; // public till refactored
- (void)setDefaultOutputAttributes:(NSDictionary *)dict; // public till refactored

- (id)lpTextWindowSize:(NSString *)link; // public till refactored

- (IBAction)mwClearScrollback:(id)sender;
- (IBAction)autoScrollLock:(id)sender;

// public till refactored
- (void)addStatusBar;
- (void)removeStatusBar;
- (void)setStatusBar:(unsigned int)index toString:(NSString *)str;

@end
