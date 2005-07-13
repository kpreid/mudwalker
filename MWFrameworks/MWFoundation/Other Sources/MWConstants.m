/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWConstants.h"
#import <Foundation/NSString.h>

// 10.2 gcc3
//#define T(t) NSString * const t = @ ## #t

// 10.3 gcc3.3
#define T(t) NSString * const t = @ #t

#define S(n, s) NSString * const n = s
#include "MWConstants.tokens"
#undef T
#undef S
