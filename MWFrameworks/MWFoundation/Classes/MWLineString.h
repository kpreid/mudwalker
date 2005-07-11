/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * A MWLineString is an attributed string which is a single line of text. It additionally has a 'role' value which is essentially another attribute, except that it can have a value even on a zero-length string. MWLineStrings should not contain any line-break characters (\n, \r, etc.).
\*/

#import <Foundation/Foundation.h>

// MWLineString provides the concept of a text 'line' of characters, not including line ending character(s), with a role attribute for special handling. It can contain either a NSString or a NSAttributedString, and present its content as either

@interface MWLineString : NSObject <NSCopying> {
  NSString *plainString;
  NSAttributedString *attrString;
  NSString *role;
}

+ (MWLineString *)lineStringWithString:(NSString *)s role:(NSString *)r;
+ (MWLineString *)lineStringWithString:(NSString *)s;
+ (MWLineString *)lineStringWithAttributedString:(NSAttributedString *)s role:(NSString *)r;
+ (MWLineString *)lineStringWithAttributedString:(NSAttributedString *)s;

- (MWLineString *)initWithString:(NSString *)s role:(NSString *)r;
- (MWLineString *)initWithString:(NSString *)s;
- (MWLineString *)initWithAttributedString:(NSAttributedString *)s role:(NSString *)r;
- (MWLineString *)initWithAttributedString:(NSAttributedString *)s;

- (NSString *)string;
- (NSAttributedString *)attributedString;
- (NSString *)role;

@end
