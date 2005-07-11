/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

#import <MudWalker/MWPlugin.h>

enum MWStartupAction { MWStartupOpenLibrary, MWStartupNewDocument, MWStartupNone };

@class MWGlobalInputWinController, MWLibraryWindowController, MWMudLibrary, MWPreferencesWinController, MWDocumentSettingsWinController, MWTriggerEnablePanelWinController;

@interface MWAppDelegate : NSObject <NSUserInterfaceValidations> {
  IBOutlet NSMenu *globalCommandMenu;
  IBOutlet NSMenu *terminalAccountMenu;
  IBOutlet NSMenu *libraryMenu;

  MWGlobalInputWinController *globalInputWC;
  MWLibraryWindowController *mudLibraryWC;
  MWPreferencesWinController *prefsWC;
  MWDocumentSettingsWinController *appConfigWC;
  MWMudLibrary *mudLibrary;
  BOOL disabledSound, disabledSpeech, disabledKeyMacros;
  int busyWindowCounter;
  MWTriggerEnablePanelWinController *triggerEnableWC;
}

- (void)makeDocumentForURL:(NSURL *)url connect:(BOOL)connect;

- (IBAction)newConnectionDocument:(id)sender;
- (IBAction)newTextDocument:(id)sender;

- (IBAction)showTextInput:(id)sender;
- (IBAction)showLibraryWindow:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showLinkTraceConsole:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)showMudWalkerWebSite:(id)sender;
- (IBAction)disableSound:(id)sender;
- (IBAction)disableSpeech:(id)sender;
- (IBAction)disableKeyMacros:(id)sender;
- (IBAction)synchronizeDefaults:(id)sender;

- (BOOL)disabledSound;
- (BOOL)disabledSpeech;
- (BOOL)disabledKeyMacros;
- (void)setDisabledSound:(BOOL)newVal;
- (void)setDisabledSpeech:(BOOL)newVal;
- (void)setDisabledKeyMacros:(BOOL)newVal;

- (MWMudLibrary *)mudLibrary;
- (MWGlobalInputWinController *)globalInputWinController;
- (NSMenu *)terminalAccountMenu;

@end
