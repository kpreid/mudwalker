/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWScriptContexts stores objects script languages need to execute scripts.
 *
 * MWScriptContexts is a linkable, and has one link name: 'debug'. Messages arising from script execution are sent out this link. To allow for automatic window display, the notification MWScriptContextsWillSendDebugMessageNotification is posted beforehand.
\*/

#import <Foundation/Foundation.h>

#import "MWConcreteLinkable.h"

extern NSString *MWScriptContextsWillSendDebugMessageNotification;

@class MWLineString;

@interface MWScriptContexts : MWConcreteLinkable {
  NSMutableDictionary *contexts;
  void *MWScriptContexts_future;
}

- (id)contextForLanguageIdentifier:(NSString *)languageIdentifier;

- (void)setContext:(id)context forLanguageIdentifier:(NSString *)languageIdentifier;

- (void)postDebugMessage:(NSString *)s;

@end
