/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>


@interface NSScanner (MWNSScannerAdditions)

/* Scan characters until ch is encountered, but treating all backslashes as quoting the following character. Return value indicates whether a closing quote was found, and *into is the unescaped string _regardless of the return value_. */
- (BOOL)mwScanBackslashEscapedStringUpToCharacter:(unichar)ch intoString:(NSString **)into;

- (BOOL)mwScanUpToCharactersFromSet:(NSCharacterSet *)chs possiblyQuotedBy:(unichar)ch intoString:(NSString **)into;

- (void)mwSetCharactersToBeSkippedToEmptySet;

@end
