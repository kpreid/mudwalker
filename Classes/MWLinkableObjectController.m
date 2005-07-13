/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLinkableObjectController.h"

#import "MWLinkableInspectorWinController.h"

@implementation MWLinkableObjectController

+ (MWLinkableObjectController *)locWithLinkable:(id <MWLinkable>)targ {
  return [[[self alloc] initWithLinkable:targ] autorelease];
}
- (MWLinkableObjectController *)initWithLinkable:(id <MWLinkable>)targ {
  if (!(self = [super init])) return nil;

  target = [targ retain];
  traceLog = [[NSTextStorage alloc] init];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lnTrace:) name:MWLinkableTraceNotification object:target];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [target release]; target = nil;
  [traceLog release]; traceLog = nil;
  [super dealloc];
}

// --- Notifications ---

- (void)lnTrace:(NSNotification *)notif {
  NSString *msg = [[notif userInfo] objectForKey:@"message"];
  
  NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    [[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]], NSFontAttributeName,
    nil
  ];

  if ([[[notif userInfo] objectForKey:@"important"] boolValue])
    [attrs setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
  [traceLog appendAttributedString:[[[NSAttributedString alloc] initWithString:msg attributes:attrs] autorelease]];
}

// --- Accessors for object properties ---

- (id <MWLinkable>)target {
  return target;
}

- (NSTextStorage *)traceStorage {
  return traceLog;
}

// --- Other ---

- (void)openView {
  MWLinkableInspectorWinController *inspectorWC;
  inspectorWC = [[[MWLinkableInspectorWinController alloc] init] autorelease];
  [inspectorWC setLOC:self];  
  [inspectorWC showWindow:nil];
}
- (void)openViewBesideWindow:(NSWindow *)win {
  MWLinkableInspectorWinController *inspectorWC;
  inspectorWC = [[[MWLinkableInspectorWinController alloc] init] autorelease];
  [inspectorWC setLOC:self];  
  [inspectorWC showWindowBesideWindow:win];
}

@end
