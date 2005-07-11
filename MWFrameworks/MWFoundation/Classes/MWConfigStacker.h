/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWConfigStacker provides the ability to view multiple MWConfigSuppliers as one, allowing 'inheritance' of configuration values. Each stacker holds two suppliers. To stack more levels, use a chain of stackers.
\*/

#import <Foundation/Foundation.h>
#import "MWConfigSupplier.h"

@interface MWConfigStacker : NSObject <MWConfigSupplier, NSCopying> {
  /* :-) */
  id <MWConfigSupplier, NSObject> car;
  id <MWConfigSupplier, NSObject> cdr;
}

+ (MWConfigStacker *)stackerWithSuppliers:(id <MWConfigSupplier, NSObject>)pcar :(id <MWConfigSupplier, NSObject>)pcdr;
- (MWConfigStacker *)initWithSuppliers:(id <MWConfigSupplier, NSObject>)pcar :(id <MWConfigSupplier, NSObject>)pcdr;

/* These methods are defined in MWConfigSupplier, included here for reference:
  - (id)objectAtPath:(MWConfigPath *)path;
  - (id)objectAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path;
  
  - (unsigned)countAtPath:(MWConfigPath *)path;
  - (NSArray *)allKeysAtPath:(MWConfigPath *)path;
  - (NSArray *)allValuesAtPath:(MWConfigPath *)path;
*/

@end
