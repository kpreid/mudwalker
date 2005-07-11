/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

#import "MWRegistry.h"

@class MWScript, MWScriptContexts;
@protocol MWCompiledScript;

@protocol MWScriptLanguage

- (NSString *)languageIdentifier;
- (NSString *)localizedLanguageName;

- (NSString *)syntaxErrorsInScript:(MWScript *)script contexts:(MWScriptContexts *)contexts location:(NSString *)location;

- (id)evaluateScript:(MWScript *)script arguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location;

@end

@interface MWRegistry (MWScriptLanguage)

- (void)registerScriptLanguage:(id <MWScriptLanguage>)language;

@end