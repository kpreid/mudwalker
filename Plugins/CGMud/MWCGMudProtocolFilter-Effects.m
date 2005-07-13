/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudProtocolFilter.h"

#import "MWCGMudCommon.h"
#import "MWCGMudGUIController.h"
#import "MWCGMudGraphicsView.h"
#import "MWCGMudIconsView.h"

#import "CGMud/Mud.h"
#import "CGMud/Effects.h"

static char effectTypeNames[ef_last + 1][32] = {
  "ef_null",
  "ef_Else",
  "ef_Fi",
  "ef_IfFound",
  "ef_FailText",
  "ef_Abort",
  "ef_Call",
  "ef_PlaceCursor",
  "ef_PlaceCursorShort",
  "ef_RemoveCursor",
  "ef_SetCursorPen",
  "ef_SetCursorPattern",
  "ef_AddButton",
  "ef_EraseButton",
  "ef_ClearButtons",
  "ef_AddRegion",
  "ef_EraseRegion",
  "ef_ClearRegions",
  "ef_SetButtonPen",
  "ef_SetPen",
  "ef_SetColour",
  "ef_ResetColours",
  "ef_Clear",
  "ef_Pixel",
  "ef_PixelRow",
  "ef_AMove",
  "ef_AMoveShort",
  "ef_RMove",
  "ef_RMoveShort",
  "ef_ADraw",
  "ef_ADrawShort",
  "ef_RDraw",
  "ef_RDrawShort",
  "ef_Rectangle",
  "ef_Circle",
  "ef_Ellipse",
  "ef_PolygonStart",
  "ef_PolygonEnd",
  "ef_DefineTile",
  "ef_DefineOverlayTile",
  "ef_DisplayTile",
  "ef_SetTextColour",
  "ef_Text",
  "ef_LoadBackGround",
  "ef_SetImage",
  "ef_ShowImage",
  "ef_ShowImagePixels",
  "ef_ShowBrush",
  "ef_ScrollRectangle",
  "ef_SetIconPen",
  "ef_NewIcon",
  "ef_ShowIcon",
  "ef_RemoveIcon",
  "ef_DeleteIcon",
  "ef_ResetIcons",
#if REDRAW_ICONS
  "ef_RedrawIcons",
  "ef_UndrawIcons",
#endif
  "ef_SoundVolume",
  "ef_PlaySound",
  "ef_Params",
  "ef_VReset",
  "ef_VoiceVolume",
  "ef_Narrate",
  "ef_MusicVolume",
  "ef_PlaySong",
  "ef_last"
};

// Trickery: We want EFFECT_TRACE to lack extraneous arguments, so we stick the current effect-processing object in a global variable for the duration of -processEffects:.
// It would be a Bad Idea to access currentEffectProcessor outside of -processEffects:, as it's pointing to a possibly deallocated object. This system could definitely use improvement.
static MWCGMudProtocolFilter *currentEffectProcessor = nil;

static __inline__ void EFFECT_TRACE(const char *format, ...) {
  va_list args;
  va_start(args, format);
  [currentEffectProcessor linkableTraceMessage:[[[NSString alloc] initWithFormat:[NSString stringWithCString:format] arguments:args] autorelease]];
  va_end(args);
}

static NSMutableArray *defaultPens = nil;

@interface MWCGMudProtocolFilter (EffectsPrivate)

- (void)setCursorData:(NSData *)data;

@end

@implementation MWCGMudProtocolFilter (MWCGMudProtocolFilterEffects)

+ (void)initializeEffects {
  float rd, gr, bl;
  defaultPens = [[NSMutableArray alloc] init];
  // code copied from the Java client
  for (rd = 0; rd < 6; rd += 1) {
    for (gr = 0; gr < 7; gr += 1) {
      for (bl = 0; bl < 6; bl += 1) {
        [defaultPens addObject:[NSColor colorWithCalibratedRed:rd / 5 green:gr / 6 blue:bl / 5 alpha:1]];
  } } }
  [defaultPens addObject:[NSColor colorWithCalibratedWhite:(float)0x44/255 alpha:1]];
  [defaultPens addObject:[NSColor colorWithCalibratedWhite:(float)0x88/255 alpha:1]];
  [defaultPens addObject:[NSColor colorWithCalibratedWhite:(float)0xcc/255 alpha:1]];
  [defaultPens addObject:[NSColor colorWithCalibratedWhite:(float)0xff/255 alpha:1]];
  assert([defaultPens count] == CGMUD_PEN_COUNT);
}

