/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

extern NSCharacterSet * MWMCPGetSimpleChars(void);
#define MWMCPSimpleChars (MWMCPGetSimpleChars())

extern NSCharacterSet * MWMCPGetQuoteAndBackslashChars(void);
#define MWMCPQuoteAndBackslashChars (MWMCPGetQuoteAndBackslashChars())
