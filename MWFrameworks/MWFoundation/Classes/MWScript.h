/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

@class MWScriptContexts;

@interface MWScript : NSObject <NSCopying, NSCoding> {
  NSString *source;
  NSString *langId;
  id compiledForm;
}

- (id)initWithSource:(NSString *)nSource languageIdentifier:(NSString *)nLangId;

- (NSString *)source;
- (NSString *)languageIdentifier;

- (id)compiledForm;
- (void)setCompiledForm:(id)newVal;

- (NSString *)syntaxErrorsWithContexts:(MWScriptContexts *)contexts location:(NSString *)location;
- (id)evaluateWithArguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location;

@end
