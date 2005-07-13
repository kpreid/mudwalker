/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWOutputWinController, MWInputTextView;
@protocol MWExtInputClient, MWExtInputManager;

/* These constants are guaranteed to have these values, so you can do interesting things with them if you like */
typedef enum MWHistoryChangeType {
  MWHistoryChangeFirst = -2,
  MWHistoryChangePrev = -1,
  MWHistoryChangeNext = +1,
  MWHistoryChangeLast = +2
} MWHistoryChangeType;

@interface MWGlobalInputWinController : NSWindowController <NSUserInterfaceValidations> {
 @private
  IBOutlet NSTabView *inputTabs;
  IBOutlet NSTextView *inputTextView;
  IBOutlet NSSecureTextField *passwordField;
  
  NSWindowController <MWExtInputClient> *targetWindowController;
  NSWindow *targetWindowSheet;
  
  NSPoint targetWindowOffset;
  BOOL wasAutoMove;
  BOOL isFading;
  NSUndoManager *undoManager;
  NSMutableDictionary *toolbarItems;
}

- (IBAction)selectHistoryFirst:(id)sender;
- (IBAction)selectHistoryNext:(id)sender;
- (IBAction)selectHistoryPrev:(id)sender;
- (IBAction)selectHistoryLast:(id)sender;
- (IBAction)mwModeMain:(id)sender;
- (IBAction)mwModePassword:(id)sender;
- (IBAction)enterPassword:(id)sender;

- (void)updatePromptString:(NSNotification *)notif;
- (void)considerMainWindow;

// Input field communication methods
- (BOOL)inputTextView:(id)sender specialKeyEvent:(NSEvent *)event;
- (NSString *)inputTextView:(MWInputTextView *)sender completeString:(NSString *)str;
- (void)inputTextViewEnteredText:(id)sender shouldKeep:(BOOL)shouldKeep;
- (BOOL)inputTextView:(id)sender specialKeyEvent:(NSEvent *)event;
- (void)focusChange;

@end
