/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTriggerConfigPane.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigSupplier.h>
#import <MudWalker/MWConfigTree.h>

@implementation MWTriggerConfigPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle mwConfigTarget:target configParent:parent])) return nil;

  [self setDirectory:[MWConfigPath pathWithComponent:@"Triggers"]];
  
  return self;
}

- (void)mainViewDidLoad {
  NSButtonCell *cell = [[[NSButtonCell alloc] init] autorelease];

  [super mainViewDidLoad];
  
  [cell setButtonType:NSSwitchButton];
  [cell setImagePosition:NSImageOnly];
  [cell setControlSize:NSSmallControlSize];

  [[[ccDirectory tableColumns] objectAtIndex:[ccDirectory columnWithIdentifier:@"active"]] setDataCell:cell];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  NSString *cid = [column identifier];
  NSString *key = [[self displaySupplier] keyAtIndex:rowIndex inDirectoryAtPath:[self directory]];
  if ([cid isEqualToString:@"active"])
    return [NSNumber numberWithBool:![[[self displaySupplier] objectAtPath:[[[self directory] pathByAppendingComponent:key] pathByAppendingComponent:@"inactive"]] boolValue]];
  else
    return [super tableView:sender objectValueForTableColumn:column row:rowIndex];
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  NSString *cid = [column identifier];
  NSString *key = [[self displaySupplier] keyAtIndex:rowIndex inDirectoryAtPath:[self directory]];

  if ([cid isEqualToString:@"active"])
    [[self configTarget] setObject:[NSNumber numberWithBool:![newVal boolValue]] atPath:[[[self directory] pathByAppendingComponent:key] pathByAppendingComponent:@"inactive"]];
  else
    [super tableView:sender setObjectValue:newVal forTableColumn:column row:rowIndex];
}

- (NSString *)localizedItemName {
  return NSLocalizedString(@"TriggerDirItem", nil);
}

- (NSDictionary *)keysForNewItem {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"new trigger", @"name",
    @"", @"patterns",
    nil
  ];
}

@end
