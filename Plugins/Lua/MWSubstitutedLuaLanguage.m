/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWSubstitutedLuaLanguage.h"

#import <MudWalker/MWNSStringAdditions.h>

// FIXME: utility class is stashed here until we decide what to do with it

enum { MWSSWStateStatement, MWSSWStateExpr };

@implementation MWSubstitutedScriptWriter

- (id)init {
  if (!(self = [super init])) return nil;
  
  result = [[NSMutableString alloc] init];
  
  return self;
}

- (void)dealloc {
  [result autorelease]; result = nil;
  [partialExpr autorelease]; partialExpr = nil;
  [super dealloc];
}

- (NSString *)exprSeparatorFragment { return @""; }
- (NSString *)beginLineFragment { return @""; }
- (NSString *)endLineFragment { return @""; }
- (NSString *)endStatementFragment { return @""; }
- (NSString *)concatFragment { return @""; }
- (NSString *)stringLiteralFragment:(NSString *)s { return @""; }
//stringWithCharactersFromSet:(NSCharacterSet *)set escapedByPrefix:(NSString *)backslash

- (void)appendPartialExpr:(NSString *)s {
  if (partialExpr || [s length]) {
    if (!partialExpr)
      partialExpr = [[NSMutableString alloc] init];
    else
      [partialExpr appendString:[self concatFragment]];
    [partialExpr appendString:s];
  }
}

- (void)flushPartial {
  if (!partialExpr)
    [self appendPartialExpr:[self stringLiteralFragment:@""]];

  [result appendString:[self beginLineFragment]];
  [result appendString:partialExpr];
  [result appendString:[self endLineFragment]];
  [result appendString:[self endStatementFragment]];
  
  [partialExpr release]; partialExpr = nil;
}

- (void)inputLiteral:(NSString *)s {
  NSEnumerator *const lineE = [[[s stringByAppendingString:@"\n"] componentsSeparatedByLineTerminators] objectEnumerator];
  NSString *line = [lineE nextObject];
  if ([line length])
    [self appendPartialExpr:[self stringLiteralFragment:line]];
  while ((line = [lineE nextObject])) {
    [self flushPartial];
    if ([line length])
      [self appendPartialExpr:[self stringLiteralFragment:line]];
  }
}
- (void)inputCode:(NSString *)s {
  [result appendString:s];
  [result appendString:[self endStatementFragment]];
}
- (void)inputExpr:(NSString *)s {
  [self appendPartialExpr:s];
}

- (void)finish {
  if (partialExpr)
    [self flushPartial];
}

- (NSString *)result {
  [self finish];
  return [[result copy] autorelease];
}

@end

@implementation MWSubstitutedLuaScriptWriter

- (NSString *)exprSeparatorFragment { return @", "; }
- (NSString *)beginLineFragment { return @"send("; }
- (NSString *)endLineFragment { return @")"; }
- (NSString *)endStatementFragment { return @"\n"; }
- (NSString *)concatFragment { return @" .. "; }
- (NSString *)stringLiteralFragment:(NSString *)s {
  return [NSString stringWithFormat:@"\"%@\"", [s stringWithCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\\"'\n"] escapedByPrefix:@"\\"]];
}

@end

@implementation MWSubstitutedLuaLanguage

- (NSString *)languageIdentifier { return @"SubstitutedLua"; }

- (NSString *)localizedLanguageName { return MWLocalizedStringHere(@"SubstitutedLua"); }

#define SPECIAL_BEGIN @"@@"
#define SPECIAL_END @"\n"
#define EXPR_BEGIN @"$("
#define EXPR_END @")$"
#define SEXPR_BEGIN @"$$"

- (NSString *)convertScriptToLua:(NSString *)source {
  MWSubstitutedLuaScriptWriter *const ssw = [[MWSubstitutedLuaScriptWriter alloc] init];
  NSScanner *const scan = [NSScanner scannerWithString:source];
  NSCharacterSet *const specials = [NSCharacterSet characterSetWithCharactersInString:@"$@"];
  [scan setCharactersToBeSkipped:[NSCharacterSet characterSetWithRange:NSMakeRange(0, 0)]];
  [scan setCaseSensitive:YES];
  
  while (1) {
    NSString *buf;
    
    if ([scan scanUpToCharactersFromSet:specials intoString:&buf])
      [ssw inputLiteral:buf];

    if ([scan isAtEnd])
      break;
    
    if ([scan scanString:@"@@" intoString:NULL]) {
      if ([scan scanUpToString:@"\n" intoString:&buf])
        [ssw inputCode:buf];
      [scan scanString:@"\n" intoString:NULL];
    } else if ([scan scanString:@"$(" intoString:NULL]) {
      if ([scan scanUpToString:@")$" intoString:&buf])
        [ssw inputExpr:buf];
      [scan scanString:@")$" intoString:NULL];
    } else if ([scan scanString:@"$$" intoString:NULL]) {
      if ([scan scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&buf])
        [ssw inputExpr:buf];
    } else {
      if ([scan scanCharactersFromSet:specials intoString:&buf])
        [ssw inputLiteral:buf];
    }
  }
  
  [ssw finish];
  [ssw inputCode:@"return _MWScriptReturnBuffer()"];
  
  //NSLog(@"%@", [ssw result]);
  
  return [ssw result];
}


- (MWScript *)compiledFormOf:(MWScript *)script {
  if (![script compiledForm])
    [script setCompiledForm:[[[MWScript alloc] initWithSource:[self convertScriptToLua:[script source]] languageIdentifier:@"Lua"] autorelease]];
  return [script compiledForm];
}

- (NSString *)syntaxErrorsInScript:(MWScript *)script contexts:(MWScriptContexts *)contexts location:(NSString *)location { 
  return [[self compiledFormOf:script] syntaxErrorsWithContexts:contexts location:location];
}

- (id)evaluateScript:(MWScript *)script arguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location { 
  return [[self compiledFormOf:script] evaluateWithArguments:arguments contexts:contexts location:location];
}

@end
