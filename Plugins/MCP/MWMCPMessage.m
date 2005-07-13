/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWMCPMessage.h"

#import <MudWalker/MudWalker.h>
#import "MWMCP.h"

@implementation MWMCPMessage

- (void)privateCheckArgumentLine:(id)arg key:(NSString *)argk {
  // for calling from init. will either return normally or release self and raise an exception.
  unsigned end; 
  
  if (![arg isKindOfClass:[NSString class]]) {
    [self release];
    [NSException raise:NSInvalidArgumentException format:@"MCP message argument line (%@) must be a string, was %@ (%@)", argk, [arg class], arg];
  }
  
  if ([arg length])
    [arg getLineStart:NULL end:&end contentsEnd:NULL forRange:NSMakeRange(0, 1)];
  else
    end = 0;
  
  if (end < [arg length]) {
    [self release];
    [NSException raise:NSInvalidArgumentException format:@"MCP message argument line must not contain a line break but did: %@", arg];
  }
}


+ (MWMCPMessage *)messageWithName:(NSString *)name {
  return [self messageWithName:name arguments:[NSDictionary dictionary]];
}
+ (MWMCPMessage *)messageWithName:(NSString *)name arguments:(NSDictionary *)args {
  return [[[self alloc] initWithMessageName:name arguments:args] autorelease];
}
- (MWMCPMessage *)initWithMessageName:(NSString *)name arguments:(NSDictionary *)args {
  if (!(self = [super init])) return nil;
  
  { NSEnumerator *argkE = [args keyEnumerator];
    id argk, arg;

    while ((argk = [argkE nextObject])) {
      arg = [args objectForKey:argk];

      if ([arg isKindOfClass:[NSString class]]) {
        [self privateCheckArgumentLine:arg key:argk];
        
      } else if ([arg isKindOfClass:[NSArray class]]) {
        NSEnumerator *lineE = [arg objectEnumerator];
        NSString *line;
        
        while ((line = [lineE nextObject]))
          [self privateCheckArgumentLine:line key:argk];
        
      } else {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"MCP message argument (%@) must be a string or array of strings, was %@ (%@)", argk, [arg class], arg];
      }
    }
  }
  
  messageName = [name copy];
  arguments = [args copy];
  
  return self;
}

- (void)dealloc {
  [messageName autorelease]; messageName = nil;
  [arguments autorelease]; arguments = nil;
  [super dealloc];
}

- (NSString *)description {
  return [self descriptionWithLocale:nil indent:0];
}
- (NSString *)descriptionWithLocale:(NSDictionary *)locale {
  return [self descriptionWithLocale:locale indent:0];
}
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level {
  return [NSString stringWithFormat:@"<#$#%@ %@>", messageName, [arguments descriptionWithLocale:locale indent:level]];
}

- (NSString *)messageName { return messageName; }

- (NSString *)messageNameWithoutPackageName:(NSString *)packageName {
  NSArray *msgPieces = [[self messageName] componentsSeparatedByString:@"-"];
  NSArray *packPieces = [packageName componentsSeparatedByString:@"-"];
  
  if ([msgPieces count] >= [packPieces count] && [packPieces isEqual:[msgPieces subarrayWithRange:NSMakeRange(0, [packPieces count])]]) {
    return [[msgPieces subarrayWithRange:MWMakeABRange([packPieces count], [msgPieces count])] componentsJoinedByString:@"-"];
  } else {
    return nil;
  }
}

- (NSArray *)linesForSendingWithAuthenticationKey:(NSString *)authKey {  
  NSMutableString *outArgsString = [NSMutableString string];
  NSMutableArray *outLines = [NSMutableArray array];

  static unsigned int dataTagSerial;
  NSString *dataTag = [NSString stringWithFormat:@"%lu~%u", random(), dataTagSerial++];
  BOOL needsDataTag = NO;
  
  NSEnumerator *argKeyE = [arguments keyEnumerator];
  NSString *argKey;

  while ((argKey = [argKeyE nextObject])) {
    id argValue = [arguments objectForKey:argKey];
    
    [outArgsString appendString:@" "];
    [outArgsString appendString:argKey];
    
    if ([argValue isKindOfClass:[NSArray class]]) {
      // multi-line value

      NSString *multiPrefix = [NSString stringWithFormat:@"#$#* %@ %@: ", dataTag, argKey];

      needsDataTag = YES;
      [outArgsString appendString:@"*: "];
      [outArgsString appendString:[NSString stringWithFormat:@"%u", [argValue count]]];

      { 
        NSEnumerator *lineE = [argValue objectEnumerator];
        NSString *line;
        while ((line = [lineE nextObject]))
          [outLines addObject:[multiPrefix stringByAppendingString:line]];
      }

    } else {
      // single-line value
      
      [outArgsString appendString:@": "];
       
      if ([argValue rangeOfCharacterFromSet:[MWMCPSimpleChars invertedSet]].length || ![argValue length]) {
        [outArgsString appendString:@"\""];
        [outArgsString appendString:[argValue stringWithCharactersFromSet:MWMCPQuoteAndBackslashChars escapedByPrefix:@"\\"]];
        [outArgsString appendString:@"\""];
      } else {
        [outArgsString appendString:argValue];
      }
    }
  }
    
  if (needsDataTag) {
    [outLines addObject:[NSString stringWithFormat:@"#$#: %@", dataTag]];
    [outArgsString appendString:@" _data-tag: "];
    [outArgsString appendString:dataTag];
  }
  
  [outLines insertObject:[NSString stringWithFormat:@"#$#%@ %@%@", [self messageName], authKey, outArgsString] atIndex:0];
  return outLines;
}


- (unsigned)count { return [arguments count]; }
- (id)objectForKey:(id)key { return [arguments objectForKey:key]; }
- (NSEnumerator *)keyEnumerator { return [arguments keyEnumerator]; }

@end
