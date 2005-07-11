/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * <need more explanation here...>
 * 
 * These adaptors are views because: 1. their lifetime should be the same as the UI objects, and if we didn't put them in the view hierarchy they'd have to be somewhere else to be retained. (NSControls and such don't retain targets nor delegates) 2. eventually we may have per-config-item UI features, in which case this class will display them.
 * 
 * You must use the appropriate subclass of MWConfigViewAdaptor for the type of control you are using.
\*/

#import <AppKit/AppKit.h>

@class MWConfigPath, MWConfigTree, MWFontSelectorView, MWConfigPane, MWScriptPanelController;
@protocol MWConfigSupplier;

@interface MWConfigViewAdapter : NSView <NSUserInterfaceValidations> {
 @private
  MWConfigPath *basePath, *relativePath;
  id <MWConfigSupplier> configRead;
  MWConfigTree *configWrite;
  NSColor *blinking;
  id transformedInitialValue;
  void *MWConfigViewAdapter_future1;
}

/* The only difference between controlWasChangedByUser and controlChangeAction is that the second responds YES to validation, allowing it to be used with validated controls. */

- (IBAction)cvaUpdateFromConfig:(id)sender;
- (IBAction)controlWasChangedByUser:(id)sender;
- (IBAction)controlChangeAction:(id)sender;
- (IBAction)cvaReset:(id)sender;

/* Subclass implementation */
- (id)valueFromControl; // may terminate editing
- (void)setValueInControl:(id)newVal;
- (void)setControlEnabled:(BOOL)newVal;

- (MWConfigPath *)basePath;
- (MWConfigPath *)relativePath;

- (void)setBasePath:(MWConfigPath *)newVal discard:(BOOL)discard;
- (void)setRelativePath:(MWConfigPath *)newVal discard:(BOOL)discard;
- (void)setReadConfig:(id <MWConfigSupplier>)newVal;
- (void)setWriteConfig:(MWConfigTree *)newVal;

// sets readConfig and writeConfig from pane
- (void)setConfigPane:(MWConfigPane *)pane;

@end

/* Generic adaptor for objectValue/setObjectValue: plus a target/action that must be triggered when a change is made. Text fields, sliders, steppers, buttons, font selectors, etc. (the adapter will set the target and action) */
@interface MWConfigControlAdapter : MWConfigViewAdapter {
  IBOutlet NSControl *control;
}
@end

@interface MWConfigTextViewAdapter : MWConfigViewAdapter {
  IBOutlet NSTextView *control;
  BOOL writesAttributed;
}
- (BOOL)writesAttributed;
- (void)setWritesAttributed:(BOOL)newVal;
@end

@interface MWConfigScriptViewAdapter : MWConfigViewAdapter {
  NSString *languageWhileEditing;
  MWScriptPanelController *panelWC;
}

/* these methods are declared so they can be used by MWScriptPanelController. */
- (id)control;
- (NSString *)defaultLanguage;
- (NSString *)languageWhileEditing;
- (void)setLanguageWhileEditing:(NSString *)languageIdentifier;

/* for subclasses */
- (void)openScriptPanel;
- (void)closeScriptPanel;

@end

@interface MWConfigScriptTextViewAdapter : MWConfigScriptViewAdapter {
  IBOutlet NSTextView *control;
}
- (void)setControl:(NSTextView *)control;
@end

@interface MWConfigScriptTextFieldAdapter : MWConfigScriptViewAdapter {
  IBOutlet NSTextField *control;
}
- (void)setControl:(NSTextField *)control;
@end

@interface MWConfigPopupTagAdapter : MWConfigViewAdapter {
  IBOutlet NSPopUpButton *control;
  BOOL usesUnsignedNumbers;
}
- (BOOL)usesUnsignedNumbers;
- (void)setUsesUnsignedNumbers:(BOOL)newVal;
@end

@interface MWConfigPopupTagLookupAdapter : MWConfigViewAdapter {
  IBOutlet NSPopUpButton *control;
  NSDictionary *tagToObject, *objectToTag;  
}
- (void)setTagToObjectLookups:(NSDictionary *)newVal;
@end

@interface MWConfigPopupRepresentedObjectAdapter : MWConfigViewAdapter {
  IBOutlet NSPopUpButton *control;
}
@end
