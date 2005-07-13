/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

#import "MWLuaLanguage.h"

@interface MWSubstitutedScriptWriter : NSObject {
  NSMutableString *result;
  NSMutableString *partialExpr;
}

- (void)inputLiteral:(NSString *)s;
- (void)inputCode:(NSString *)s;
- (void)inputExpr:(NSString *)s;

- (void)finish;

- (NSString *)result;

@end

@interface MWSubstitutedLuaScriptWriter : MWSubstitutedScriptWriter
@end

@interface MWSubstitutedLuaLanguage : NSObject <MWScriptLanguage>

@end
