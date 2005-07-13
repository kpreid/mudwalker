/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWNSTextStorageAdditions.h"


@implementation NSTextStorage (MWNSTextStorageAdditions)

- (void)maintainScrollbackOfLength:(unsigned)minLength {
  const float k = 1.5;
  
  if (minLength && [self length] > (k * (float)minLength)) {
    [self replaceCharactersInRange:NSMakeRange(0, [self length] - minLength) withString:@""];
  }
}

@end
