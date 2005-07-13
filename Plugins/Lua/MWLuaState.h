/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#include "lua.h"

@class MWScriptContexts;

@interface MWLuaState : NSObject {
  MWScriptContexts *owningContexts; /* WEAK */
  lua_State *state;
}

- (id)initWithContexts:(/* WEAK */ MWScriptContexts *)cxs;

- (lua_State *)luaStateValue;

@end

void MWPushObjectOnLuaStack(lua_State *state, id object);
id MWObjectFromLuaStackIndex(lua_State *state, int ix);
