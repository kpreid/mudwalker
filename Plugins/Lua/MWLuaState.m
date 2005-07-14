/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLuaState.h"

#import <MudWalker/MWLink.h>
#import <MudWalker/MWLineString.h>
#import <MudWalker/MWConfigSupplier.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWScriptContexts.h>
#import <MudWalker/MWUtilities.h>
#import <AppKit/NSSound.h>
#import <AppKit/NSSpeechSynthesizer.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

@interface MWLuaState (Private)

- (MWScriptContexts *)owningContexts;

@end

@implementation MWLuaState

// I checked. At least in the current implementation, it's OK to longjmp out of NS_HANDLER...NS_ENDHANDLER, and the documentation doesn't say you can't.

#define mydelete(state, k, t) do { \
  lua_pushstring(state, k); \
  lua_pushnil(state); \
  lua_settable(state, t); \
} while(0)

#define MWLuaExceptionConvert_BEGIN \
  NS_DURING
#define MWLuaExceptionConvert_END \
  NS_HANDLER \
    if (0) NSLog(@"%@ %@", localException, [localException reason]); \
    MWPushObjectOnLuaStack(L, [localException reason]); \
    lua_error(L); \
  NS_ENDHANDLER

static int myLUDRelease(lua_State *L) {
  int const n = lua_gettop(L);
  if (n >= 1) {
    MWLuaExceptionConvert_BEGIN
      [*(id *)lua_touserdata(L, -1) release];
    MWLuaExceptionConvert_END
  }
  return 0;
}

// FIXME: standard framework for trivial lua-to-objc method conversions

static int myLUD_link_send(lua_State *L) {
  int const n = lua_gettop(L);
  if (n >= 3) {
    MWLuaExceptionConvert_BEGIN
      [*(id *)lua_touserdata(L, 1) send:MWObjectFromLuaStackIndex(L, 2) toLinkFor:MWObjectFromLuaStackIndex(L, 3)];
    MWLuaExceptionConvert_END
  }
  return 0;
}

static int myLUD_objectAtPath(lua_State *L) {
  int const n = lua_gettop(L);
  if (n >= 2) {
    MWLuaExceptionConvert_BEGIN
      MWPushObjectOnLuaStack(L, [*(id *)lua_touserdata(L, 1) objectAtPath:MWObjectFromLuaStackIndex(L, 2)]);
    MWLuaExceptionConvert_END
    return 1;
  }
  return 0;
}

static int myLUD_config(lua_State *L) {
  int const n = lua_gettop(L);
  if (n >= 1) {
    MWLuaExceptionConvert_BEGIN
      MWPushObjectOnLuaStack(L, [*(id *)lua_touserdata(L, 1) config]);
    MWLuaExceptionConvert_END
    return 1;
  }
  return 0;
}

static int myLUDIndex(lua_State *L) {
  int const n = lua_gettop(L);
  if (n >= 1) {
    const char *const key = lua_tostring(L, -1);
    // FIXME: use a dictionary instead
    if (strcmp(key, "link_send") == 0) {
      lua_pushcfunction(L, myLUD_link_send);
    } else if (strcmp(key, "objectAtPath") == 0) {
      lua_pushcfunction(L, myLUD_objectAtPath);
    } else if (strcmp(key, "config") == 0) {
      lua_pushcfunction(L, myLUD_config);
    } else {
      lua_pushnil(L);
    }
    return 1;
  }
  return 0;
}

static int myLua_new_lineString(lua_State *L) {
  MWLuaExceptionConvert_BEGIN
    MWPushObjectOnLuaStack(L, [[[MWLineString alloc] initWithString:MWObjectFromLuaStackIndex(L, 1) role:MWObjectFromLuaStackIndex(L, 2)] autorelease]);
  MWLuaExceptionConvert_END
  return 1;
}

static int myLua_configPath(lua_State *L) {
  int const n = lua_gettop(L);
  MWLuaExceptionConvert_BEGIN
    NSMutableArray *components = [NSMutableArray array];
    int i;
    for (i = 1; i <= n; i++) {
      [components addObject:MWObjectFromLuaStackIndex(L, i)];
    }
    MWPushObjectOnLuaStack(L, [MWConfigPath pathWithArray:components]);
  MWLuaExceptionConvert_END
  return 1;
}

static int myLua_soundNamed(lua_State *L) {
  MWLuaExceptionConvert_BEGIN
    MWPushObjectOnLuaStack(L, [NSClassFromString(@"NSSound") soundNamed:MWObjectFromLuaStackIndex(L, 1)]);
  MWLuaExceptionConvert_END
  return 1;
}

