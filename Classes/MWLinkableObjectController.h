/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MudWalker.h>
#import <Cocoa/Cocoa.h>

@class MWLinkableInspectorWinController;

@interface MWLinkableObjectController : NSObject {
  id <MWLinkable>target;
  
  NSTextStorage *traceLog;
  NSArray *configurationOrdering;
  NSDictionary *configurationCache;
}

+ (MWLinkableObjectController *)locWithLinkable:(id <MWLinkable>)targ;
- (MWLinkableObjectController *)initWithLinkable:(id <MWLinkable>)targ;

- (id <MWLinkable>)target;
- (NSTextStorage *)traceStorage;

- (void)lnTrace:(NSNotification *)notif; // oog

//- (NSArray *)lConfigurationOrdering;
//- (NSDictionary *)lConfigurationCached;
//- (void)refreshConfiguration;

- (void)openView;
- (void)openViewBesideWindow:(NSWindow *)win;

@end
