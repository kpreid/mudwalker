/*\  
 * MudWalker Source
 * Copyright 2001-2003 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MudWalker.h>
#import <Cocoa/Cocoa.h>
#import <MWAppKit/MWExtInput.h>

@protocol MWOutputWinController <MWLinkable, NSObject>
  - (BOOL)mwHasConnection;
  /**/
  - (NSString *)outputWindowGroup;
  /**/
  - (void)setOutputWindowGroup:(NSString *)newVal;
  /**/
  - (IBAction)mwOpenConnection:(id)sender;
  - (void)askUserToUnlinkWindow;
  /* Display a sheet asking the user if it is OK to close the connection. */
  - (void)askUserToDisconnectWindowWithDelegate:(id)delegate didDisconnect:(SEL)didDisconnectSelector contextInfo:(void *)contextInfo;
  /* Like the similarly named methods in NSDocument, except that it will actually cause disconnection. */
  - (void)closeConnectionNiceWithDelegate:(id)delegate didDisconnect:(SEL)didDisconnectSelector contextInfo:(void *)contextInfo;
  /* Logout and call the selector upon disconnection */
@end

@interface MWOutputWinController : NSWindowController <MWOutputWinController, MWLinkable, NSUserInterfaceValidations, MWExtInputClient, MWHasMutableConfig> {
  IBOutlet NSView *tbCharacterView;
  IBOutlet NSMenu *tbCharacterMenu;
  IBOutlet NSPopUpButton *tbCharacterPopUp;

  id <MWConfigSupplier> configParent;
  MWConfigTree *configLocal;
  id <MWConfigSupplier> configStack;

  NSMutableDictionary *links;
  id <MWExtInputManager> extInputManager;
  NSString *windowGroup;
  NSInvocation *connectionClosedCallback;
  
  NSMutableDictionary *toolbarItems;
  
  // Full-screen feature state
  NSWindow *originalWindow;
  NSString *originalFrameName;
  NSPoint naturalShift;
  NSTrackingRectTag autohideRectTag;
}

- (id)init;
  // designated initializer

- (NSString *)outputWindowNibName;
  // for subclass implementation; name of nib file to load

- (void)configChanged:(NSNotification *)notif;
  // if overriden, must call superclass implementation

- (void)updateWindowTitle;
- (void)updateMiniwindowTitle;
- (NSString *)computeWindowTitle;
- (NSString *)computeMiniwindowTitle;
  // This is a *replacement* for the synchronizeWindowTitleWithDocumentName / windowTitleForDocumentDisplayName: system. They are called whenever a value that they depend on is changed. If overriding, you should call them as appropriate. Calling -updateWindowTitle implies -updateMiniwindowTitle.

// --- Window delegate ---

/* MWOutputWinController implements the following window delegate methods. If implementing them you should make the appropriate [super ...] call. */

- (BOOL)windowShouldClose:(NSWindow *)sender;
- (void)windowWillClose:(NSNotification *)notif;


// --- Fullscreen mode suppport ---
- (NSArray *)fullscreenEdgeRect;
  // for subclass implementation - return numbers for left,top,right,bottom portions of the window which should behave autohidely

// --- Actions ---
- (IBAction)mwOpenConnection:(id)sender;
- (IBAction)mwCloseConnectionHard:(id)sender;
- (IBAction)mwCloseConnectionNice:(id)sender;
- (IBAction)mwUnlinkWindow:(id)sender;
- (IBAction)mwSendPing:(id)sender;

- (IBAction)mwInspectFilters:(id)sender;
- (IBAction)mwSelectCharacter:(id)sender;

- (IBAction)mwFullScreenToggle:(id)sender;
- (IBAction)mwResetPrompt:(id)sender;

// --- Accessors ---

- (id <MWConfigSupplier>)config;
- (void)setConfig:(id <MWConfigSupplier>)newVal;

/* Exists solely to allow overriding by subclasses. */
- (void)setInputPrompt:(NSAttributedString *)string;

@end
