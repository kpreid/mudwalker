/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Protocol for things that have config.
\*/

@protocol MWConfigSupplier;
@class MWConfigTree;

@protocol MWHasConfig

- (id <MWConfigSupplier>)config;

@end

@protocol MWHasMutableConfig <MWHasConfig>

- (MWConfigTree *)configLocalStore;

@end