- (void)initializeEffectsState {
  effectsCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
  pens = [defaultPens mutableCopyWithZone:[self zone]];
  textAttributes = [[NSDictionary allocWithZone:[self zone]] initWithObjectsAndKeys:
    cFont ? cFont : [[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]], NSFontAttributeName,
    nil
  ];
  iconCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
  tileCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
  activeEffects = [[NSMutableDictionary allocWithZone:[self zone]] init];
  soundRepeats = [[NSMutableDictionary allocWithZone:[self zone]] init];
}

- (void)resetEffectsState {
  [effectsCache removeAllObjects];
  // fixme: remove all regions here
  [pens autorelease];
  pens = [defaultPens mutableCopy];
  [activeImage autorelease];
  activeImage = nil;
  [iconCache removeAllObjects];
  [tileCache removeAllObjects];
}

- (NSImage *)effectImageResource:(NSString *)filename {
  /* fixme: ought to cache images so we don't 1. access the HD a lot, 2. waste time */
  NSString *path = [[MWRegistry defaultRegistry] pathForResourceFromSearchPath:[NSString stringWithFormat:@"CGMud/Images/%@", filename]];
  return path ? [[[NSImage alloc] initWithContentsOfFile:path] autorelease] : nil;
}

- (NSSound *)effectSoundResource:(NSString *)filename {
  /* fixme: ought to cache sounds so we don't 1. access the HD a lot, 2. waste time */
  NSString *path = [[MWRegistry defaultRegistry] pathForResourceFromSearchPath:[NSString stringWithFormat:@"CGMud/Sounds/%@", filename]];
  return path ? [[[NSSound alloc] initWithContentsOfFile:path byReference:YES] autorelease] : nil;
}

- (NSImage *)activeImage { return activeImage; }
- (void)setActiveImage:(NSImage *)img {
  [activeImage autorelease];
  activeImage = [img retain];
}

- (NSImage *)convertBitmap:(NSData *)bitmap toImageColored:(NSColor *)color {
  unsigned int size = sqrt([bitmap length] * 8);
  NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size pixelsHigh:size bitsPerSample:8 samplesPerPixel:4 hasAlpha:1 isPlanar:0 colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
  NSImage *img = [[[NSImage alloc] initWithSize:NSMakeSize(size, size)] autorelease];
  uint32_t *pixels; // NOTE that this is 4 bytes per element
  const uint8_t *scan = [bitmap bytes];
  if ((pixels = (uint32_t *)[rep bitmapData])) {
    int i, bit;
    for (i = 0; i < [bitmap length]; i++) {
      // NOTE that endianness doesn't matter since it's all-ones or all-zeros
      for (bit = 0; bit < 8; bit++) 
        pixels[i*8 + bit] = (scan[i] & (1<<(7 - bit))) ? 0xFFFFFFFF : 0x00000000;
    }
  }
  [rep colorizeByMappingGray:0.5 toColor:color blackMapping:color whiteMapping:color];
  [img addRepresentation:rep];
  return img;
}

#define common_andAdvancePointer \
  if (*scan > end - size) { \
    [self linkableErrorMessage:@"Effect bytecode ended unexpectedly"]; \
    return 0; \
  } \
  *scan += size;
  
#define common_args MWCGMudProtocolFilter *self, unsigned const char **scan, unsigned const char *end

static NSString * readCStringAndAdvancePointer(common_args) {
  unsigned const char *stringStart = *scan;
  NSString *result = nil;
  NSData *data = nil;
  size_t length = 0;

  while (**scan != 0 && *scan <= end) { (*scan)++; length++; }
  data = [NSData dataWithBytes:stringStart length:length];
  result = [[[NSString alloc] initWithData:data encoding:CGMUD_ENCODING] autorelease];
  if (*scan < end) (*scan)++;
  return result;
}

static uint8_t read_uint8_andAdvancePointer(common_args) {
  const int size = 1;
  common_andAdvancePointer
  return *(*scan - size);
}

static uint16_t read_uint16_andAdvancePointer(common_args) {
  const int size = 2;
  common_andAdvancePointer
  return ntohs(*( (uint16_t *)(*scan - size) ));
}

static uint32_t read_uint32_andAdvancePointer(common_args) {
  const int size = 4;
  common_andAdvancePointer
  return ntohl(*( (uint32_t *)(*scan - size) ));
}

#undef common_andAdvancePointer
#undef common_args

