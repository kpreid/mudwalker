/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWDocumentSettings.h"

#import <MudWalker/MudWalker.h>
#import <AppKit/AppKit.h>

@implementation MWDocumentSettings

- (NSDictionary *)convertToDictionaryForStorage {
  NSEnumerator *enumerator = [self keyEnumerator];
  id key;
  NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:[self count]];

  while ((key = [enumerator nextObject])) {
    id value = [self objectForKey:key];
    [resultDict setObject:[[value copy] autorelease] forKey:key];
  }
  return resultDict;
}

- (void)restoreFromDictionaryForStorage:(NSDictionary *)dict {
  NSEnumerator *enumerator = [dict keyEnumerator];
  id key;
  NSParameterAssert(dict != nil);
  
  // Old documents had some of the values stored as archived or stringified objects, so we need to unarchive them if they are.
  
  [[self undoManager] disableUndoRegistration];
  while ((key = [enumerator nextObject])) {
    id value = [dict objectForKey:key];
    //printf("Loading setting %s\n", [key cString]);
    if ([key isEqualToString:@"Address"] && [value isKindOfClass:[NSString class]]) {
      [self setObject:[NSURL URLWithString:value] forKey:key];
    } else if ([key isEqualToString:@"Colors"]) {
      // For backward compatibility, we extend the array as needed
      NSMutableArray *colors = [[(
        [value isKindOfClass:[NSArray class]] ? value : [NSUnarchiver unarchiveObjectWithData:value]
      ) mutableCopy] autorelease];
      while ([colors count] - 1 < MWCOLOR_MAXINDEX) [colors addObject:[NSColor grayColor]];
      [self setObject:colors forKey:key];
    } else {
      [self setObject:value forKey:key];
    }
  }
  [[self undoManager] enableUndoRegistration];
}

// --- Scripting support ---

- (id)valueForKey:(NSString *)key {
  id v;
  if ((v = [self objectForKey:key]))
    return v;
  else
    return [super valueForKey:key];
}

- (void)takeValue:(id)newVal forKey:(NSString *)key {
  if ([self objectForKey:key] || [[[self class] defaultSettings] objectForKey:key])
    [self setObject:newVal forKey:key];
  else
    return [super takeValue:newVal forKey:key];
}

// --- Dictionary primitive methods ---

- (id)objectForKey:(id)key {
  id value;
  value = [super objectForKey:key];
  if (!value) value = [[[self class] defaultSettings] objectForKey:key];
  return value;
}

+ (NSDictionary *)defaultSettings {
  static NSDictionary *ds = nil;
  
  if (!ds) {
    NSColor *black = [NSColor blackColor];
    NSColor *white = [NSColor whiteColor];
    NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];

    [md setObject:[NSNumber numberWithInt:NO] forKey:@"AutoConnect"];
    [md setObject:[NSNumber numberWithInt:20000] forKey:@"ScrollbackCharacters"];
    [md setObject:[NSNumber numberWithFloat:0] forKey:@"TextWrapIndent"];
    [md setObject:[NSFont userFixedPitchFontOfSize:9] forKey:@"TextFontMonospaced"];
    [md setObject:[[NSFontManager sharedFontManager] convertWeight:YES ofFont:[NSFont userFontOfSize:[NSFont labelFontSize]]] forKey:@"TextFontProportional"];
    [md setObject:[NSURL URLWithString:@""] forKey:@"Address"];
    [md setObject:@"\r\n" forKey:@"LineEnding"];
    [md setObject:[NSNumber numberWithUnsignedInt:0x8000020F /* Latin-9 */] forKey:@"CharEncoding"];
    [md setObject:[NSNumber numberWithFloat:0.7] forKey:MWConfigureTelnetPromptTimeout];
    [md setObject:[[[NSAttributedString alloc] initWithString:@"" attributes:[NSDictionary dictionary]] autorelease] forKey:MWConfigureLoginScript];
    [md setObject:[[[NSAttributedString alloc] initWithString:@"quit\n@quit\n" attributes:[NSDictionary dictionary]] autorelease] forKey:MWConfigureLogoutScript];
    
  #define DC(c) [[NSColor c##Color] blendedColorWithFraction:0.5 ofColor:black]
  #define NC(c) [[NSColor c##Color] blendedColorWithFraction:0.3 ofColor:black]
  #define LC(c) [NSColor c##Color]
  #define XLC(c) [[NSColor c##Color] blendedColorWithFraction:0.5 ofColor:white]
  #define XC    [NSColor grayColor]
    [md setObject:[NSArray arrayWithObjects:
      /* normal, bright, dim, special */
      /* See MWConstants.h for what these mean */
      NC(black), NC(red), NC(green), NC(yellow), NC(blue), NC(magenta), NC(cyan), NC(white), NC(white), NC(black),
      LC(black), LC(red), LC(green), LC(yellow), LC(blue), LC(magenta), LC(cyan), LC(white), LC(white), LC(black),
      DC(black), DC(red), DC(green), DC(yellow), DC(blue), DC(magenta), DC(cyan), DC(white), DC(white), DC(black),
      NC(orange),NC(green),XLC(blue),XC,         XC,       XC,          XC,       XC,        XC,        XC,        
      nil
    ] forKey:@"Colors"];
  #undef DC
  #undef NC
  #undef LC
  #undef XLC
  #undef XC
    [md setObject:[NSNumber numberWithInt:YES] forKey:@"ColorBrightColor"];
    [md setObject:[NSNumber numberWithInt:NO] forKey:@"ColorBrightBold"];
    
    ds = [md copy];
  }
  
  return ds;
}

@end
