/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@class MWCGMudGUIController;

@interface MWCGMudGraphicsView : NSView {
  NSPoint cursorLocation;
  NSImage *cursorImage;
  NSCachedImageRep *backingImageRep;
  MWCGMudGUIController *delegate;
  NSMutableDictionary *regions;
}

- (void)lockFocusForModification;
- (void)unlockFocusForModification;

- (void)setCursorImage:(NSImage *)image;
- (void)setCursorLocation:(NSPoint)loc;

- (NSMutableDictionary *)regions;
- (MWCGMudGUIController *)delegate;
- (void)setDelegate:(MWCGMudGUIController *)obj;


@end
