/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWDocumentSettings, MWConfigTree, MWDocumentSettingsWinController, MWScriptContexts, MWTriggerEnablePanelWinController;
@protocol MWOutputWinController, MWConfigSupplier, MWHasMutableConfig;

extern NSString *MWConnectionDocument_Type;

@interface MWConnectionDocument : NSDocument <MWHasMutableConfig, NSUserInterfaceValidations> {
  MWConfigTree *config;
  id <MWConfigSupplier> configStack;

  MWDocumentSettingsWinController *settingsWindow;
  NSMutableSet *windowFrameIdentifiersUsed;
  
  MWScriptContexts *scriptContexts;
}

- (MWConnectionDocument *)init;

- (Class)defaultOutputWindowClass;

- (NSWindowController <MWOutputWinController>  *)outputWindowOfClass:(Class)theClass group:(NSString *)group reuse:(BOOL)reuse connect:(BOOL)connect display:(BOOL)display;
/* High-level output window management method. theClass may be Nil in which case the address scheme's plugin's default output window type is used. If reuse is true then an existing unconnected window may be returned. If connect is true then it will act as if the user had performed an Open Connection action. If display is true then the window will be shown. */

- (NSString *)acquireWindowFrameAutosaveNameWithPrefix:(NSString *)prefix;
- (void)releaseWindowFrameAutosaveName:(NSString *)name;

// Actions
- (IBAction)mwOpenDocumentSettings:(id)sender;
- (IBAction)mwNewTerminal:(id)sender;
- (IBAction)mwOpenConnection:(id)sender;
- (IBAction)mwOpenServerInfo:(id)sender;
- (IBAction)mwOpenServerHelp:(id)sender;


// Accessors
- (id <MWConfigSupplier>)config;
- (MWConfigTree *)configLocalStore;

- (MWScriptContexts *)mwScriptContexts;

@end


