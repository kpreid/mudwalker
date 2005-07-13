/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinInterface.h"

#import "MWMCProtocolFilter.h"
#import "MWMCPMessage.h"

#import <MWAppKit/MWGenericTableViewDataSource.h>

#import "MWTWinViewCompatibility.h"

#import "MWTWinLinearLayoutView.h"
#import "MWTWinShapeView.h"
#import "MWTWinSpaceView.h"
#import "MWTWinWindowContentView.h"

#import <Foundation/NSDebug.h>

@interface MWTWinInterface (Private)

- (void)parseForm:(NSString *)form;
- (void)updateAckInfo;

- (NSWindow *)window;
- (void)setWindow:(NSWindow *)newVal;

@end

@implementation MWTWinInterface

- (MWTWinInterface *)init {
  if (!(self = [super init])) return nil;
  
  widgets = [[NSMutableDictionary allocWithZone:[self zone]] init];
  revWidgets = [[NSMutableDictionary allocWithZone:[self zone]] init];

  return self;
}

- (void)dealloc {
  //printf("twin interface deallocated\n");
  [widgets autorelease]; widgets = nil;
  [revWidgets autorelease]; revWidgets = nil;
  if (!dontCloseWindow) [window close];
  [window autorelease]; window = nil;
  [super dealloc];
}

// --- Window delegate ---

- (void)windowWillClose:(NSNotification *)notif {
  dontCloseWindow = YES;
  [self unlinkAll];
}

- (void)windowDidResize:(NSNotification *)notif {
  [(MWTWinWindowContentView *)[[self window] contentView] twinRecursivePerformPhysicalLayout];
}

// --- Linkage & MCP cord ---

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", nil]; }

- (void)linkPrune {
  if (![[self links] objectForKey:@"outward"]
      || ![[self window] isVisible]
  ) {
    //printf("twin interface pruning (%u)\n", [self retainCount]);
    if (!dontCloseWindow) [[self window] close];
    [self unlinkAll];
    //printf("twin interface pruned (%u)\n", [self retainCount]);
  }
}

- (void)handleTWinSetEvent:(NSDictionary *)args {
  NSView *widget = [widgets objectForKey:[args objectForKey:@"widget"]];
  NSString *attr = [args objectForKey:@"attr"];
  NSString *value = [args objectForKey:@"value"];
  NSArray *values = nil;
  NSScanner *scan = [NSScanner scannerWithString:value];

  [self linkableTraceMessage:[NSString stringWithFormat:@"set w=%@ a=%@ v=%@\n", widget, attr, value]];
  
  [scan mwSetCharactersToBeSkippedToEmptySet];
  if (!([scan scanTWinSExpressionIncludingType:NO into:&values])) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"(couldn't parse '%@')\n", value]];
  }
  
  if (![values isKindOfClass:[NSArray class]]) values = [NSArray arrayWithObject:values];
  
  [widget twinApplyFormAttributes:[NSDictionary dictionaryWithObject:values forKey:attr]];
}

