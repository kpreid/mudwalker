/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

@class NSString;

// rather fuzzy, these are, deliberately
typedef unsigned int MWConfigScope;
#define MWConfigScopeBuiltin  (1 << 1)
#define MWConfigScopeHost     (1 << 2)
#define MWConfigScopeUser     (1 << 3)
#define MWConfigScopeDocument (1 << 4)
#define MWConfigScopeSession  (1 << 5)
#define MWConfigScopeAll      (~(MWConfigScope)0)

enum { MWEnterKey = 0x03 };

/* Negation of these constants is always the reverse direction. */
typedef enum MWCursorMotionAction {
  MWCursorMotionFirst = -2,
  MWCursorMotionPrev  = -1,
  MWCursorMotionNone  =  0,
  MWCursorMotionNext  = +1,
  MWCursorMotionLast  = +2
} MWCursorMotionAction;

#define T(t) extern NSString * const t
#define S(n, s) extern NSString * const n
#ifdef BUILDING_MUDWALKER_FRAMEWORK
#  include "MWConstants.tokens"
#else
#  include <MudWalker/MWConstants.tokens>
#endif
#undef T
#undef S

