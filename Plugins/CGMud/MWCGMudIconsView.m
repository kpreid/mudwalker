/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudIconsView.h"

#include <math.h>

#define SCALE_MAX 10
#define PADDING 2

#define INTERVAL 0.25 / SCALE_MAX

@implementation MWCGMudIconsView

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;

  iconOrdering = [[NSMutableArray allocWithZone:[self zone]] init];
  iconImages = [[NSMutableDictionary allocWithZone:[self zone]] init];
  iconStates = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [iconOrdering release]; iconOrdering = nil;
  [iconImages release]; iconImages = nil;
  [iconStates release]; iconStates = nil;
  [super dealloc];
}

- (void)drawRect:(NSRect)rect {
  NSEnumerator *e = [iconOrdering reverseObjectEnumerator];
  id iconID;
  float pos = PADDING;
  float width = [self bounds].size.height - PADDING * 2;
  
  while ((iconID = [e nextObject])) {
    NSImage *img = [iconImages objectForKey:iconID];
    NSNumber *istate = [iconStates objectForKey:iconID];
    int iscale = abs(istate ? [istate intValue] : SCALE_MAX);
    float uscale = (float)iscale / SCALE_MAX;
    
    //printf("istate = %i, uscale = %f\n", [istate intValue], uscale);
    if (!img) break;
    [img drawInRect:NSMakeRect(pos, PADDING + width*(1-uscale)/2, width*uscale, width*uscale) fromRect:NSMakeRect(0, 0, [img size].width, [img size].height) operation:NSCompositeSourceOver fraction:uscale];
    pos += width * uscale + PADDING;
  }
}

- (void)makeAnimTimer {
  // NOTE that if two icons are added, or removed, there will be two anim timers, making the animation occur twice as fast (if possible). This is deliberate.
  [NSTimer scheduledTimerWithTimeInterval:INTERVAL
    target:self
    selector:@selector(animateIcons:)
    userInfo:nil
    repeats:YES
  ];
}

// --- Special methods ---

- (void)animateIcons:(NSTimer *)timer {
  NSEnumerator *e = [[iconStates allKeys] objectEnumerator];
  id iconID;
  
  if (![iconStates count]) {
    [timer invalidate];
    return;
  }

  while ((iconID = [e nextObject])) {
    int istate = [[iconStates objectForKey:iconID] intValue];
    if (istate < 0) {
      istate++;
      if (istate >= 0) {
        [iconStates removeObjectForKey:iconID];
        [iconImages removeObjectForKey:iconID];
        [iconOrdering removeObject:iconID];
      } else {
        [iconStates setObject:[NSNumber numberWithInt:istate] forKey:iconID];
      }
    } else {
      istate++;
      if (istate >= SCALE_MAX) {
        [iconStates removeObjectForKey:iconID];
      } else {
        [iconStates setObject:[NSNumber numberWithInt:istate] forKey:iconID];
      }
    }
  }
  
  // now we recompute the frame
  {
    float pos = PADDING;
    float width = [self bounds].size.height - PADDING * 2;
    e = [iconOrdering objectEnumerator];
    
    while ((iconID = [e nextObject])) {
      NSNumber *istate = [iconStates objectForKey:iconID];
      int iscale = abs(istate ? [istate intValue] : SCALE_MAX);
      float uscale = (float)iscale / SCALE_MAX;
      pos += width * uscale + PADDING;
    }
    [self setFrameSize:NSMakeSize(pos, [self frame].size.height)];
  }
  
  [self setNeedsDisplay:YES];
}

// Setting the state for the added/removed icon needs to consider that the icon may be already present/absent/appearing/disappearing

- (void)addIcon:(id)iconID image:(NSImage *)img {
  if (![iconImages objectForKey:iconID]) [iconOrdering insertObject:iconID atIndex:(
    ([iconOrdering count] + 1) * ((float)random() / (float) LONG_MAX)
  )];
  [iconImages setObject:img forKey:iconID];
  if ([[iconStates objectForKey:iconID] intValue] <= 0) [iconStates setObject:[NSNumber numberWithInt:0] forKey:iconID];
  [self makeAnimTimer];
}

- (void)removeIcon:(id)iconID {
  NSNumber *oldValue = [iconStates objectForKey:iconID];
  if (!oldValue) [iconStates setObject:[NSNumber numberWithInt:-SCALE_MAX] forKey:iconID];
  else if ([oldValue intValue] >= 0) [iconStates setObject:[NSNumber numberWithInt:-[oldValue intValue]] forKey:iconID];
  [self makeAnimTimer];
}

- (void)removeAllIcons {
  NSEnumerator *e = [[iconImages allKeys] objectEnumerator];
  id iconID;
  while ((iconID = [e nextObject])) {
    [self removeIcon:iconID];
  }
}

@end
