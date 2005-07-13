/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWColorSetConfigPane.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigSupplier.h>
#import <MudWalker/MWConfigTree.h>

@implementation MWColorSetConfigPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;

  [self setDirectory:[MWConfigPath pathWithComponent:@"ColorSets"]];
  
  return self;
}

- (NSString *)localizedItemName {
  return NSLocalizedString(@"ColorSetDirItem", nil);
}

- (NSDictionary *)keysForNewItem {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"new color set", @"Name",
    [[self displaySupplier] objectAtPath:[MWConfigPath pathWithComponents:@"ColorSets", @"builtin-on-white", @"ColorDictionary", nil]], @"ColorDictionary",
    nil
  ];
}

@end
