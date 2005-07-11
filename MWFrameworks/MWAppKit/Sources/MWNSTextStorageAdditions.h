/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * 
\*/

#import <AppKit/NSTextStorage.h>

@interface NSTextStorage (MWNSTextStorageAdditions)

- (void)maintainScrollbackOfLength:(unsigned)minLength;
  /* When the text reaches k*minLength characters, the beginning will be cut off such that it is equal to minLength. k will be no more than 2.0. Does nothing if minLength is 0. */

@end
