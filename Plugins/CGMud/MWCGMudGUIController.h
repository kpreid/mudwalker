/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>
#import <MudWalker/MWConcreteLinkable.h>
#import <MWAppKit/MWOutputTextView.h>

@class MWCGMudIconsView;

@interface MWCGMudGUIController : MWConcreteLinkable {
  NSMutableDictionary *viewIdentifiers;
  NSMutableDictionary *identifierViews;
  
  MWCGMudIconsView *iconsView;
  MWOutputTextView *textView;
  unsigned scrollbackLength;
}

- (void)addView:(NSView *)newView withID:(id)newID inID:(id)outerID;

- (void)addViewIdentifier:(id)ident forView:(NSView *)view;
- (void)forgetView:(NSView *)view;
- (NSView *)viewForIdentifier:(id)ident;
- (id)identifierForView:(NSView *)view;

- (MWCGMudIconsView *)iconsView;

@end
