/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWNSScannerAdditions.h"

@implementation NSScanner (MWNSScannerAdditions)

- (BOOL)mwScanBackslashEscapedStringUpToCharacter:(unichar)ch intoString:(NSString **)into {
  NSString *quoteChar = [NSString stringWithCharacters:&ch length:1];
  unichar specialsbuf[2] = {ch, '\\'};
  NSCharacterSet *specials = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:specialsbuf length:2]];
  NSMutableString *accum = [NSMutableString string];
  NSCharacterSet *restoreSkip = [self charactersToBeSkipped];
  BOOL success = NO;
  
  [self mwSetCharactersToBeSkippedToEmptySet];
  
  while (1) {
    NSString *piece = nil;
    if ([self scanUpToCharactersFromSet:specials intoString:&piece])
      [accum appendString:piece];
    if ([self scanString:quoteChar intoString:NULL]) {
      [self setScanLocation:[self scanLocation] - 1];
      success = YES;
      break;
    } else if ([self scanString:@"\\" intoString:NULL]) {
      if ([self isAtEnd]) break;
      piece = [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
      [self setScanLocation:[self scanLocation] + 1];
      [accum appendString:piece];
    } else {
      // must be end of string
      break;
    }
  }
  *into = [[accum copy] autorelease];
  [self setCharactersToBeSkipped:restoreSkip];
  return success;
}

- (BOOL)mwScanUpToCharactersFromSet:(NSCharacterSet *)chs possiblyQuotedBy:(unichar)ch intoString:(NSString **)into {
  *into = nil;
  //NSLog(@"scanloc %i under cursor = '%c' %i  skipspace = %i  ch in = %i", [self scanLocation], [[self string] characterAtIndex:[self scanLocation]], [[self string] characterAtIndex:[self scanLocation]], [[self charactersToBeSkipped] characterIsMember:' '], [[self charactersToBeSkipped] characterIsMember:[[self string] characterAtIndex:[self scanLocation]]]);
  // this doesn't work for mysterious reasons: [self scanCharactersFromSet:[self charactersToBeSkipped] intoString:NULL];
  while ([[self charactersToBeSkipped] characterIsMember:[[self string] characterAtIndex:[self scanLocation]]])
    [self setScanLocation:[self scanLocation] + 1];

  if ([self isAtEnd]) return NO;
  if ([[self string] characterAtIndex:[self scanLocation]] == ch) {
    BOOL ret;
    [self setScanLocation:[self scanLocation] + 1];
    ret = [self mwScanBackslashEscapedStringUpToCharacter:ch intoString:into];
    if (ret) [self setScanLocation:[self scanLocation] + 1];
    return ret;
  } else {
    return [self scanUpToCharactersFromSet:chs intoString:into];
  }
}

- (void)mwSetCharactersToBeSkippedToEmptySet {
  static NSCharacterSet *emptySet = nil;
  if (!emptySet) emptySet = [[NSCharacterSet characterSetWithCharactersInString:@""] retain];
  [self setCharactersToBeSkipped:emptySet];
}

@end
