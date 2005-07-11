/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWConfigPath.h"

#import "MWUtilities.h"

enum {
  version1 = 1,
};
static const int currentVersion = version1;

static NSCharacterSet *escapeNeedingCharacters;

@implementation MWConfigPath

static MWConfigPath *singleEmptyPath = nil;

+ (void)initialize {
  [self setVersion:currentVersion];
  
  if (!escapeNeedingCharacters)
    escapeNeedingCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"%/"] retain];
}

+ (MWConfigPath *)emptyPath {
  if (!singleEmptyPath) singleEmptyPath = [[self alloc] init];
  return singleEmptyPath;
}
+ (MWConfigPath *)pathWithComponent:(NSString *)component {
  return [[[self alloc] initWithComponent:component] autorelease];
}
+ (MWConfigPath *)pathWithComponents:(NSString *)first, ... {
  NSMutableArray *c = first ? [NSMutableArray arrayWithObject:first] : nil;
  va_list v;
  id o = nil;
  if (!c) return [self emptyPath];
  va_start(v, first);
  while ((o = va_arg(v, id)) != nil) [c addObject:o];
  va_end(v);
  return [[[self alloc] initWithArray:c] autorelease];
}
+ (MWConfigPath *)pathWithArray:(NSArray *)array {
  return [[[self alloc] initWithArray:array] autorelease];
}
+ (MWConfigPath *)pathWithStringRepresentation:(NSString *)str {
  return [[[self alloc] initWithStringRepresentation:str] autorelease];
}
- (MWConfigPath *)initWithComponent:(NSString *)component {
  return [self initWithArray:[NSArray arrayWithObject:component]];
}
- (MWConfigPath *)initWithComponents:(NSString *)first, ... {
  NSMutableArray *c = [NSMutableArray arrayWithObject:first];
  va_list v;
  id o = nil;
  va_start(v, first);
  while ((o = va_arg(v, id)) != nil) [c addObject:o];
  va_end(v);
  return [self initWithArray:c];
}
- (MWConfigPath *)initWithArray:(NSArray *)array {
  if (!(self = [super init])) return nil;
  components = [array copyWithZone:[self zone]];
  return self;
}
- (MWConfigPath *)initWithStringRepresentation:(NSString *)str {
  NSEnumerator *scompE = [[[[str componentsSeparatedByString:@"/"] mutableCopy] autorelease] objectEnumerator];
  NSMutableString *scomp;
  NSMutableArray *final = [NSMutableArray array];
  if (!(self = [super init])) return nil;
  if (![[scompE nextObject] isEqualToString:@""]) {
    [self release];
    return nil;
  }
  while ((scomp = [[[scompE nextObject] mutableCopy] autorelease])) {
    NSRange
      searchRange = NSMakeRange(0, [scomp length]),
      foundRange;
    while ((foundRange = [scomp rangeOfString:@"%" options:NSLiteralSearch range:searchRange]).length) {
      NSString *hex = nil;
      int chi;
      unichar ch;
      if (foundRange.location + 3 > [scomp length]) {
        [self release];
        return nil;
      }
      hex = [scomp substringWithRange:NSMakeRange(foundRange.location + 1, 2)];
      if (![[NSScanner scannerWithString:hex] scanHexInt:&chi]) {
        [self release];
        return nil;
      }
      ch = chi;
      [scomp replaceCharactersInRange:NSMakeRange(foundRange.location, 3) withString:[NSString stringWithCharacters:&ch length:1]];
      searchRange = MWMakeABRange(foundRange.location + 1, [scomp length]);
    }
    [final addObject:[[scomp copy] autorelease]];
  }
  components = [final copyWithZone:[self zone]];
  return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (!(self = [super init])) return nil;
  switch ([aDecoder versionForClassName:@"MWConfigPath"]) {
    case version1:
      components = [[aDecoder decodeObject] retain];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigPath!", [aDecoder versionForClassName:@"MWConfigPath"]];
  }
  return self;
}

- (void)dealloc {
  [components autorelease]; components = nil;
  [stringRep autorelease]; stringRep = nil;
  [super dealloc];
}

// --- Path methods ---

- (NSArray *)components { return components ? components : [NSArray array]; }

- (NSString *)stringRepresentation {
  NSArray *com = [self components];
  if (!stringRep) {
    NSMutableString *rbuf = [NSMutableString string];
    NSEnumerator *cE = [com objectEnumerator];
    id c;
    while ((c = [cE nextObject])) {
      NSScanner *cScan = [[NSScanner alloc] initWithString:c];
    
      [rbuf appendString:@"/"];
      
      if (1) {
        while (![cScan isAtEnd]) {
          NSString *buf;
          unsigned loc;
          if ([cScan scanUpToCharactersFromSet:escapeNeedingCharacters intoString:&buf])
            [rbuf appendString:buf];
          if ([cScan isAtEnd]) break;
          // can't escape characters with values >255 properly. but it doesn't need to.
          [rbuf appendString:[NSString stringWithFormat:@"%%%2x", [c characterAtIndex:loc = [cScan scanLocation]]]];
          [cScan setScanLocation:loc + 1];
        }
      } else {
        // old code
        [rbuf appendString:[[[[c componentsSeparatedByString:@"%"] componentsJoinedByString:@"%25"] componentsSeparatedByString:@"/"] componentsJoinedByString:@"%2f"]];
      }
    }
    stringRep = [rbuf copyWithZone:[self zone]];
  }
  return stringRep;
}

- (BOOL)hasPrefix:(MWConfigPath *)other {
  return other && [[[self stringRepresentation] stringByAppendingString:@"/"] hasPrefix:[[other stringRepresentation] stringByAppendingString:@"/"]];
}

- (id)pathByDeletingLastComponent {
  NSArray *com = [self components];
  return [[self class] pathWithArray:[com subarrayWithRange:NSMakeRange(0, [com count] - 1)]];
}

- (id)pathByAppendingComponent:(NSString *)component {
  NSArray *com = [self components];
  return [[self class] pathWithArray:[com arrayByAddingObject:component]];
}

- (id)pathByAppendingPath:(MWConfigPath *)other {
  NSArray *com = [self components];
  return [[self class] pathWithArray:[com arrayByAddingObjectsFromArray:[other components]]];
}

// --- Protocols ---

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@>%@", [self class], [self stringRepresentation]];
}

- (unsigned)hash {
  return [[self stringRepresentation] hash];
}

- (BOOL)isEqual:(id)other {
  return self == other || (
    [other isKindOfClass:[MWConfigPath class]]
    && [[other stringRepresentation] isEqualToString:[self stringRepresentation]]
  );
}

- (id)copyWithZone:(NSZone *)zone {
  return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:components ? components : [NSArray array]];
}

@end
