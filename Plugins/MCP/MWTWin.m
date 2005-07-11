/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWin.h"

#import <MudWalker/MudWalker.h>
#import "MWTWinLayoutView.h"

NSCharacterSet * MWTWinGetEscapeNeedingCharacters(void) {
  static NSCharacterSet *escape = nil;
  if (!escape) escape = [[NSCharacterSet characterSetWithCharactersInString:@"\"\\"] retain];
  return escape;
}

NSDictionary * MWTWinGetWidgetData(void) {
  static NSDictionary *data = nil;
  if (!data) data = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[MWTWinLayoutView class]] pathForResource:@"TWinWidgetData" ofType:@"plist"]] retain];
  if (!data) [NSException raise:NSInternalInconsistencyException format:@"TWinWidgetData.plist not found in bundle or not readable"];
  return data;
}

@implementation NSScanner (MWTWinAdditions)

- (BOOL)scanTWinSExprLeaf:(id *)into {
  [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
  if ([self scanString:@"\"" intoString:NULL]) {
    NSMutableString *accum = [NSMutableString string];
    while (1) {
      NSString *piece = nil;
      if ([self scanUpToCharactersFromSet:MWTWinEscapeNeedingCharacters intoString:&piece])
        [accum appendString:piece];
      if ([self scanString:@"\"" intoString:NULL]) {
        break;
      } else if ([self scanString:@"\\" intoString:NULL]) {
        if ([self isAtEnd]) return NO;
        piece = [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
        [self setScanLocation:[self scanLocation] + 1];
        [accum appendString:piece];
      } else {
        // end of string
        return NO;
      }
    }
    *into = [[accum copy] autorelease];
  } else {
    if (![self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" ])"] intoString:into]) return NO;
  }
  return YES;
}

- (BOOL)scanTWinSExpressionIncludingType:(BOOL)includingType into:(id *)into {
  NSMutableArray *pieces = [NSMutableArray arrayWithCapacity:1];
  NSString *type;
  NSParameterAssert(![[self charactersToBeSkipped] characterIsMember:0x20]);
  
  *into = nil;
  
  [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
  if (                   /* brace matching fix */
       [self scanString:@"(" /*)*/ intoString:&type]
    || [self scanString:@"[" /*]*/ intoString:&type]
  ) {
    id piece, closing;
    closing = [type isEqual:@"(" /*)*/] ? /*(*/ @")" : /*[*/ @"]";
    
    if (includingType) [pieces addObject:type];
    
    while ([self scanTWinSExpressionIncludingType:includingType into:&piece]) [pieces addObject:piece];
    
    [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
    if (![self scanString:closing intoString:NULL]) return NO;
    [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
    
    *into = [[pieces copy] autorelease];
    return YES;
    
  } else {
    return [self scanTWinSExprLeaf:into];
  }
}

@end // NSScanner

@implementation NSArray (MWTWinAdditions)

- (NSString *)asTWinSExpression {
  NSMutableString *value = [@"(" mutableCopy];
  NSEnumerator *e = [self objectEnumerator];
  id child;
  while ((child = [e nextObject])) {
    [value appendString:[child asTWinSExpression]];
    [value appendString:@" "];
  }
  [value appendString:@")"];
  return [[value copy] autorelease];
}

@end // NSArray

@implementation NSNumber (MWTWinAdditions)

- (NSString *)asTWinSExpression {
  return [self stringValue];
}

@end // NSNumber

@implementation MWToken (MWTWinAdditions)

- (NSString *)asTWinSExpression {
  NSString *name = [self name];
  unsigned nlen = [name length];
  NSMutableData *md = [NSMutableData dataWithLength:nlen * sizeof(unichar)];
  unichar *mdb = [md mutableBytes];
  int i;
  
  [name getCharacters:mdb];
  for (i = 0; i < nlen; i++)
    if (!(i ? isalnum(mdb[i]) || mdb[i] == '_' : isalpha(mdb[i])))
      [NSException raise:NSInvalidArgumentException format:@"MWToken %@ cannot be converted to TWin S-expression due to invalid character: '%@'", [name substringWithRange:NSMakeRange(i, 1)]];

  return [self name];
}

@end // MWToken

@implementation NSString (MWTWinAdditions)

- (NSString *)asTWinSExpression {
  return [NSString stringWithFormat:@"\"%@\"", [self stringWithCharactersFromSet:MWTWinEscapeNeedingCharacters escapedByPrefix:@"\\"]];
}

- (int)getTWinSize:(float *)size stretch:(float *)stretch shrink:(float *)shrink {
  int used = 0;
  NSScanner *scan = [NSScanner scannerWithString:self];
  
  while (![scan isAtEnd]) {
    int dbit;
    float *dvar;
    if ([scan scanString:@"+" intoString:NULL]) {
      dbit = MWTWinStretchBit;
      dvar = stretch;
    } else if ([scan scanString:@"-" intoString:NULL]) {
      dbit = MWTWinShrinkBit;
      dvar = shrink;
    } else {
      dbit = MWTWinSizeBit;
      dvar = size;
    }
    if ([scan scanString:@"Inf" intoString:NULL]) {
      *dvar = MWTWinInfinity;
      used |= dbit;
    } else if ([scan scanFloat:dvar]) {
      used |= dbit;
    } else {
      NSLog(@"Warning: couldn't parse TWin size attribute '%@' at character %u", self, [scan scanLocation]);
      used |= MWTWinSizeErrorBit;
      return used;
    }
  }
  return used;
}
 
@end // NSString

