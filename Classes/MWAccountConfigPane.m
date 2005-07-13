/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWAccountConfigPane.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWUtilities.h>

@implementation MWAccountConfigPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;

  [self setDirectory:[[MWConfigPath alloc] initWithComponent:@"Accounts"]];
  
  return self;
}

- (NSString *)localizedItemName {
  return NSLocalizedString(@"AccountDirItem", nil);
}

- (NSDictionary *)keysForNewItem {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"unnamed", @"name",
    @"", @"username",
    @"", @"password",
    nil
  ];
}

@end