- (void)handleTWinAppendEvent:(NSDictionary *)args {
  NSView *widget = [widgets objectForKey:[args objectForKey:@"widget"]];

  if ([widget respondsToSelector:@selector(twinEventAppend:)])
    [widget twinEventAppend:args];
  else
     [self linkableErrorMessage:[NSString stringWithFormat:@"Widget '%@' %@ got append event, but didn't understand it.", widget, [args objectForKey:@"widget"]]];
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)linkName {
  NSString *message = nil;
  NSDictionary *args = nil;
  BOOL noAck = NO;

  if (![obj isKindOfClass:[MWMCPMessage class]]) return NO;
  message = [(MWMCPMessage *)obj messageName];
  args = obj;

  dontSendChanges = YES;
  NS_DURING
    if ([message isEqual:@"create"]) {
      [self parseForm:[args objectForKey:@"form"]];
      
    } else if ([message isEqual:@"event"]) {
      NSString *type = [args objectForKey:@"event"];

      receivedCount++;
      [self updateAckInfo];
    
      // if we get more event types, then should use a dictionary for dispatching ?
      if ([type isEqualToString:@"set"]) {
        [self handleTWinSetEvent:args];
      } else if ([type isEqualToString:@"append"]) {
        [self handleTWinAppendEvent:args];
      } else {
        [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown TWin event type: '%@'", type]];
      }
    
      // event message may have an 'ack' argument
      if ([args objectForKey:@"ack"]) {
        ackedSentCount = [[args objectForKey:@"ack"] intValue];
        [self updateAckInfo];
      }
      
    } else if ([message isEqual:@"ack"]) {
      ackedSentCount = [[args objectForKey:@"messages"] intValue];
      [self updateAckInfo];
      noAck = YES;
      
    } else {
      [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown TWin cord message type: '%@'", message]];
    }
    dontSendChanges = NO;
  NS_HANDLER
    // ...how about a finally block?
    dontSendChanges = NO;
    [localException raise];
  NS_ENDHANDLER
  
  // send ack message, if needed
  if (!noAck) {
    [self send:[MWMCPMessage messageWithName:@"ack" arguments:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%lu", receivedCount] forKey:@"messages"]] toLinkFor:@"outward"];
  }
  return YES;
}

- (NSView *)recursiveCreateFormWidget:(NSArray *)sexp {
  NSRect zf = {{0, 0}, {0, 0}};
  NSString *type = nil;
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  int i = 0;
  id createSpec = nil;
  BOOL dontAddSubviewsNormally = NO;
  NSView *view = nil, *nameView = nil;
  
  NSParameterAssert([sexp count] >= 2);
  
  if (![[sexp objectAtIndex:i++] isEqual:@"["]) [NSException raise:NSInvalidArgumentException format:@"Form translation: expected [] list, got %@", sexp];
  type = [sexp objectAtIndex:i++];

  for (; i < [sexp count]; i++) {
    NSArray *att = [sexp objectAtIndex:i];
    if (![[att objectAtIndex:0] isEqual:@"("]) break;
    [attributes setObject:[att subarrayWithRange:MWMakeABRange(2, [att count])] forKey:[att objectAtIndex:1]];
  }
  
  createSpec = [[MWTWinWidgetData objectForKey:@"ClassMap"] objectForKey:type];
  
  if ([createSpec isEqual:@"__Special__"]) {
    if ([type isEqualToString:@"Window"]) {
      NSWindow *w = [[[NSWindow alloc] initWithContentRect:NSMakeRect(300,300,300,300) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
      [self setWindow:w];
      view = [[[MWTWinWindowContentView alloc] initWithFrame:zf] autorelease];
      
      [w setContentView:view];
      [w setDelegate:self];
      [w setReleasedWhenClosed:NO];
      [w useOptimizedDrawing:YES];
      [view twinApplyFormAttributes:attributes];

    } else if ([type isEqualToString:@"Tabbed"]) {
      view = [[[MWTWinTabView alloc] initWithFrame:zf] autorelease];
      
      dontAddSubviewsNormally = YES;
      for (; i < [sexp count]; i++) {
        NSTabViewItem *tab = (id)[self recursiveCreateFormWidget:[sexp objectAtIndex:i]];
        if (![tab isKindOfClass:[NSTabViewItem class]]) {
          [self linkableErrorMessage:[NSString stringWithFormat:@"Tabbed widget contained non-Tab subwidget"]];
        } else {
          [(NSTabView *)view addTabViewItem:tab];
        }
      }
    
    } else if ([type isEqualToString:@"Tab"]) {
      NSTabViewItem *tvi = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
      
      dontAddSubviewsNormally = YES;
      [tvi twinConfigureAs:type];
      [tvi twinApplyFormAttributes:attributes];
      [tvi setView:[self recursiveCreateFormWidget:[sexp objectAtIndex:i++]]];
      
      view = (id)tvi;
    
    } else if ([type isEqualToString:@"Label"] || [type isEqualToString:@"TypeIn"]) {
      // special only because we need to choose the class based on an attribute
      Class viewClass = TWIN_BOOLEAN_ATTR(@"Password", NO) ? [NSSecureTextField class] : [NSTextField class];
      view = [[[viewClass alloc] initWithFrame:zf] autorelease];
      [view twinConfigureAs:type];
      [view twinApplyFormAttributes:attributes];
      [(NSTextField *)view setTarget:self];
      [(NSTextField *)view setDelegate:self];
      
    } else {
      [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown widget of type '%@' was listed as __Special__ in widget data.\n", type]];
      view = [[[NSView alloc] initWithFrame:zf] autorelease];
    }
  // End special widget creation processing
  
  } else if ([createSpec isKindOfClass:[NSString class]]) {
    view = [[[NSClassFromString(createSpec) alloc] initWithFrame:zf] autorelease];
    [view twinConfigureAs:type];
    [view twinApplyFormAttributes:attributes];
    if ([view respondsToSelector:@selector(setTarget:)])
      [(id)view setTarget:self];
    if ([view respondsToSelector:@selector(setDelegate:)])
      [(id)view setDelegate:self];
  
  } else if ([createSpec isKindOfClass:[NSArray class]] && [[createSpec objectAtIndex:0] isEqual:@"Scroll"]) {
    NSSize ss;

    nameView = [[[NSClassFromString([createSpec objectAtIndex:1]) alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
    ss = [MWTWinScrollView frameSizeForContentSize:[nameView frame].size hasHorizontalScroller:NO hasVerticalScroller:YES borderType:NSBezelBorder];
    view = [[[MWTWinScrollView alloc] initWithFrame:NSMakeRect(0, 0, ss.width, ss.height)] autorelease];

    [(NSScrollView *)view setDocumentView:nameView];
    [view     twinConfigureAs:type];
    [nameView twinConfigureAs:type];
    if ([nameView respondsToSelector:@selector(setTarget:)])
      [(id)nameView setTarget:self];
    if ([nameView respondsToSelector:@selector(setDelegate:)])
      [(id)nameView setDelegate:self];
    [view     twinApplyFormAttributes:attributes];
    [nameView twinApplyFormAttributes:attributes];
  
  } else {
    [self linkableErrorMessage:[NSString stringWithFormat:@"Widget data contained odd classmap spec: %@\n", createSpec]];
    view = [[[NSView alloc] initWithFrame:zf] autorelease];
  }
  
  if (!dontAddSubviewsNormally) {
    for (; i < [sexp count]; i++) {
      NSView *subview = [self recursiveCreateFormWidget:[sexp objectAtIndex:i]];
      if (!subview) continue;
      if (![subview isKindOfClass:[NSView class]]) {
        [self linkableErrorMessage:[NSString stringWithFormat:@"Non-special widget of type '%@' got processed subwidget not a NSView: %@\n", type, subview]];
      } else {
        [view addSubview:subview];
      }
    }
  }
  
  {
    NSString *Name = [[attributes objectForKey:@"Name"] objectAtIndex:0];
    if (Name) {
      if (!nameView) nameView = view;
      [widgets setObject:nameView forKey:Name];
      [revWidgets setObject:Name forKey:MWKeyFromObjectIdentity(nameView)];
    }
  }
  
  return view;
}

// --- Actions and delegate methods for UI objects ---

- (void)updateAckInfo {
  //NSLog(@"%lu %lu %lu", receivedCount, sentCount, ackedSentCount);
  [[self window] setDocumentEdited:ackedSentCount != sentCount];
}

- (void)sendTWinEvent:(NSString *)event widgetView:view arguments:(NSDictionary *)arguments {
  NSString *name = [revWidgets objectForKey:MWKeyFromObjectIdentity(view)];
  NSMutableDictionary *messageArgs = [[arguments mutableCopy] autorelease];
  
  if (dontSendChanges) return;
  if (!name) {
    NSBeep();
    return;
  }
  
  if (!messageArgs) messageArgs = [NSMutableDictionary dictionary];
  [messageArgs setObject:event forKey:@"event"];
  [messageArgs setObject:name forKey:@"widget"];
  
  sentCount++;
  [self updateAckInfo];
  [self send:[MWMCPMessage messageWithName:@"event" arguments:messageArgs] toLinkFor:@"outward"];
}

// FIXME: widget should handle this itself
- (IBAction)tableViewSelectionDidChange:(NSNotification *)notif {
  NSTableView *sender = [notif object];
  NSMutableArray *rows = [NSMutableArray array];

  {
    NSEnumerator *e = [sender selectedRowEnumerator];
    NSNumber *r = nil;
    while ((r = [e nextObject])) 
      [rows addObject:[NSNumber numberWithUnsignedInt:[r unsignedIntValue] + 1]];
  }

  [self sendTWinEvent:@"set" widgetView:sender arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    [rows asTWinSExpression], @"value",
    nil
  ]];
}

// FIXME: widget should handle this itself
- (void)controlTextDidChange:(NSNotification *)notif {
  NSTextField *sender = [notif object];
  [self sendTWinEvent:@"set" widgetView:sender arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    [[sender stringValue] asTWinSExpression], @"value",
    nil
  ]];
}

- (IBAction)twinInvokeAction:(id)sender {
  [self sendTWinEvent:@"invoke" widgetView:sender arguments:nil];
}

- (NSView *)widgetNamed:(NSString *)name {
  return [widgets objectForKey:name];
}
- (NSString *)nameOfWidget:(NSView *)widget {
  return [revWidgets objectForKey:MWKeyFromObjectIdentity(widget)];
}

// ---

- (void)parseForm:(NSString *)form {
  NSArray *sexp = nil;
  NSScanner *scan = [NSScanner scannerWithString:form];
  [scan mwSetCharactersToBeSkippedToEmptySet];

  if (![scan scanTWinSExpressionIncludingType:YES into:&sexp]) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"Form parse failed at character %u: %@\n", [scan scanLocation], [form substringFromIndex:[scan scanLocation]]]];
    [self unlinkAll];
    return;
  }
  
  if (![scan isAtEnd]) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"Form parse had leftover characters.\n"]];
  }

  { NSView *root = [self recursiveCreateFormWidget:sexp];
    [[self window] setContentSize:[root twinPreferredSize]];
  }
  
  [[self window] orderFront:nil];
}

// --- Accessors ---

- (NSWindow *)window { return window; }
- (void)setWindow:(NSWindow *)newVal {
  [window autorelease];
  window = [newVal retain];
}

@end