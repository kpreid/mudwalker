/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

// NOTE: Avoid relying on the -stringRepresentation of a MWConfigPath across launches, as the precise conversion may change.

#import <Foundation/Foundation.h>

@interface MWConfigPath : NSObject <NSCopying, NSCoding> {
  NSArray *components;
  NSString *stringRep;
  void *expand;
}

+ (MWConfigPath *)emptyPath;
+ (MWConfigPath *)pathWithComponent:(NSString *)component;
+ (MWConfigPath *)pathWithComponents:(NSString *)first, ...;
+ (MWConfigPath *)pathWithArray:(NSArray *)array;
+ (MWConfigPath *)pathWithStringRepresentation:(NSString *)str;
- (MWConfigPath *)initWithComponent:(NSString *)component;
- (MWConfigPath *)initWithComponents:(NSString *)first, ...;
- (MWConfigPath *)initWithArray:(NSArray *)array;
- (MWConfigPath *)initWithStringRepresentation:(NSString *)str;

- (NSArray *)components;
- (NSString *)stringRepresentation;

- (BOOL)hasPrefix:(MWConfigPath *)other;

- (id)pathByDeletingLastComponent;
- (id)pathByAppendingComponent:(NSString *)component;
- (id)pathByAppendingPath:(MWConfigPath *)other;

@end
