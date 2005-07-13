/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Cocoa/Cocoa.h>

@interface MWGenericTableViewDataSource : NSObject {
  unsigned int rowCount;
  NSMutableDictionary *columns;
}

- (void)setRowCount:(int)rows;
- (void)setColumn:(NSArray *)array forKey:(NSString *)identifier;

@end
