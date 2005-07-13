/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWNSStringAdditions.h"
#import "MWNSScannerAdditions.h"
#import "MWUtilities.h"

@implementation NSString (MWNSStringAdditions)

- (NSRange)mwCharacterRangeForLineNumbers:(NSRange)lrange {
  const SEL getlinesel = @selector(getLineStart:end:contentsEnd:forRange:);
  void (*const getline)(id, SEL, unsigned *, unsigned *, unsigned *, NSRange) = (void (*)(id, SEL, unsigned *, unsigned *, unsigned *, NSRange))[self methodForSelector:getlinesel];
  const unsigned myLength = [self length];

  unsigned startIndex, lineEndIndex;
  NSRange cursor = NSMakeRange(0, 0);
  int specPos = lrange.location;
  NSRange chrange;

  while (NSMaxRange(cursor) <= myLength && specPos > 0) {
    getline(self, getlinesel, &startIndex, &lineEndIndex, NULL, cursor);
    specPos--;
    cursor = NSMakeRange(lineEndIndex, 1);
  }
  if (specPos > 0) {
    chrange = NSMakeRange(myLength, 0);
    return chrange;
  } else {
    chrange = NSMakeRange(startIndex, 0);
  }
  
  specPos = lrange.length;
  cursor = chrange;
  while (NSMaxRange(cursor) <= myLength && specPos > 0) {
    getline(self, getlinesel, &startIndex, &lineEndIndex, NULL, cursor);
    specPos--;
    cursor = NSMakeRange(lineEndIndex, 1);
  }
  chrange.length = lineEndIndex - chrange.location;
  return chrange;
}

- (NSRange)mwLineNumbersForCharacterRange:(NSRange)chrange {
  const SEL getlinesel = @selector(getLineStart:end:contentsEnd:forRange:);
  void (*const getline)(id, SEL, unsigned *, unsigned *, unsigned *, NSRange) = (void (*)(id, SEL, unsigned *, unsigned *, unsigned *, NSRange))[self methodForSelector:getlinesel];
  const unsigned myLength = [self length];

  unsigned startIndex = 0, lineEndIndex = 0;
  NSRange cursor = NSMakeRange(0, 0);
  unsigned linesSeen = 0;
  NSRange lrange;

  while (NSMaxRange(cursor) <= myLength && lineEndIndex <= chrange.location) {
    getline(self, getlinesel, &startIndex, &lineEndIndex, NULL, cursor);
    linesSeen++;
    cursor = NSMakeRange(lineEndIndex, 1);
  }
  lrange.location = linesSeen;
  
  startIndex = lineEndIndex;
  while (NSMaxRange(cursor) <= myLength && startIndex < NSMaxRange(chrange)) {
    getline(self, getlinesel, &startIndex, &lineEndIndex, NULL, cursor);
    linesSeen++;
    cursor = NSMakeRange(lineEndIndex, 1);
  }
  if (NSMaxRange(cursor) > myLength && lineEndIndex == myLength) linesSeen++;
  
  lrange.length = linesSeen - lrange.location;
  return lrange;
}

- (NSArray *)componentsSeparatedByLineTerminators {
  unsigned startIndex, lineEndIndex, contentsEndIndex;
  NSRange cursor = NSMakeRange(0, 0);
  NSMutableArray *out = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
  
  while (NSMaxRange(cursor) <= [self length]) {
    [self getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:cursor];
    [out addObject:[self substringWithRange:MWMakeABRange(startIndex, contentsEndIndex)]];
    cursor = NSMakeRange(lineEndIndex, 1);
  }
  return [[out copyWithZone:[self zone]] autorelease];
}

- (NSString *)stringWithCharactersFromSet:(NSCharacterSet *)set escapedByPrefix:(NSString *)backslash {
  NSScanner *scan = [NSScanner scannerWithString:self];
  NSMutableString *outs = [NSMutableString string];
  
  [scan mwSetCharactersToBeSkippedToEmptySet];

  while (![scan isAtEnd]) {
    NSString *part;
    BOOL hasPart;
    while (!(hasPart = [scan scanUpToCharactersFromSet:set intoString:&part]) && ![scan isAtEnd]) {
      part = [self substringWithRange:NSMakeRange([scan scanLocation], 1)];
      [scan setScanLocation:[scan scanLocation] + 1];
      [outs appendString:backslash];
      [outs appendString:part];
    }
    // at end of loop part will contain non-escape-needing chars
    if (hasPart) [outs appendString:part];
  }
  return [NSString stringWithString:outs];
}


@end
