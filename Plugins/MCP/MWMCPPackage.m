/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWMCPPackage.h"

#import "MWMCPMessage.h"
#import "MWMCProtocolFilter.h"

@implementation MWMCPVersion

+ (MWMCPVersion *)bestVersionInRangeAMin:(MWMCPVersion *)aMin aMax:(MWMCPVersion *)aMax bMin:(MWMCPVersion *)bMin bMax:(MWMCPVersion *)bMax {
  if (!aMin || !aMax || !bMin || !bMax) return nil;
  
  if ([aMin compare:bMax] == NSOrderedDescending || [bMin compare:aMax] == NSOrderedDescending)
    return nil;
  else if ([aMax compare:bMax] == NSOrderedAscending)
    return aMax;
  else
    return bMax;
}

+ (id)versionWithString:(NSString *)strVers {
  return [[[self alloc] initWithString:strVers] autorelease];
}

- (id)initWithString:(NSString *)strVers {
  NSRange dot = [strVers rangeOfString:@"."];
  if (!(self = [super init])) return nil;

  if (dot.length == 0) {
    [self release];
    return nil;
  }
  major = [[strVers substringToIndex:dot.location] intValue];
  minor = [[strVers substringFromIndex:dot.location + dot.length] intValue];

  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%i.%i", [self majorVersion], [self minorVersion]];
}

- (unsigned)hash {
  return (unsigned)[self majorVersion]
      + ((unsigned)[self minorVersion] << 8);
}

- (BOOL)isEqual:(id)other {
  return
    [other isKindOfClass:[self class]]
    && [self majorVersion] == [other majorVersion]
    && [self minorVersion] == [other minorVersion];
}

- (NSComparisonResult)compare:(MWMCPVersion *)other {
  if ([self majorVersion] == [other majorVersion]) {
    if ([self minorVersion] == [other minorVersion]) {
      return NSOrderedSame;
    } else if ([self minorVersion] > [other minorVersion]) {
      return NSOrderedDescending;
    } else {
      return NSOrderedAscending;
    }
  } else if ([self majorVersion] > [other majorVersion]) {
    return NSOrderedDescending;
  } else {
    return NSOrderedAscending;
  }
}

- (int)majorVersion { return major; }
- (int)minorVersion { return minor; }

@end

@implementation MWMCPPackage

+ (Class)classForPackageVersion:(MWMCPVersion *)vers { return self; }

- (id)initWithFilter:(MWMCProtocolFilter *)owner {
  if (!(self = [self init])) return nil;

  owningFilter = owner;

  return self;  
}

// owningFilter not retained

+ (NSArray *)packageNameComponents {
  NSArray *pieces = [[self description] componentsSeparatedByString:@"_"];
  if ([pieces count] >= 2) {
    return [pieces subarrayWithRange:NSMakeRange(1, [pieces count] - 1)];
  } else {
    [NSException raise:NSInternalInconsistencyException format:@"+[%@ packageName] not overriden and class name not parseable!", self];
    return nil;
  }
}
+ (NSString *)packageName {
  return [[self packageNameComponents] componentsJoinedByString:@"-"];
}
- (NSString *)packageName {
  return [[self class] packageName];
}

- (BOOL)participatesInVersionNegotiation { return YES; }

- (void)handleIncomingMessage:(MWMCPMessage *)msg {
  NSString *incomingName = [msg messageNameWithoutPackageName:[[self class] packageName]];
  if (!incomingName) {
    [NSException raise:NSInternalInconsistencyException format:@"%@: got message in wrong package: %@", self, msg];
  } else {
    // using member: to hopefully avoid security holes through possible string weirdness
    NSString *name = [[self incomingMessages] member:incomingName];
    if (!name) {
      [NSException raise:NSInternalInconsistencyException format:@"%@: got unknown message: %@", self, msg];
    } else {
      name = [NSString stringWithFormat:@"handleMessage_%@:", [[name componentsSeparatedByString:@"-"] componentsJoinedByString:@"_"]];
      [self performSelector:NSSelectorFromString(name) withObject:msg];
    }
  }
}

- (BOOL)handleOutgoing:(id)obj alreadyHandled:(BOOL)already {
  return NO;
}

- (void)sendMCPMessage:(NSString *)msg args:(NSDictionary *)args {
  [owningFilter sendMCPMessage:msg args:args];
}

- (void)startPackage {}

- (MWMCProtocolFilter *)owningFilter { return owningFilter; }

- (void)owningFilterDroppedPackage { owningFilter = nil; }

@end
