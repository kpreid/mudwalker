/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudGraphicsView.h"

#import "MWCGMudMessage.h"
#import "MWCGMudGUIController.h"
#import "MWCGMudGraphicsBackingView.h"

#import "CGMud/Mud.h"
#import "CGMud/Request.h"
#import "CGMud/Effects.h"

@implementation MWCGMudGraphicsView

- (id)initWithFrame:(NSRect)frame {
  NSWindow *backingWindow;

  if (!(self = [super initWithFrame:frame])) return nil;

  backingWindow = [[[NSWindow alloc] initWithContentRect:[self bounds] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
  [backingWindow setDynamicDepthLimit:NO];
  [backingWindow setDepthLimit:NSBestDepth(NSCalibratedRGBColorSpace, 0, 0, 0, NULL)];
  [backingWindow setContentView:[[[MWCGMudGraphicsBackingView alloc] initWithFrame:[self bounds]] autorelease]];

  backingImageRep = [[NSCachedImageRep allocWithZone:[self zone]] initWithWindow:backingWindow rect:[self bounds]];

  regions = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [backingImageRep autorelease]; backingImageRep = nil;
  [delegate autorelease]; delegate = nil;
  [cursorImage autorelease]; cursorImage = nil;
  [regions autorelease]; regions = nil;
  [super dealloc];
}

- (void)drawRect:(NSRect)rect {
  [backingImageRep draw];
  if (cursorLocation.x != -1) [cursorImage compositeToPoint:NSMakePoint(cursorLocation.x, [self bounds].size.height - cursorLocation.y - [cursorImage size].height) operation:NSCompositeSourceOver fraction:1];
}

- (void)mouseDown:(NSEvent *)event {
  NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
  loc.y = [self bounds].size.height - loc.y;

  {
    NSEnumerator *e = [regions keyEnumerator];
    NSNumber *regionIDNumber;
    
    // The Java client sends the lowest-numbered region. However, the scenario source comments seem to imply that this behavior (sending for ALL regions intersected) is OK. 
    
    while ((regionIDNumber = [e nextObject])) {
      NSRect regionRect = [[regions objectForKey:regionIDNumber] rectValue];
      if (!NSPointInRect(loc, regionRect)) break;
  
      {
        NSMutableData *tail = [NSMutableData data];
        uint16_t relX = loc.x - regionRect.origin.x,
                 relY = loc.y - regionRect.origin.y;
        uint16_t viewIdentifier = [[delegate identifierForView:self] unsignedIntValue];
        [self linkableTraceMessage:[NSString stringWithFormat:@"Clicked on region %u of view %u at %u, %u", [regionIDNumber unsignedIntValue], viewIdentifier, relX, relY]];
        [tail appendBytes:&relX length:2];
        [tail appendBytes:&relY length:2];
        [delegate send:[MWCGMudMessage messageWithType:rt_regionSelect key:[regionIDNumber unsignedIntValue] flag:0 uint:viewIdentifier tail:tail] toLinkFor:@"outward"]; // fixme: delegate should do this itself
      }
    }
  }
}

- (void)resetCursorRects {
  //[self addCursorRect:[self bounds] cursor:handCursor];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
  return YES;
}

// --- Special methods ---

- (void)lockFocusForModification {
  [[[backingImageRep window] contentView] lockFocus];
}

- (void)unlockFocusForModification {
  [[[backingImageRep window] contentView] unlockFocus];
  [self setNeedsDisplay:YES];
}

- (void)setCursorImage:(NSImage *)image {
  [cursorImage autorelease];
  cursorImage = [image retain];
  [self setNeedsDisplay:YES];
}

- (void)setCursorLocation:(NSPoint)loc {
  cursorLocation = loc;
  [self setNeedsDisplay:YES];
}

- (NSMutableDictionary *)regions { return regions; }
- (MWCGMudGUIController *)delegate { return delegate; }
- (void)setDelegate:(MWCGMudGUIController *)obj {
  [delegate autorelease];
  delegate = [obj retain];
}

@end
