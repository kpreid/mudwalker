/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

// MWLineData provides the concept of a text 'line' of unspecified character
// set, not including line ending character(s), with a role attribute for
// prompt handling.

@interface MWLineData : NSObject <NSCopying> {
  NSData *data;
  NSString *role;
}

- (MWLineData *)initWithData:(NSData *)d role:(NSString *)r;
- (MWLineData *)initWithData:(NSData *)d;

- (NSData *)data;
- (NSString *)role;

@end
