/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinShapeView.h"

#import <MudWalker/MudWalker.h>
#import "MWTWinInterface.h"
#import "MWTWinViewCompatibility.h"

@implementation MWTWinShapeView

- (void)drawRect:(NSRect)rect {
  return;
  [[NSColor greenColor] set];
  [NSBezierPath setDefaultLineWidth:3];
  [NSBezierPath strokeRect:[self bounds]];
}

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;
  
  xpref = ypref = xstretch = ystretch = xshrink = yshrink = -1;
  
  return self;
}

- (void)twinComputePreferredSize {
  NSSize subPref, subStretch, subShrink;
  if ([[self subviews] count]) {
    NSView *subview = [[self subviews] objectAtIndex:0];
    subPref    = [subview twinPreferredSize];
    subStretch = [subview twinStretch];
    subShrink  = [subview twinShrink];
  } else {
    subPref = subStretch = subShrink = NSMakeSize(0, 0);
  }

  csPref = NSMakeSize(
    xpref != -1 ? xpref : subPref.width,
    ypref != -1 ? ypref : subPref.height);
  csStretch = NSMakeSize(
    xstretch != -1 ? xstretch : subStretch.width,
    ystretch != -1 ? ystretch : subStretch.height);
  csShrink = NSMakeSize(
    xshrink != -1 ? xshrink : subShrink.width,
    yshrink != -1 ? yshrink : subShrink.height);
}

- (void)twinPerformPhysicalLayout {
  NSRect myFrame = [self frame];
  NSView *subview = [[self subviews] count] ? [[self subviews] objectAtIndex:0] : nil;
  [subview twinSetFrameFromLayout:NSMakeRect(0, 0, myFrame.size.width, myFrame.size.height)];
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  if ((values = [attributes objectForKey:@"Width"])) {
    xpref = xstretch = xshrink = -1;
    [[values componentsJoinedByString:@" "] getTWinSize:&xpref stretch:&xstretch shrink:&xshrink];
  }
  if ((values = [attributes objectForKey:@"Height"])) {
    ypref = ystretch = yshrink = -1;
    [[values componentsJoinedByString:@" "] getTWinSize:&ypref stretch:&ystretch shrink:&yshrink];
  }
  if ((values = [attributes objectForKey:@"Value"]) && isRadio) {
    // delayed to make it work right on initial setup of form
    [self performSelector:@selector(twinInitialRadioSetup:) withObject:[values objectAtIndex:0] afterDelay:0];
    //[self performSelector:@selector(twinPropagateRadioState:) withObject:[[[self window] delegate] widgetNamed:[values objectAtIndex:0]] afterDelay:0.01];
  }
  [self performLayout:MWLayoutAttributesChanged];
  [super twinApplyFormAttributes:attributes];
}

- (void)twinInitialRadioSetup:(NSString *)name {
  [self twinPropagateRadioState:[[[self window] delegate] widgetNamed:name]];
}

- (void)twinConfigureAs:(NSString *)widget {
  if ([widget isEqual:@"Fill"]) {
    xpref = ypref = xstretch = xshrink = 0;
    xstretch = ystretch = MWTWinInfinity;
  } else if ([widget isEqual:@"Radio"]) {
    isRadio = YES;
  } else if ([widget isEqual:@"Shape"]) {
  }
}

- (void)twinPropagateRadioSelection:(NSView *)selected {
  MWTWinInterface *interface = [[self window] delegate];
  if (isRadio) {
    [interface sendTWinEvent:@"set" widgetView:self arguments:[NSDictionary dictionaryWithObjectsAndKeys:
      @"Value", @"attr",
      [interface nameOfWidget:selected], @"value",
      nil
    ]];
    [self twinPropagateRadioState:selected];
  } else {
    [super twinPropagateRadioSelection:selected];
  }
}

@end
