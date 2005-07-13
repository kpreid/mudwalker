/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

#define CGMUD_PEN_COUNT 256

// bleh. I'd rather not include this, but I need the definition of EffectsInfo_t
#import "CGMud/Mud.h"
#import "CGMud/Effects.h"

// see the #import at the end

@class MWLinearLayoutView, MWCGMudIconsView, MWCGMudGraphicsView;

@interface MWCGMudProtocolFilter : MWConcreteLinkable <MWPlugin> {
  // Configuration
  NSFont *cFont;

  // Protocol data
  int state;
  NSMutableData *messageBuffer;
  
  // Application data
  EffectsInfo_t effectsInfo;
  unsigned long sessionKey;
  BOOL inWizardMode;
  BOOL inGetString;
  
  // Effects data
  NSDictionary *textAttributes;
  NSMutableDictionary *effectsCache;
  
  NSMutableArray *pens;
  int currentPen, currentCursorPen, currentIconPen;
  NSData *cursorData;
  NSPoint currentPosition;
  
  NSImage *activeImage;
  
  NSMutableDictionary *tileCache;
  NSMutableDictionary *iconCache;

  NSMutableDictionary *activeEffects;
  NSMutableDictionary *soundRepeats;
}

- (NSValue *)lpEffectsInfo:(NSString *)link;

@end

#import "MWCGMudProtocolFilter-Effects.h"
