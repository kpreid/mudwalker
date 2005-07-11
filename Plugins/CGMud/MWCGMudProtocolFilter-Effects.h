/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

@interface MWCGMudProtocolFilter (MWCGMudProtocolFilterEffects)

+ (void)initializeEffects;

- (void)processEffects:(NSData *)bytecode component:(uint32_t)component;

- (void)initializeEffectsState;
- (void)resetEffectsState;

@end
