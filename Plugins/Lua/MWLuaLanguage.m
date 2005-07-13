/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWLuaLanguage.h"

#import <MudWalker/MWScriptContexts.h>

#import "MWLuaState.h"
#import "MWSubstitutedLuaLanguage.h"

#include <lua.h>
#include <lauxlib.h>

@implementation MWLuaLanguage

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  [registry registerScriptLanguage:[[[MWLuaLanguage alloc] init] autorelease]];
  [registry registerScriptLanguage:[[[MWSubstitutedLuaLanguage alloc] init] autorelease]];
}

- (NSString *)languageIdentifier { return @"Lua"; }

- (NSString *)localizedLanguageName { return @"Lua"; }

- (MWLuaState *)luaStateForContexts:(MWScriptContexts *)contexts {
   MWLuaState *stateObj = [contexts contextForLanguageIdentifier:[self languageIdentifier]];
  if (!stateObj) {
    stateObj = [[[MWLuaState alloc] initWithContexts:contexts] autorelease];
    [contexts setContext:stateObj forLanguageIdentifier:[self languageIdentifier]];
  }
  return stateObj;
}

- (NSString *)syntaxErrorsInScript:(MWScript *)script contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  MWLuaState *const stateObj = [self luaStateForContexts:contexts];
  lua_State *const state = [stateObj luaStateValue];
    
  NSData *scriptData = [[script source] dataUsingEncoding:[NSString defaultCStringEncoding]];
  switch (luaL_loadbuffer(state, [scriptData bytes], [scriptData length], [location lossyCString])) {
    case 0:
      lua_pop(state, 1);
      return nil;
    default: {
      NSString *const errors = MWObjectFromLuaStackIndex(state, -1);
      lua_pop(state, 1);
      return errors;
    }
  }
}

- (id)evaluateScript:(MWScript *)script arguments:(NSDictionary *)arguments contexts:(MWScriptContexts *)contexts location:(NSString *)location {
  MWLuaState *const stateObj = [self luaStateForContexts:contexts];
  lua_State *const state = [stateObj luaStateValue];

  lua_pushstring(state, "arg");
  MWPushObjectOnLuaStack(state, arguments);
  lua_settable(state, LUA_GLOBALSINDEX);

  lua_pushstring(state, "_MWScriptInit");
  lua_gettable(state, LUA_GLOBALSINDEX);
  switch (lua_pcall(state, 0, 0, NULL)) {
    case 0:
      break;
    default:
      [contexts postDebugMessage:[NSString stringWithFormat:@"Could not run Lua function for pre-script init: %@", MWObjectFromLuaStackIndex(state, -1)]];
      lua_pop(state, 1);
      break;
  }
  
  
  NSData *scriptData = [[script source] dataUsingEncoding:[NSString defaultCStringEncoding]];
  switch (luaL_loadbuffer(state, [scriptData bytes], [scriptData length], [location lossyCString])) {
    case 0:
      break;
    default: {
      NSString *const errors = MWObjectFromLuaStackIndex(state, -1);
      lua_pop(state, 1);
      [contexts postDebugMessage:errors];
      return nil;
    }
  }
  
  switch (lua_pcall(state, 0, 1, NULL)) {
    case 0: {
      id value = MWObjectFromLuaStackIndex(state, -1);
      lua_pop(state, 1);
      return value;
    }
    default: {
      id message = MWObjectFromLuaStackIndex(state, -1);
      lua_pop(state, 1);
      [contexts postDebugMessage:message];
      return nil;
    }
  }
}

@end