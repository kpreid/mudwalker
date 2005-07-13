/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWDisplayConfigPane.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigSupplier.h>

@implementation MWDisplayConfigPane

- (void)configChanged:(NSNotification *)notif {
  id <MWConfigSupplier> const config = [notif object];
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];

  if (!path || [path hasPrefix:[MWConfigPath pathWithComponent:@"ColorSets"] ]|| [path isEqual:[MWConfigPath pathWithComponent:@"SelectedColorSet"]]) {
    NSMutableArray *colorSets = [[[config allKeysAtPath:[MWConfigPath pathWithComponent:@"ColorSets"]] mutableCopy] autorelease];

    if (!colorSets) colorSets = [NSMutableArray array];

    [cColorSetPopup removeAllItems];
    
    NSEnumerator *const keyE = [colorSets objectEnumerator];
    NSString *key;
    while ((key = [keyE nextObject])) {
      NSString *itemName = [config objectAtPath:[MWConfigPath pathWithComponents:@"ColorSets", key, @"Name", nil]];
      if (!itemName) itemName = @"";
      
      NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:itemName action:NULL keyEquivalent:@""] autorelease];
      [item setRepresentedObject:key];
      [[cColorSetPopup menu] addItem:item];
    }
    
    [cColorSetAdapter cvaUpdateFromConfig:nil];
  }
}

@end