static int myLua_print(lua_State *L) {
  lua_pushstring(L, "MudWalker Lua State Object");
  lua_gettable(L, LUA_REGISTRYINDEX);
  MWLuaState *const self = MWObjectFromLuaStackIndex(L, -1);
  lua_pop(L, 1);
  MWLuaExceptionConvert_BEGIN
    [[self owningContexts] postDebugMessage:MWObjectFromLuaStackIndex(L, 1)];
  MWLuaExceptionConvert_END
  return 0;
}

static int myLua_speak(lua_State *L) {
  static NSMutableDictionary *voicesByNameCache = nil;
  
  // NSClassFromString is used so that this bundle does not depend on AppKit at link time.
  Class const lNSSpeechSynthesizer = NSClassFromString(@"NSSpeechSynthesizer");
  
  NSString *voice = nil;
  NSString *text = nil;

  int const n = lua_gettop(L);
  switch (n) {
    case 2: {
      NSString *voiceName = nil;

      MWLuaExceptionConvert_BEGIN
        voiceName = MWObjectFromLuaStackIndex(L, 2);
        text = MWObjectFromLuaStackIndex(L, 1);
        
        if (!voicesByNameCache)
          voicesByNameCache = [[NSMutableDictionary alloc] init];
          
        if (!(voice = [voicesByNameCache objectForKey:voiceName])) {
          MWenumerate([[lNSSpeechSynthesizer availableVoices] objectEnumerator], NSString *, someVoiceId) {
            //NSLog(@"%@ %@", someVoiceId, [lNSSpeechSynthesizer attributesForVoice:someVoiceId]);
            if ([[[lNSSpeechSynthesizer attributesForVoice:someVoiceId] objectForKey:/* NSVoiceName */ @"VoiceName"] isEqualToString:voiceName]) {
              voice = someVoiceId;
              [voicesByNameCache setObject:someVoiceId forKey:voiceName];
              break;
            }
          }
        }

      MWLuaExceptionConvert_END
      
      if (!voice) {
        MWLuaExceptionConvert_BEGIN
          MWPushObjectOnLuaStack(L, [NSString stringWithFormat:@"speak(): unknown voice: %@", voiceName]);
        MWLuaExceptionConvert_END
        lua_error(L);
      }
      break;
    }
    case 1: {
      MWLuaExceptionConvert_BEGIN
      voice = [lNSSpeechSynthesizer defaultVoice];
      text = MWObjectFromLuaStackIndex(L, 1);
      MWLuaExceptionConvert_END
      break;
    }
    default: {
      MWLuaExceptionConvert_BEGIN
        MWPushObjectOnLuaStack(L, [NSString stringWithFormat:@"speak() takes 1 or 2 arguments, not %i", n]);
      MWLuaExceptionConvert_END
      lua_error(L);
      // won't reach here
    }
  }
  MWLuaExceptionConvert_BEGIN
    NSSpeechSynthesizer *const syn = [[[lNSSpeechSynthesizer alloc] initWithVoice:voice] autorelease];
    [syn startSpeakingString:text];
  MWLuaExceptionConvert_END
  return 0;
}

- (id)initWithContexts:(MWScriptContexts *)cxs {
  if (!(self = [super init])) return nil;
  
  state = lua_open();
  owningContexts = cxs;
  
  luaopen_base(state);
  luaopen_string(state);
  luaopen_table(state);
  luaopen_math(state);
  
  /* delete dangerous funcs in base lib */
  mydelete(state, "print", LUA_GLOBALSINDEX);
  mydelete(state, "loadfile", LUA_GLOBALSINDEX);
  mydelete(state, "dofile", LUA_GLOBALSINDEX);
  mydelete(state, "loadstring", LUA_GLOBALSINDEX);
  mydelete(state, "require", LUA_GLOBALSINDEX);
 
  /* our metatable for ObjC refs held in Lua userdata */
  {
    lua_pushstring(state, "MudWalker ObjC Userdata Metatable");
    lua_newtable(state);
    int ix = lua_gettop(state);

    lua_pushstring(state, "__gc");
    lua_pushcfunction(state, myLUDRelease);
    lua_settable(state, ix);

    lua_pushstring(state, "__index");
    lua_pushcfunction(state, myLUDIndex);
    lua_settable(state, ix);

    // FIXME: define equality on isEqual:

    lua_settable(state, LUA_REGISTRYINDEX);
  }
  
  /* ref to us for use in lua */
  lua_pushstring(state, "MudWalker Lua State Object");
  MWPushObjectOnLuaStack(state, self);
  lua_settable(state, LUA_REGISTRYINDEX);
  
  /* our global funcs */
  lua_register(state, "new_lineString", myLua_new_lineString);
  lua_register(state, "configPath", myLua_configPath);
  lua_register(state, "soundNamed", myLua_soundNamed);
  lua_register(state, "print", myLua_print);
  lua_register(state, "speak", myLua_speak);
 
  /* lua-code init */
  if (luaL_loadfile(state, [[[NSBundle bundleForClass:[self class]] pathForResource:@"mw_init" ofType:@"lua"] fileSystemRepresentation])) {
        [owningContexts postDebugMessage:[NSString stringWithFormat:@"Could not load Lua MudWalker library: %@", MWObjectFromLuaStackIndex(state, -1)]];
    lua_pop(state, 1);
  } else {
    switch (lua_pcall(state, 0, 0, NULL)) {
      case 0:
        break;
      default:
        [owningContexts postDebugMessage:[NSString stringWithFormat:@"Could not run Lua MudWalker library: %@", MWObjectFromLuaStackIndex(state, -1)]];
        lua_pop(state, 1);
        break;
    }
  }
 
  return self;
}

