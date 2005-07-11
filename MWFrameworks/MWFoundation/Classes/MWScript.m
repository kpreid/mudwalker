/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWScript.h"

#import "MWRegistry.h"
#import "MWScriptLanguage.h"
#import "MWScriptContexts.h"

enum {
  version1 = 1,
};
static const int currentVersion = version1;

@implementation MWScript

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)initWithSource:(NSString *)nSource languageIdentifier:(NSString *)nLangId {
  if (!(self = [super init])) return nil;
  
  source = nSource ? [nSource copyWithZone:[self zone]] : [@"" retain];
  langId = [nLangId copyWithZone:[self zone]];
  
  
  return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super init])) return nil;

  switch ([decoder versionForClassName:@"MWScript"]) {
    case version1:
      source = [[decoder decodeObject] retain];
      langId = [[decoder decodeObject] retain];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWScript!", [decoder versionForClassName:@"MWScript"]];
  }

  return self;
}

- (void)dealloc {
  [source autorelease]; source = nil;
  [langId autorelease]; langId = nil;
  [compiledForm autorelease]; compiledForm = nil;
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:source];
  [aCoder encodeObject:langId];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithSource:[self source] languageIdentifier:[self languageIdentifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ in %@>%@", [self class], [self languageIdentifier], [self source]];
}

- (BOOL)isEqual:(id)other {
  return [other isKindOfClass:[MWScript class]]
    && [[other source] isEqualToString:[self source]]
    && ([[other languageIdentifier] isEqualToString:[self languageIdentifier]]
        || [other languageIdentifier] == nil && [self languageIdentifier] == nil);
}

- (unsigned)hash { return [[self source] hash] ^ [[self languageIdentifier] hash]; }

- (NSString *)source { return source; }
- (NSString *)languageIdentifier { return langId; }

- (id)compiledForm { return compiledForm; }
- (void)setCompiledForm:(id)newVal {
  [compiledForm autorelease];
  compiledForm = [newVal retain];
}

- (id <MWScriptLanguage>)privateGetMyLanguage:(MWScriptContexts *)contexts {
  id <MWScriptLanguage> const language = [[MWRegistry defaultRegistry] handlerForCapability:[NSArray arrayWithObjects:@"MWScriptLanguage", [self languageIdentifier], nil]];
  
  if (!language) {
    [contexts postDebugMessage:[NSString stringWithFormat:@"There is no interpreter for \"%@\" available.\n", [self languageIdentifier]]];
  }
  
  return language;
}

- (NSString *)syntaxErrorsWithContexts:(MWScriptContexts *)contexts location:(NSString *)location {
  return [[self privateGetMyLanguage:contexts] syntaxErrorsInScript:self contexts:contexts location:location];
}

- (id)evaluateWithArguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  if ([[self source] isEqualToString:@""] && ![self languageIdentifier])
    return nil;
    
  return [[self privateGetMyLanguage:contexts] evaluateScript:self arguments:arguments contexts:contexts location:location];
}

@end
