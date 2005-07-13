/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

extern NSString *MWRemoteTextHolderDirtyChangedNotification;

@interface MWRemoteTextHolder : NSObject {
  id delegate;
  NSMutableDictionary *rtMetadata;
  NSTextStorage *rtStorage;
  NSString *rtTitle;
  NSUndoManager *rtUndoManager;
 @private
  BOOL rtLostOriginalState;
  int rtChangeCount;
}

- (void)openView;
- (BOOL)canSave;
- (void)performSave;
- (BOOL)canRefresh;
- (void)performRefresh;
- (void)hasBeenSaved;

// Accessors
- (NSTextStorage *)textStorage;
- (NSUndoManager *)undoManager;

- (id)delegate;
- (void)setDelegate:(id)newVal;
- (NSString *)title;
- (void)setTitle:(NSString *)newVal;
- (NSString *)string;
- (void)setString:(NSString *)newVal;
- (NSMutableDictionary *)metadata;
- (BOOL)dirty;

@end

@interface NSObject (MWRemoteTextHolderDelegate)

- (void)remoteTextHolderShouldSave:(MWRemoteTextHolder *)sender;
- (void)remoteTextHolderShouldRefresh:(MWRemoteTextHolder *)sender;

@end
