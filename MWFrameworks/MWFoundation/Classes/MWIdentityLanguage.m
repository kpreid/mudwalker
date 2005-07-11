/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWIdentityLanguage.h"

#import "MWLink.h"
#import "MWNSStringAdditions.h"
#import "MWScript.h"
#import "MWLineString.h"
#import "MWUtilities.h"

@implementation MWIdentityLanguage

- (NSString *)languageIdentifier { return @"BaseIdentity"; }

- (NSString *)localizedLanguageName { return MWLocalizedStringHere([self languageIdentifier]); }

- (NSString *)syntaxErrorsInScript:(MWScript *)script contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  return nil;
}

- (id)evaluateScript:(MWScript *)script arguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  NSString *hint = [arguments objectForKey:@"_MWScriptResultHint"];
  if ([hint isEqualToString:@"outward"]) {
    MWenumerate ([[[script source] componentsSeparatedByLineTerminators] objectEnumerator], NSString *, line) {
      [[arguments objectForKey:@"linkable"] send:[MWLineString lineStringWithString:line] toLinkFor:@"outward"];
    }
    return nil;
  } else if ([hint isEqualToString:@"return"]) {
    return [script source];
  } else {
    // FIXME: report error
    return nil;
  }
}

@end