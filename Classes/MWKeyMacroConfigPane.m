/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWKeyMacroConfigPane.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWUtilities.h>
#import <MWAppKit/MWKeyCodeCell.h>

@implementation MWKeyMacroConfigPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;

  [self setDirectory:[[MWConfigPath alloc] initWithComponent:@"KeyCommands"]];
  
  return self;
}

- (void)mainViewDidLoad {
  NSTableColumn *col = [[[self directoryTableView] tableColumns] objectAtIndex:[[self directoryTableView] columnWithIdentifier:@"__DIRECTORY__"]];
  MWKeyCodeCell *cell = [[[MWKeyCodeCell alloc] init] autorelease];
  NSTextFieldCell *oldCell = [col dataCell];

  [cell setAlignment:[oldCell alignment]];
  [cell setFont:[oldCell font]];
  [cell setEditable:YES];
  [col setDataCell:cell];

  [super mainViewDidLoad];
}

- (NSString *)localizedItemName {
  return NSLocalizedString(@"KeyMacroDirItem", nil);
}

- (NSDictionary *)keysForNewItem {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"", @"command",
    nil
  ];
}

@end