#define efRead_uint8()  read_uint8_andAdvancePointer (self, &scan, end)
#define efRead_uint16() read_uint16_andAdvancePointer(self, &scan, end)
#define efRead_uint32() read_uint32_andAdvancePointer(self, &scan, end)
#define efRead_int8()   read_uint8_andAdvancePointer (self, &scan, end)
#define efRead_int16()  read_uint16_andAdvancePointer(self, &scan, end)
#define efRead_int32()  read_uint32_andAdvancePointer(self, &scan, end)
#define efRead_String()  readCStringAndAdvancePointer(self, &scan, end)
#define efParam_uint8(sym)  uint8_t  sym = read_uint8_andAdvancePointer (self, &scan, end)
#define efParam_uint16(sym) uint16_t sym = read_uint16_andAdvancePointer(self, &scan, end)
#define efParam_uint32(sym) uint32_t sym = read_uint32_andAdvancePointer(self, &scan, end)
#define efParam_int8(sym)    int8_t  sym = read_uint8_andAdvancePointer (self, &scan, end)
#define efParam_int16(sym)   int16_t sym = read_uint16_andAdvancePointer(self, &scan, end)
#define efParam_int32(sym)   int32_t sym = read_uint32_andAdvancePointer(self, &scan, end)
#define efParam_String(sym) NSString *sym = readCStringAndAdvancePointer(self, &scan, end)

