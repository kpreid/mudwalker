/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWGenericTableViewDataSource.h"

@implementation MWGenericTableViewDataSource

- (id)init {
  if (!(self = [super init])) return nil;
 
  columns = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [columns release]; columns = nil;
  [super dealloc];
}

// --- 

- (void)correctSizeOfColumn:(NSMutableArray *)col {
  unsigned count = [col count];
  while (count < rowCount) {
    [col addObject:@""];
    count++;
  }
  while (count > rowCount) {
    [col removeLastObject];
    count--;
  }
}

- (void)setRowCount:(int)rows {
  NSEnumerator *e = [columns objectEnumerator];
  NSMutableArray *col;
  rowCount = rows;
  
  while ((col = [e nextObject])) {
    [self correctSizeOfColumn:col];
  }
}

- (void)setColumn:(NSArray *)array forKey:(NSString *)identifier {
  NSMutableArray *col = [[array mutableCopy] autorelease];
  [self correctSizeOfColumn:col];
  [columns setObject:col forKey:identifier];
}

// --- Data source methods ---

- (int)numberOfRowsInTableView:(NSTableView *)table {
  return rowCount;
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  return [[columns objectForKey:[column identifier]] objectAtIndex:rowIndex];
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  NSEnumerator *e = [rows objectEnumerator];
  NSNumber *rowIndex = nil;
  NSMutableString *buf = [NSMutableString string];
  int i = 0, j;

  [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
  
  while ((rowIndex = [e nextObject])) {
    NSEnumerator *colE = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *col;
    j = 0;
    if (i++) [buf appendString:@"\n"];
    while ((col = [colE nextObject])) {
      if (j++) [buf appendString:@"\t"];
      [buf appendString:[[[columns objectForKey:[col identifier]] objectAtIndex:[rowIndex intValue]] description]];
    }
  }
  
  [pboard setString:buf forType:NSStringPboardType];
  return YES;
}

@end
