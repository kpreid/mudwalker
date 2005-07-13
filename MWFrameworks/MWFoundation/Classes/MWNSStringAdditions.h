/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * General category methods on NSString.
\*/

#import <Foundation/Foundation.h>


@interface NSString (MWNSStringAdditions)

- (NSRange)mwCharacterRangeForLineNumbers:(NSRange)lrange;
/* Given a range of line numbers (1-based) returns a range of characters from the beginning of the first line to the end of the last line, including the terminator. If lrange.length is 0 the result range's length will be 0. */

- (NSRange)mwLineNumbersForCharacterRange:(NSRange)chrange;
/* Given a range of characters, returns a range of line numbers (1-based) containing the characters. The result range's length will be 0 only if chrange's length is 0 and its location is between lines. */

- (NSArray *)componentsSeparatedByLineTerminators;
/* Like componentsSeparatedByString: but breaks on any sequence considered a line terminator. Based on -getLineStart:end:contentsEnd:forRange:. */

- (NSString *)stringWithCharactersFromSet:(NSCharacterSet *)set escapedByPrefix:(NSString *)backslash;

@end