#define EXECUTION if (!execute || controlSkip) break; else ;
#define EXECUTION_IFLESS if (!execute) break; else ;
#define GRAPHICS if (!doGraphics) {[self linkableErrorMessage:@"Graphics effect in non-graphics component"]; break; } else ;
- (void)processEffects:(NSData *)bytecode component:(uint32_t)component {
  MWCGMudGUIController *guiController = [self probe:@selector(lpGUICustomController:) ofLinkFor:@"inward"];
  NSView *compView = [guiController viewForIdentifier:[NSNumber numberWithUnsignedInt:component]];
  unsigned const char *scan = [bytecode bytes];
  unsigned const char *end = scan + [bytecode length];
  float vRange = [compView bounds].size.height;
  BOOL execute = YES;
  BOOL failFlag = NO;
  BOOL controlSkip = NO;
  BOOL insideIf = NO;
  BOOL doGraphics = [compView isKindOfClass:[MWCGMudGraphicsView class]];
  NSBezierPath *polygon = nil;
  
  currentEffectProcessor = self;
  if (!bytecode) { EFFECT_TRACE("nil "); return; }
  
  if (doGraphics) {
    [(MWCGMudGraphicsView *)compView lockFocusForModification];
  }
  [[pens objectAtIndex:currentPen] set];
  [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
  [NSBezierPath setDefaultLineJoinStyle:NSMiterLineJoinStyle];
  EFFECT_TRACE("{ ");
  while (scan < end) {
    // note that we increment scan NOW, so the effect code can read the values it's interested
    unsigned char effect = *(scan++);
    if (effect > ef_last) effect = ef_last;
    
    EFFECT_TRACE("%s", effectTypeNames[effect] + 3);
    // above skips over the effect code, individual handlers are in charge of skipping over the arguments
    switch (effect) {
      case ef_null:
        break;
     
      case ef_IfFound:
        EXECUTION_IFLESS;
        insideIf = YES;
        controlSkip = failFlag; // will skip till else/endif if fail flag set
        break;
        
      case ef_Else:
        EXECUTION_IFLESS;
        controlSkip = !controlSkip;
        break;
        
      case ef_Fi:
        EXECUTION_IFLESS;
        insideIf = NO;
        controlSkip = NO;
        break;
        
      case ef_FailText: {
        efParam_String(text);
        EFFECT_TRACE("('%s')", [text cString]);
        EXECUTION;
        if (failFlag) {
          [self localMessage:[NSString stringWithFormat:@"<<%@>>", text]];
        }
        break;
      }
    
      case ef_Abort: {
        id theEffect;
        efParam_uint8(type);
        efParam_uint32(effID);
        EFFECT_TRACE("(%u, %u)", type, effID);
        EXECUTION;
        theEffect = [activeEffects objectForKey:[NSNumber numberWithUnsignedInt:effID]];
        if ([theEffect isKindOfClass:[NSSound class]]) {
          [(NSSound *)theEffect stop];
        } else {
          // fixme: complain
        }
        break;
      }
    
      case ef_Call: {
        efParam_uint32(subID);
        EFFECT_TRACE("(%u)", subID);
        EXECUTION;
        [self processEffects:[effectsCache objectForKey:[NSNumber numberWithUnsignedLong:subID]] component:component];
        break;
      }
        
      case ef_PlaceCursor: {
        efParam_uint16(x);
        efParam_uint16(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        [(MWCGMudGraphicsView *)compView setCursorLocation:NSMakePoint(x, y)];
        break;
      }
        
      case ef_PlaceCursorShort: {
        efParam_uint8(x);
        efParam_uint8(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        [(MWCGMudGraphicsView *)compView setCursorLocation:NSMakePoint(x, y)];
        break;
      }
        
      case ef_RemoveCursor:
        EXECUTION;
        GRAPHICS;
        [(MWCGMudGraphicsView *)compView setCursorLocation:NSMakePoint(-1, -1)];
        break;
      
      case ef_SetCursorPen: {
        efParam_uint16(newPen);
        EFFECT_TRACE("(%i)", currentCursorPen);
        EXECUTION;
        GRAPHICS;
        currentCursorPen = newPen;
        [(MWCGMudGraphicsView *)compView setCursorImage:[self convertBitmap:cursorData toImageColored:[pens objectAtIndex:currentCursorPen]]];
        break;
      }
      
      case ef_SetCursorPattern: {
        scan += 32;
        EXECUTION;
        GRAPHICS;
        [self setCursorData:[NSData dataWithBytes:scan - 32 length:32]];
        [(MWCGMudGraphicsView *)compView setCursorImage:[self convertBitmap:cursorData toImageColored:[pens objectAtIndex:currentCursorPen]]];
        break;
      }
      
      case ef_AddButton: {
        efParam_uint16(x);
        efParam_uint16(y);
        efParam_uint16(bID);
        NSButton *button;
        NSString *titleString;
        NSSize size;
        
        titleString = efRead_String();
        
        EFFECT_TRACE("(%i,%i i%i '%s')", x, y, bID, [titleString cString]);
        EXECUTION;
        
        size = [titleString sizeWithAttributes:textAttributes];
        size.width += 9;
        size.height += 4;
        
        button = [[[NSButton alloc] initWithFrame:NSMakeRect(0,0,1,1)] autorelease];
        [button setTitle:titleString];
        [button setButtonType:NSMomentaryPushButton];
        [button setBezelStyle:NSShadowlessSquareBezelStyle];
        [button setImagePosition:NSNoImage];
        [button setFont:[textAttributes objectForKey:NSFontAttributeName]];
        [[button cell] setControlSize:NSSmallControlSize];
        [button setFrameSize:size];
        [button setFrameOrigin:NSMakePoint(x, vRange - y - size.height)];
        [button setTarget:[self probe:@selector(lpGUICustomController:) ofLinkFor:@"inward"]];
        [button setAction:@selector(serverButtonPressed:)];
        
        [guiController addView:button withID:[NSString stringWithFormat:@"%u-Button-%u", component, bID] inID:[NSNumber numberWithUnsignedInt:component]];
        break;
      }
      
      case ef_EraseButton: {
        efParam_uint16(bID);

        EFFECT_TRACE("(%i)", bID);
        EXECUTION;

        {
          NSView *view = [guiController viewForIdentifier:[NSString stringWithFormat:@"%u-Button-%u", component, bID]];
          
          if (view) {
            [guiController forgetView:view];
            [view removeFromSuperview];
          }
        }

        break;
      }
      
      case ef_ClearButtons: {
        EFFECT_TRACE("()");
        EXECUTION;
      
        {
          NSView *view = [guiController viewForIdentifier:[NSNumber numberWithUnsignedInt:component]];
          NSEnumerator *e = [[view subviews] objectEnumerator];
          NSView *subview = nil;
          
          while ((subview = [e nextObject])) {
            [guiController forgetView:subview];
            [subview removeFromSuperview];
          }
        }
        break;
      }
      
      case ef_AddRegion: {
        efParam_uint16(x);
        efParam_uint16(y);
        efParam_uint16(w);
        efParam_uint16(h);
        efParam_uint16(rID);
        
        EFFECT_TRACE("({%u, %u, %u, %u} i%i)", x, y, w, h, rID);
        EXECUTION;
        GRAPHICS;
        [[(MWCGMudGraphicsView *)compView regions] setObject:[NSValue valueWithRect:NSMakeRect(x, y, w, h)] forKey:[NSNumber numberWithUnsignedInt:rID]];
        break;
      }
        
      case ef_EraseRegion: {
        efParam_uint16(rID);
        
        EFFECT_TRACE("(%u)", rID);
        EXECUTION;
        GRAPHICS;
        [[(MWCGMudGraphicsView *)compView regions] removeObjectForKey:[NSNumber numberWithUnsignedInt:rID]];
        break;
      }
      
      case ef_ClearRegions:
        EXECUTION;
        GRAPHICS;
        [[(MWCGMudGraphicsView *)compView regions] removeAllObjects];
        break;
      
      case ef_SetButtonPen:
        // this sets the colors used for drawing buttons. as we're using system controls for the buttons, this is not applicable.
        scan += 4;
        EXECUTION;
        GRAPHICS;
        break;
      
      case ef_SetPen: {
        efParam_uint16(newPen);
        EFFECT_TRACE("(%i)", newPen);
        EXECUTION;
        currentPen = newPen;
        [[pens objectAtIndex:currentPen] set];
        break;
      }
      
      case ef_SetColour: {
        efParam_uint16(penID);
        efParam_uint16(color);

        EFFECT_TRACE("(%u, %03x)", penID, color);
        EXECUTION;
        [pens replaceObjectAtIndex:penID withObject:[NSColor colorWithCalibratedRed:(color >> 8) & 0xF green:(color >> 4) & 0xF blue:(color >> 0) & 0xF alpha:1]];
        if (currentPen == penID) [[pens objectAtIndex:currentPen] set];
        break;
      }
      
      case ef_ResetColours: {
        EXECUTION;
        [pens release];
        pens = [defaultPens mutableCopy];
        [[pens objectAtIndex:currentPen] set];
        break;
      }
      
      case ef_Clear:
        EXECUTION;
        GRAPHICS;
        [[pens objectAtIndex:0] set];
        [NSBezierPath fillRect:[compView bounds]];
        break;

      case ef_Pixel:
        EXECUTION;
        GRAPHICS;
        [NSBezierPath fillRect:NSMakeRect(currentPosition.x, currentPosition.y, 1, 1)];
        break;
                
      case ef_AMove: {
        efParam_uint16(x);
        efParam_uint16(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        currentPosition = NSMakePoint(x, y);
        if (polygon) [polygon moveToPoint:currentPosition];
        break;
      }
      
      case ef_AMoveShort: {
        efParam_uint8(x);
        efParam_uint8(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        currentPosition = NSMakePoint(x, y);
        if (polygon) [polygon moveToPoint:currentPosition];
        break;
      }
      
      // Note that for ef_R*, the arguments are *SIGNED*.
      
      case ef_RMove: {
        efParam_int16(x);
        efParam_int16(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        currentPosition.x += x;
        currentPosition.y += y;
        if (polygon) [polygon moveToPoint:currentPosition];
        break;
      }
      
      case ef_RMoveShort: {
        efParam_int8(x);
        efParam_int8(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        currentPosition.x += x;
        currentPosition.y += y;
        if (polygon) [polygon moveToPoint:currentPosition];
        break;
      }
      
      case ef_ADraw: {
        efParam_uint16(x);
        efParam_uint16(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        if (polygon) {
          [polygon lineToPoint:NSMakePoint(x, y)];
        } else {
          [NSBezierPath strokeLineFromPoint:NSMakePoint(currentPosition.x + 0.5, currentPosition.y + 0.5)
            toPoint:NSMakePoint(x+0.5, y+0.5)];
        }
        currentPosition.x = x;
        currentPosition.y = y;
        break;
      }
      
      case ef_ADrawShort: {
        efParam_uint8(x);
        efParam_uint8(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        if (polygon) {
          [polygon lineToPoint:NSMakePoint(x, y)];
        } else {
          [NSBezierPath strokeLineFromPoint:NSMakePoint(currentPosition.x + 0.5, currentPosition.y + 0.5)
            toPoint:NSMakePoint(x+0.5, y+0.5)];
        }
        currentPosition.x = x;
        currentPosition.y = y;
        break;
      }
      
      case ef_RDraw: {
        efParam_int16(x);
        efParam_int16(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        if (polygon) {
           [polygon lineToPoint:NSMakePoint(currentPosition.x+x, currentPosition.y+y)];
        } else {
          [NSBezierPath strokeLineFromPoint:NSMakePoint(currentPosition.x + 0.5, currentPosition.y + 0.5)
            toPoint:NSMakePoint(currentPosition.x+x+0.5, currentPosition.y+y+0.5)];
        }
        currentPosition.x += x;
        currentPosition.y += y;
        break;
      }
      
      case ef_RDrawShort: {
        efParam_int8(x);
        efParam_int8(y);
        EFFECT_TRACE("(%i, %i)", x, y);
        EXECUTION;
        GRAPHICS;
        if (polygon) {
           [polygon lineToPoint:NSMakePoint(currentPosition.x+x, currentPosition.y+y)];
        } else {
          [NSBezierPath strokeLineFromPoint:NSMakePoint(currentPosition.x + 0.5, currentPosition.y + 0.5)
            toPoint:NSMakePoint(currentPosition.x+x+0.5, currentPosition.y+y+0.5)];
        }
        currentPosition.x += x;
        currentPosition.y += y;
        break;
      }
      
      case ef_Rectangle: {
        efParam_uint16(w);
        efParam_uint16(h);
        efParam_uint8(fill);
        NSRect rect = NSMakeRect(currentPosition.x, currentPosition.y, w, h);
        
        EFFECT_TRACE("(%u, %u)", w, h);
        EXECUTION;
        GRAPHICS;
        if (fill) [NSBezierPath fillRect:rect];
             else [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
        
        break;
      }
        
      case ef_Circle: {
        efParam_uint16(r);
        efParam_uint8(fill);
        NSRect rect = NSMakeRect(currentPosition.x - r, currentPosition.y - r, r*2, r*2);
        
        EFFECT_TRACE("(%u, %s)", r, (fill ? "fill" : "stroke"));
        EXECUTION;
        GRAPHICS;
        if (fill) [[NSBezierPath bezierPathWithOvalInRect:rect] fill];
             else [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)] stroke];
        
        break;
      }

      case ef_Ellipse: {
        efParam_uint16(w);
        efParam_uint16(h);
        efParam_uint8(fill);
        NSRect rect = NSMakeRect(currentPosition.x - w, currentPosition.y - h, w*2, h*2);
        
        EFFECT_TRACE("(%u, %u, %s)", w, h, (fill ? "fill" : "stroke"));
        EXECUTION;
        GRAPHICS;
        if (fill) [[NSBezierPath bezierPathWithOvalInRect:rect] fill];
             else [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)] stroke];
        
        break;
      }
      
      case ef_PolygonStart:
        EFFECT_TRACE("[");
        EXECUTION;
        GRAPHICS;
        polygon = [NSBezierPath bezierPath];
        break;
      
      case ef_PolygonEnd:
        EFFECT_TRACE("]");
        EXECUTION;
        GRAPHICS;
        if (polygon) {
          [polygon closePath];
          [polygon fill];
        }
        polygon = nil;
        break;
        
      // NOTE that this is a unified handler for two different effects with slightly different parameters
      case ef_DefineTile: case ef_DefineOverlayTile: {
        efParam_uint16(tID);
        int16_t transparentColor = -1;
        uint8_t w, h;
        if (effect == ef_DefineOverlayTile)
          transparentColor = efRead_uint16();
        w = efRead_uint8();
        h = efRead_uint8();
        scan += w * h;
        
        EFFECT_TRACE("(i%u, tc=%u, %ux%u)", tID, transparentColor, w, h);
        EXECUTION;
        if (!w || !h) {
          [self linkableErrorMessage:@"Error: got ef_defineTile with zero width or height"];
        } else {
          uint8_t x, y;
          NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:4 samplesPerPixel:4 hasAlpha:1 isPlanar:0 colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:16] autorelease];
          NSImage *tileImage = [[[NSImage alloc] initWithSize:NSMakeSize(w, h)] autorelease];
          const uint8_t *inPens = scan - w * h;
          uint16_t *outPixels = (uint16_t *)[rep bitmapData];
          for (x = 0; x < w; x++) { for (y = 0; y < h; y++) {
            uint8_t pen = inPens[x + y * w];
            NSColor *pColor = [[pens objectAtIndex:pen] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            uint8_t cR = [pColor redComponent] * 0xF,
                    cG = [pColor greenComponent] * 0xF,
                    cB = [pColor blueComponent] * 0xF;
            outPixels[x + y * w] = htons(
                (cR << 12)
              | (cG << 8)
              | (cB << 4)
              | (pen == transparentColor ? 0x0 : 0xF)
            );
          }}
          [tileImage addRepresentation:rep];
          [tileImage setFlipped:YES];
          [tileCache setObject:tileImage forKey:[NSNumber numberWithUnsignedInt:tID]];
        }
        break;
      }
      
      case ef_DisplayTile: {
        efParam_uint16(tID);
        NSImage *theImage = [tileCache objectForKey:[NSNumber numberWithUnsignedInt:tID]];
        EFFECT_TRACE("(i%u)", tID);
        EXECUTION;
        GRAPHICS;
        [theImage drawAtPoint:currentPosition fromRect:NSMakeRect(0, 0, [theImage size].width, [theImage size].height) operation:NSCompositeSourceOver fraction:1];
        break;
      }
      
      case ef_SetTextColour:
        // no longer used, on Amiga it set colors for text component
        scan += 4;
        EXECUTION;
        GRAPHICS;
        break;
      
      case ef_Text: {
        efParam_String(text);
        NSMutableDictionary *attr = [[textAttributes mutableCopy] autorelease];
        EFFECT_TRACE("('%s')", [text cString]);
        EXECUTION;
        GRAPHICS;
        [attr setObject:[pens objectAtIndex:currentPen] forKey:NSForegroundColorAttributeName];
        [text drawAtPoint:NSMakePoint((int)currentPosition.x + 0.5, (int)currentPosition.y + 0.5 - effectsInfo.ei_fontHeight) withAttributes:attr];
        break;
      }

      case ef_LoadBackGround: {
        efParam_String(filename);
        NSImage *image;
        EFFECT_TRACE("('%s')", [filename cString]);
        EXECUTION;
        GRAPHICS;
        image = [self effectImageResource:filename];
        [image compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeCopy];
        failFlag = !image;
        break;
      }

      case ef_SetImage: {
        efParam_String(filename);
        NSImage *image;
        EFFECT_TRACE("('%s')", [filename cString]);
        EXECUTION;
        GRAPHICS;
        image = [self effectImageResource:filename];
        if (image) {
          [image setFlipped:YES];
          [self setActiveImage:image];
        }
        EFFECT_TRACE("=%i", !!image);
        failFlag = !image;
        break;
      }
      
      case ef_ShowImagePixels: {
        efParam_String(name);
        NSImage *image;
        efParam_uint16(srcX);
        efParam_uint16(srcY);
        efParam_uint16(srcW);
        efParam_uint16(srcH);
        efParam_uint16(dstX);
        efParam_uint16(dstY);
        EFFECT_TRACE("('%s', %ux%u, %ux%u, %ux%u)", [name cString], srcX, srcY, srcW, srcH, dstX, dstY);
        EXECUTION;
        GRAPHICS;
        if ([name length]) image = [self effectImageResource:name];
                      else image = [self activeImage];
        EFFECT_TRACE("=%i", !!image);
        [image drawAtPoint:NSMakePoint(dstX, dstY + [image size].height) fromRect:NSMakeRect(srcX, srcY, srcW, srcH) operation:NSCompositeCopy fraction:1];
        break;
      }
      
        // fix2float
#define F2F(f) ((float)(f) / (1<<16))
      case ef_ShowImage: {
        efParam_String(name);
        NSImage *image;
        // proto.doc is totally unhelpful on what these parameters really are 
        efParam_uint32(isrcX);
        efParam_uint32(isrcY);
        efParam_uint32(isrcW);
        efParam_uint32(isrcH);
        efParam_uint32(idstX);
        efParam_uint32(idstY);
        efParam_uint32(idstW);
        efParam_uint32(idstH);
        EFFECT_TRACE("('%s', %.1fx%.1f, %.1fx%.1f, %.1fx%.1f, %.1fx%.1f)", [name cString], F2F(isrcX), F2F(isrcY), F2F(isrcW), F2F(isrcH), F2F(idstX), F2F(idstY), F2F(idstW), F2F(idstH));
        EXECUTION;
        GRAPHICS;
        if ([name length]) image = [self effectImageResource:name];
                      else image = [self activeImage];
        EFFECT_TRACE("=%i", !!image);
        if (image) {
          NSSize iSize = [image size],
                 vSize = [compView bounds].size;
          float srcX = F2F(isrcX * iSize.width), srcY = F2F(isrcY * iSize.height),
                srcW = F2F(isrcW * iSize.width), srcH = F2F(isrcH * iSize.height),
                dstX = F2F(idstX * vSize.width), dstY = F2F(idstY * vSize.height),
                dstW = F2F(idstW * vSize.width), dstH = F2F(idstH * vSize.height);
          [image drawInRect:NSMakeRect(dstX, dstY, dstW, dstH) fromRect:NSMakeRect(srcX, srcY, srcW, srcH) operation:NSCompositeCopy fraction:1];
        }
        break;
      }
#undef F2F
        
      case ef_ShowBrush: {
        efParam_String(name);
        scan += 4;
        EFFECT_TRACE("('%s')", [name cString]);
        EXECUTION;
        GRAPHICS;
        // fixme
        failFlag = YES;
        break;
      }
        
      case ef_ScrollRectangle: {
        efParam_int16(deltaX);
        efParam_int16(deltaY);
        efParam_uint16(minX);
        efParam_uint16(minY);
        efParam_uint16(sizeX);
        efParam_uint16(sizeY);
        EFFECT_TRACE("(Æ%ix%i, {%ux%u, %ux%u})", deltaX, deltaY, minX, minY, sizeX, sizeY);
        EXECUTION;
        GRAPHICS;
        NSCopyBits([compView gState], NSMakeRect(minX, minY, sizeX, sizeY), NSMakePoint(minX + deltaX, minY + deltaY));
        break;
      }
        
      case ef_SetIconPen: {
        efParam_uint16(newIconPen);
        EFFECT_TRACE("(%i)", newIconPen);
        EXECUTION;
        currentIconPen = newIconPen;
        break;
      }
        
      case ef_NewIcon: {
        efParam_uint32(iconID);
        scan += 32;
        EFFECT_TRACE("(i%u)", iconID);
        EXECUTION;
        // OK, in order to get icon colors reasonably updated, what we do is keep the raw bitmap data in the cache, and only convert it to a colorized image when we show it.
        [iconCache setObject:[NSData dataWithBytes:scan - 32 length:32] forKey:[NSNumber numberWithUnsignedInt:iconID]];
        break;
      }
        
      case ef_ShowIcon: {
        efParam_uint32(iconID);
        efParam_uint8(generic);
        NSData *iconData;
        EFFECT_TRACE("(i%u, %i)", iconID, generic);
        EXECUTION;
        iconData = [iconCache objectForKey:[NSNumber numberWithUnsignedInt:iconID]];
        if (!iconData) {
          // for now, break. later, implement generic icon
          break;
        }
        //printf("debug: imaging icon using color %s\n", [[[pens objectAtIndex:currentIconPen] description] cString]);
        [[guiController iconsView] addIcon:[NSNumber numberWithUnsignedInt:iconID] image:[self convertBitmap:iconData toImageColored:[pens objectAtIndex:currentIconPen]]];
        break;
      }
        
      case ef_RemoveIcon: {
        efParam_uint32(iconID);
        EFFECT_TRACE("(i%u)", iconID);
        EXECUTION;
        [[guiController iconsView] removeIcon:[NSNumber numberWithUnsignedInt:iconID]];
        break;
      }
        
      case ef_DeleteIcon: {
        efParam_uint32(iconID);
        EFFECT_TRACE("(i%u)", iconID);
        EXECUTION;
        [iconCache removeObjectForKey:[NSNumber numberWithUnsignedInt:iconID]];
        [[guiController iconsView] removeIcon:[NSNumber numberWithUnsignedInt:iconID]];
        break;
      }
        
      case ef_ResetIcons:
        EXECUTION;
        // Contrary to proto.doc, ResetIcons should not forget icons, just hide them
        [[guiController iconsView] removeAllIcons];
        break;
        
      case ef_SoundVolume: {
        efParam_uint16(newVolume);
        EFFECT_TRACE("(%i)", newVolume);
        EXECUTION;
        // fixme
        break;
      }
        
      case ef_PlaySound: {
        NSSound *sound = nil;
        efParam_String(filename);
        efParam_uint32(effID);
        efParam_uint16(repeats);
        EFFECT_TRACE("('%s' x %i i%i)", [filename cString], repeats, effID);
        EXECUTION;
        // We copy the sound so that changing the delegate etc. doesn't affect anything else
        sound = [[[self effectSoundResource:filename] copy] autorelease];
        if (sound) {
          [sound setDelegate:self];
          [sound play];
          [activeEffects setObject:sound forKey:[NSNumber numberWithUnsignedInt:effID]];
          [soundRepeats setObject:[NSNumber numberWithUnsignedInt:repeats] forKey:MWKeyFromObjectIdentity(sound)];
        }
        // fixme: complain if it doesn't exist
        break;
      }
        
      case ef_Params: {
        efParam_uint16(rate);
        efParam_uint16(pitch);
        efParam_uint8(mode);
        efParam_uint8(sex);
        efParam_uint8(volume);
        EFFECT_TRACE("(%u %u %u %u %u)", rate, pitch, mode, sex, volume);
        EXECUTION;
        // fixme
        break;
      }
        
      case ef_VReset:
        EXECUTION;
        // fixme
        break;
        
      case ef_VoiceVolume:
        scan += 2;
        EXECUTION;
        // fixme
        break;
        
      case ef_Narrate: {
        efParam_String(text);
        efParam_uint32(effID);
        EFFECT_TRACE("('%s', i%i)", [text cString], effID);
        EXECUTION;
        break;
      }
        
      case ef_MusicVolume:
        scan += 2;
        EXECUTION;
        // fixme
        break;
        
      case ef_PlaySong: {
        efParam_String(name);
        efParam_uint32(effID);
        EFFECT_TRACE("('%s', i%i)", [name cString], effID);
        EXECUTION;
        break;
      }
        
      default: 
        [self linkableErrorMessage:[NSString stringWithFormat:@"don't understand effect %s, ending parse", effectTypeNames[effect]]];
        EFFECT_TRACE(" ...");
        scan = end;
    }
    EFFECT_TRACE(" ");
  }
  EFFECT_TRACE("} ");
  if (doGraphics) {
    [(MWCGMudGraphicsView *)compView unlockFocusForModification];
  }
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finished {
  id key = MWKeyFromObjectIdentity(sound);
  unsigned int repeats = [[soundRepeats objectForKey:key] unsignedIntValue];
  if (repeats > 1 && finished) {
    [soundRepeats setObject:[NSNumber numberWithUnsignedInt:repeats - 1] forKey:key];
    [sound play];
  } else {
    [soundRepeats removeObjectForKey:key];
  }
}

- (void)setCursorData:(NSData *)v; {
  [v retain];
  [cursorData release];
  cursorData = v;
}

@end