#undef delete

- (void)dealloc {
  if (state)
    lua_close(state);
  state = nil;
  [super dealloc];
}

- (lua_State *)luaStateValue { return state; }

- (MWScriptContexts *)owningContexts { return owningContexts; }

@end

void MWPushObjectOnLuaStack(lua_State *state, id object) {
  if (!object) {
    lua_pushnil(state);
  } else if ([object isKindOfClass:[NSDictionary class]]) {
    lua_newtable(state);
    int ix = lua_gettop(state);
    NSEnumerator *keyE = [object keyEnumerator];
    id key;
    while ((key = [keyE nextObject])) {
      MWPushObjectOnLuaStack(state, key);
      MWPushObjectOnLuaStack(state, [object objectForKey:key]);
      lua_settable(state, ix);
    }
  } else if ([object isKindOfClass:[NSArray class]]) {
    lua_newtable(state);
    int ix = lua_gettop(state);
    NSEnumerator *valueE = [object objectEnumerator];
    int key = 1;
    id value;
    while ((value = [valueE nextObject])) {
      lua_pushnumber(state, key++);
      MWPushObjectOnLuaStack(state, value);
      lua_settable(state, ix);
    }
  } else if ([object isKindOfClass:[NSString class]]) {
    lua_pushlstring(state, [object lossyCString], [object cStringLength]);
  } else if ([object isKindOfClass:[NSNumber class]]) {
    lua_pushnumber(state, [object doubleValue]);
  } else {
    *(id *)lua_newuserdata(state, sizeof(id)) = [object retain];
    int ix = lua_gettop(state);
    lua_pushstring(state, "MudWalker ObjC Userdata Metatable");
    lua_gettable(state, LUA_REGISTRYINDEX);
    lua_setmetatable(state, ix);
  }
}

/* from lauxlib.c: convert a stack index to positive */
#define abs_index(L, i)		((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : \
					lua_gettop(L) + (i) + 1)

id MWObjectFromLuaStackIndex(lua_State *state, int ix) {
  id value;

  ix = abs_index(state, ix);
    
  switch (lua_type(state, ix)) {
    case LUA_TNIL:
    case LUA_TNONE:
      value = nil;
      break;
    case LUA_TNUMBER:
      value = [NSNumber numberWithDouble:lua_tonumber(state, ix)];
      break;
    case LUA_TBOOLEAN:
      value = [NSNumber numberWithBool:lua_tonumber(state, ix)];
      break;
    case LUA_TSTRING:
      value = [NSString stringWithCString:lua_tostring(state, ix) length:lua_strlen(state, ix)];
      break;
    case LUA_TTABLE: {
      value = [NSMutableDictionary dictionary];
      lua_pushnil(state);
      while (lua_next(state, ix) != 0) {
        [value setObject:MWObjectFromLuaStackIndex(state, -1) forKey:MWObjectFromLuaStackIndex(state, -2)];
        lua_pop(state, 1);
      }
      value = [[value copy] autorelease];
      break;
    }
    case LUA_TFUNCTION: {
      lua_CFunction cfunc = lua_tocfunction(state, ix);
      value = [NSValue valueWithBytes:&cfunc objCType:@encode(lua_CFunction)];
      break;
    }
    case LUA_TUSERDATA:
      value = [[*(id *)lua_touserdata(state, ix) retain] autorelease];
      break;
    case LUA_TLIGHTUSERDATA:
    case LUA_TTHREAD:
    default:
      value = [NSString stringWithFormat:@"<%s>", lua_typename(state, lua_type(state, ix))];
      break;
  }
  return value;
}

