/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <AppKit/AppKit.h>

extern NSString *MWTextDocument_PlainType;

@interface MWTextDocument : NSDocument {
  NSTextStorage *textStorage;
  BOOL readOnly;
}

- (NSTextStorage *)textStorage;

- (void)setReadOnly:(BOOL)newVal;

@end
