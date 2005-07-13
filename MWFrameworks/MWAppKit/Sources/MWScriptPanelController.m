/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWScriptPanelController.h"

#import <MudWalker/MWRegistry.h>
#import <MudWalker/MWScriptLanguage.h>
#import "MWConfigViewAdapter.h"
#import "MWValidatedButton.h"

@interface MWScriptPanelController (FakeCategoryJustToDeclareTheMethodReturnType)

- (MWScriptContexts *)mwScriptContexts;

@end

@implementation MWScriptPanelController

- (void)windowDidLoad {
  [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];

  [languagePopUp removeAllItems];
  
  NSEnumerator *const langE = [[[MWRegistry defaultRegistry] allHandlersForCapability:@"MWScriptLanguage"] objectEnumerator];
  id <MWScriptLanguage> lang;
  while ((lang = [langE nextObject])) {
    NSMenuItem *const item = [[[NSMenuItem alloc] initWithTitle:[lang localizedLanguageName] action:NULL keyEquivalent:@""] autorelease];
    [item setRepresentedObject:[lang languageIdentifier]];
    [[languagePopUp menu] addItem:item];
  }

  [super windowDidLoad];
}

- (IBAction)changeLanguage:(id)sender {
  [target setLanguageWhileEditing:[[languagePopUp selectedItem] representedObject]];
}

- (void)updateLanguage {
  [self window]; // force outlet connection

  NSString *newVal = [target languageWhileEditing];
  NSEnumerator *const itemE = [[[languagePopUp menu] itemArray] objectEnumerator];
  NSMenuItem *item;
  while ((item = [itemE nextObject])) {
    if ([[item representedObject] isEqual:newVal]) {
      [languagePopUp selectItem:item];
      return;
    }
  }
  [languagePopUp selectItem:nil];
}

- (void)updateErrors {
  [self window]; // force outlet connection

  id <MWScriptLanguage> const language = [[MWRegistry defaultRegistry] handlerForCapability:[NSArray arrayWithObjects:@"MWScriptLanguage", [target languageWhileEditing], nil]];

  NSString *const errors = [language syntaxErrorsInScript:[target valueFromControl] contexts:[[[[target window] windowController] document] mwScriptContexts] /* FIXME: better way to get contexts obj, or maybe we want to create one just for the purpose */ location:@""];

  [errorView setString:errors ? errors : @""];

  [saveButton validate];
  [revertButton validate];
}

- (void)setTarget:(MWConfigScriptViewAdapter *)newVal {
  
  target = newVal;
  
  [self window];
  [revertButton setTarget:target];
  [saveButton setTarget:target];

  [self updateLanguage];
  [self updateErrors];
  
  {
    NSSize const mySize = [[self window] frame].size;
    
    NSView *const targetView = [[target control] enclosingScrollView];
    
    NSWindow *const targetWindow = [target window];
    NSRect const targetWindowFrame = [targetWindow frame];
    NSRect const targetScreenFrame = [[targetWindow screen] visibleFrame];
    NSRect const targetViewFrame = NSOffsetRect([targetView convertRect:[targetView bounds] toView:nil], targetWindowFrame.origin.x, targetWindowFrame.origin.y);
    
    BOOL const fitsOnLeft = mySize.width <= NSMinX(targetViewFrame) - NSMinX(targetScreenFrame);
    BOOL const fitsOnRight = mySize.width <= NSMaxX(targetScreenFrame) - NSMaxX(targetViewFrame);
    
    float chosenOriginX;
    
    if (fitsOnRight || !fitsOnLeft) {
      chosenOriginX = MIN(NSMaxX(targetScreenFrame) - mySize.width, NSMaxX(targetWindowFrame) + 1);
    } else {
      chosenOriginX = MAX(NSMinX(targetScreenFrame), NSMinX(targetWindowFrame) - mySize.width - 1);
    }

    float chosenOriginY = NSMidY(targetViewFrame) - mySize.height / 2;
    
    chosenOriginY = MIN(chosenOriginY, NSMaxY(targetScreenFrame) - mySize.height);
    chosenOriginY = MAX(chosenOriginY, NSMinY(targetScreenFrame));

    [[self window] setFrameOrigin:NSMakePoint(chosenOriginX, chosenOriginY)];
  }
}

@end
