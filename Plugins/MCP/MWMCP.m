/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

#define getter(sym, setstr) \
  NSCharacterSet * sym(void) { \
    static NSCharacterSet *set = nil; \
    if (!set) set = [[NSCharacterSet characterSetWithCharactersInString:setstr] retain]; \
    return set; \
  }

getter(MWMCPGetSimpleChars, @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-~`!@#$%^&()=+{}[]|';?/><.,");
getter(MWMCPGetQuoteAndBackslashChars, @"\"\\");
