/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MWConfigDictionary.h>

@interface MWDocumentSettings : MWConfigDictionary {
}

+ (NSDictionary *)defaultSettings;

- (NSDictionary *)convertToDictionaryForStorage;
- (void)restoreFromDictionaryForStorage:(NSDictionary *)dict;

@end
