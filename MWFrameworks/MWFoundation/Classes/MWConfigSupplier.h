/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Protocol for MWConfigTree and MWConfigStacker.
\*/

@class MWConfigPath;

@protocol MWConfigSupplier <NSObject>

/* These methods should return nil if the object requested does not exist (or optionally NSRangeException if an index is out of range), or if the given path is nil. Mutation methods raise exceptions instead. If a directory is requested, the result is undefined except in that it will not be nil. */
- (id)objectAtPath:(MWConfigPath *)path;
- (id)objectAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path;
- (NSString *)keyAtIndex:(unsigned)index inDirectoryAtPath:(MWConfigPath *)path;
- (unsigned)indexOfKey:(NSString *)key inDirectoryAtPath:(MWConfigPath *)path;
- (BOOL)isDirectoryAtPath:(MWConfigPath *)path;

/* Number of entries in specified directory path. Result is undefined if path does not refer to a directory. */
- (unsigned)countAtPath:(MWConfigPath *)path;
/* Keys in specified directory path. Result is undefined if path does not refer to a directory. */
- (NSArray *)allKeysAtPath:(MWConfigPath *)path;
/* Values in specified directory path Result is undefined if path does not refer to a directory. */
- (NSArray *)allValuesAtPath:(MWConfigPath *)path;

// the protocol possibly should have an API for extracting the mutable object from a stacker, for write-back purposes?

@end