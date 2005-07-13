/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTriggerEnablePanelWinController.h"

#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigSupplier.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConstants.h>
#import <MudWalker/MWUtilities.h>

#import "MWConnectionDocument.h"

static MWConfigPath *directory;

@interface MWTriggerEnablePanelWinController (Private)

- (void)setTargetDocument:(MWConnectionDocument *)doc;
- (id <MWConfigSupplier>)config;

@end

@implementation MWTriggerEnablePanelWinController

+ (void)initialize {
  if (!directory)
    directory = [[MWConfigPath alloc] initWithComponent:@"Triggers"];
}

- (id)init {
  if (!(self = [super initWithWindowNibName:@"TriggerEnablePanel"])) return self;
  
  [self setShouldCascadeWindows:NO];
  [self setWindowFrameAutosaveName:NSStringFromClass([self class])];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:[self config]];
  [targetDocument autorelease]; targetDocument = nil;
  [super dealloc];
}


- (void)mainWindowChanged:(NSNotification *)notif {
  NSDocument *doc = [[notif object] document];
  [self setTargetDocument:[doc respondsToSelector:@selector(configLocalStore)]
                            ? (MWConnectionDocument *)doc
                            : nil];
}

- (void)mainWindowResigned:(NSNotification *)notif {
  [self setTargetDocument:nil];
}

- (void)windowDidLoad {
  [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];

  [super windowDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];

  [self mainWindowChanged:[NSNotification notificationWithName:NSWindowDidBecomeMainNotification object:[NSApp mainWindow]]];

}

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];
  
  if (!path || [path hasPrefix:directory]) {
    [self window];
    [triggerTable reloadData];
  }
}

- (void)setTargetDocument:(MWConnectionDocument *)doc {
  NSDocument *oldConfig = [targetDocument config];
  if (oldConfig) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:oldConfig];
  }

  [targetDocument autorelease];
  targetDocument = [doc retain];

  if (doc) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:[doc config]];
  }

  [self configChanged:[NSNotification notificationWithName:MWConfigSupplierChangedNotification object:[doc config]]];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  return [NSString stringWithFormat:MWLocalizedStringHere(@"TriggerEnablePanelTitle%@"), displayName];
}

- (id <MWConfigSupplier>)config { return [targetDocument config]; }

// --- Table view data source ---

- (int)numberOfRowsInTableView:(NSTableView *)sender {
  id <MWConfigSupplier> config = [self config];

  return [config countAtPath:directory];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  id <MWConfigSupplier> config = [self config];

  NSString *cid = [column identifier];
  NSString *key = [[config allKeysAtPath:directory] objectAtIndex:rowIndex];
  if ([cid isEqualToString:@"active"])
    return [NSNumber numberWithBool:![[config objectAtPath:[[directory pathByAppendingComponent:key] pathByAppendingComponent:@"inactive"]] boolValue]];
  else
    return [config objectAtPath:[[directory pathByAppendingComponent:key] pathByAppendingComponent:cid]];
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)newVal forTableColumn:(NSTableColumn *)column row:(int)rowIndex {
  MWConfigTree *configLocalStore = [targetDocument configLocalStore];
  NSString *cid = [column identifier];
  NSString *key = [[self config] keyAtIndex:rowIndex inDirectoryAtPath:directory];

  if ([cid isEqualToString:@"active"]) {
    newVal = [NSNumber numberWithBool:![newVal boolValue]];
    cid = @"inactive";
  }
    
  MWConfigPath *fieldPath = [[directory pathByAppendingComponent:key] pathByAppendingComponent:cid];
  
  if (![[configLocalStore objectAtPath:fieldPath] isEqual:newVal]) {
    [configLocalStore addDirectoryAtPath:[directory pathByAppendingComponent:key] recurse:YES insertIndex:-1];
    [configLocalStore setObject:newVal atPath:fieldPath];
    [[configLocalStore undoManager] setActionName:[NSString stringWithFormat:MWLocalizedStringHere(@"DirectoryChangeValue%@"), MWLocalizedStringHere(@"TriggerDirItem")]];
  }
}


@end
