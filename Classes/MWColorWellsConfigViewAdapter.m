/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWColorWellsConfigViewAdapter.h"

#import <MudWalker/MWConstants.h>

#import "MWColorConverter.h"

@implementation MWColorWellsConfigViewAdapter

#define COLOR_WELL_TAG_BASE 100

- (void)awakeFromNib {
  int tag;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    [[viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag] setContinuous:YES];
  }
}

- (id)valueFromControl {
  NSMutableDictionary *const newValue = [NSMutableDictionary dictionaryWithCapacity:MWCOLOR_MAXINDEX];
  unsigned int tag;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    NSColorWell *well = [viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag];
    //NSLog(@"%u %@", tag, MWColorNameForIndex(tag));
    [newValue setObject:well ? [well color] : [NSColor grayColor] forKey:MWColorNameForIndex(tag)];
  }
  return [[newValue copy] autorelease];
}
- (void)setValueInControl:(id)newVal {
  unsigned int tag;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    NSColorWell *const well = [viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag];
    
    if (well) {
      /* Due to interaction with NSColorPanel, color wells send their actions when their color is set if they are activated, which thoroughly hoses proper config view adapter behavior. Therefore, we temporarily disable the action. */
      [well setAction:NULL];
      [well setColor:newVal ? [newVal objectForKey:MWColorNameForIndex(tag)] : [NSColor whiteColor]];
      [well setAction:@selector(controlChangeAction:)];
    }
  }
}
- (void)setControlEnabled:(BOOL)newVal {
  unsigned int tag;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    NSColorWell *well = [viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag];
    [well setEnabled:newVal];
  }
}

- (void)setViewContainingColorWells:(id)newVal {
  unsigned int tag;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    [[viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag] setTarget:nil];
    [[viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag] setAction:NULL];
  }
  viewContainingColorWells = newVal;
  for (tag = 0; tag < MWCOLOR_MAXINDEX; tag++) {
    [[viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag] setTarget:self];
    [[viewContainingColorWells viewWithTag:COLOR_WELL_TAG_BASE + tag] setAction:@selector(controlChangeAction:)];
  }
  [self cvaUpdateFromConfig:nil];
}

@end
