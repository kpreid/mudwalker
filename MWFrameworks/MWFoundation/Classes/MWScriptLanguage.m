#import "MWScriptLanguage.h"

@implementation MWRegistry (MWScriptLanguage)

- (void)registerScriptLanguage:(id <MWScriptLanguage>)language {
  // FIXME: needs test
  [self registerCapability:[NSArray arrayWithObjects:@"MWScriptLanguage", [language languageIdentifier], nil] qualifiers:nil handler:language];
  [self registerCapability:@"MWScriptLanguage" qualifiers:nil handler:language];
}

@end