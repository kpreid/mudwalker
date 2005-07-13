/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinLinearLayoutView.h"

#import <MudWalker/MudWalker.h>
#import "MWTWinViewCompatibility.h"

@implementation MWTWinLinearLayoutView

- (void)drawRect:(NSRect)rect {
  return;
  [[NSColor redColor] set];
  [NSBezierPath setDefaultLineWidth:3];
  [NSBezierPath strokeRect:[self bounds]];
}

- (void)twinComputePreferredSize {
  NSEnumerator *e = [[self subviews] objectEnumerator];
  MWTWinLayoutView *subview;
  float minimum = 0, maximum = MWTWinInfinity;
  
  csPref = NSMakeSize(0, 0);
  csStretch = NSMakeSize(0, 0);
  csShrink = NSMakeSize(0, 0);
  
  while ((subview = [e nextObject])) {
    NSSize subPref = [subview twinPreferredSize],
           subStretch = [subview twinStretch],
           subShrink = [subview twinShrink];
    float subMin, subMax;
    
    //printf("%s pref = %f %f, stretch = %f %f, shrink = %f %f\n", [[subview description] cString], subPref.width, subPref.height, subStretch.width, subStretch.height, subShrink.width, subShrink.height);
    
#define PER_SUBVIEW_CODE(DIMA, DIMB) \
      subMin = subPref.DIMB - subShrink.DIMB; \
      subMax = subPref.DIMB + subStretch.DIMB; \
      csPref.DIMA += subPref.DIMA; \
      csStretch.DIMA += subStretch.DIMA; \
      csShrink.DIMA += subShrink.DIMA; \
      if (subPref.DIMB > csPref.DIMB) csPref.DIMB = subPref.DIMB;
     
    if (vertical) {
      PER_SUBVIEW_CODE(height, width)
    } else {
      PER_SUBVIEW_CODE(width, height)
    }
    if (subMin > minimum) minimum = subMin;
    if (subMax < maximum) maximum = subMax;
  }

#define SIZE_LAST_CODE(DIMA, DIMB) \
  if (maximum < minimum) maximum = minimum; \
  if (1 && csPref.DIMB > maximum) csPref.DIMB = maximum; \
  if (1 && csPref.DIMB < minimum) csPref.DIMB = minimum; \
  csStretch.DIMB = maximum - csPref.DIMB; \
  csShrink.DIMB = csPref.DIMB - minimum;

  if (vertical) {
    SIZE_LAST_CODE(height, width)
  } else {
    SIZE_LAST_CODE(width, height)
  }
  
  if (csShrink.width > csPref.width) csShrink.width = csPref.width;
  if (csShrink.height > csPref.height) csShrink.height = csPref.height;
  //printf("v%i, total pref = %f %f, stretch = %f %f, shrink = %f %f, min B = %f, max B = %f\n\n\n", vertical, csPref.width, csPref.height, csStretch.width, csStretch.height, csShrink.width, csShrink.height, minimum, maximum);

}
 
static __inline__ NSSize MWAddSize(NSSize a, NSSize b) { 
  NSSize s;
  s.width = a.width + b.width;
  s.height = a.height + b.height;
  return s;
}
static __inline__ NSSize MWSubSize(NSSize a, NSSize b) {
  NSSize s;
  s.width = a.width - b.width;
  s.height = a.height - b.height;
  return s;
}
 
- (void)twinPerformPhysicalLayout {
  NSArray *subviews = [self subviews];
  NSSize pSize = [self bounds].size;
  unsigned numSubviews = [subviews count];

  int totalPref = 0, totalStretch = 0, totalShrink = 0;
  int goalSize = !vertical ? pSize.width : pSize.height;

#define primaryDimOf(v, dim) (vertical ? [v dim].height : [v dim].width)

  { int i;
    for (i = 0; i < numSubviews; i++) {
      MWTWinLayoutView *subview = [subviews objectAtIndex:i];
      int pref = primaryDimOf(subview, twinPreferredSize);
      int stretch = primaryDimOf(subview, twinStretch);
      int shrink = primaryDimOf(subview, twinShrink);
      totalPref += pref < 0 ? 0 : pref;
      totalStretch += stretch < 0 ? 0 : stretch;
      totalShrink += shrink < 0 ? 0 : shrink;
    }
  }
  {
    double curLength = 0;
    int deltaFromPref = goalSize - totalPref;
    BOOL stretching = deltaFromPref > 0;
    int maxVariance = (stretching ? totalStretch : totalShrink);
    double fraction = (double)deltaFromPref / (double)(maxVariance ? maxVariance : numSubviews);
  
    //printf("v %i delta %i stretching %i fraction %f t+ %i t- %i\n", vertical, deltaFromPref, stretching, fraction, totalStretch, totalShrink);
   
#define LAYOUT_CODE(POSA, POSB, DIMA, DIMB) do { \
  MWTWinLayoutView *subview = [subviews objectAtIndex:i]; \
  int pref = primaryDimOf(subview, twinPreferredSize); \
  int stretch = primaryDimOf(subview, twinStretch); \
  int shrink = primaryDimOf(subview, twinShrink); \
  NSRect sf = {{0,0},pSize}; \
  sf.origin.POSA = curLength; \
  sf.size.DIMA = pref + (maxVariance ? (double)(stretching ? stretch : shrink) : 1) * fraction; \
  curLength += sf.size.DIMA; \
  sf.origin.POSA = (unsigned)sf.origin.POSA; \
  sf.size.DIMA = (unsigned)sf.size.DIMA; \
  [subview twinSetFrameFromLayout:sf]; \
} while(0) 

    { 
      int i;
  
      if (vertical) {
        for (i = numSubviews-1; i >= 0; i--)
          LAYOUT_CODE(y, x, height, width);
      } else {
        for (i = 0; i < numSubviews; i++)
          LAYOUT_CODE(x, y, width, height);
      }
    }
  }
}

- (void)twinConfigureAs:(NSString *)widget {
  [self setVertical:[widget isEqual:@"VBox"]];
}

- (BOOL)isVertical { return vertical; }
- (void)setVertical:(BOOL)val {
  vertical = val;
  [self performLayout:MWLayoutAttributesChanged];
}

@end
