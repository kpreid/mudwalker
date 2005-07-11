/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
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

@interface MWTWinInterface (Private)

- (void)parseForm:(NSString *)form;

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
  printf("twin interface deallocated\n");
  [widgets autorelease]; widgets = nil;
  [revWidgets autorelease]; revWidgets = nil;
  [window close];
  [window autorelease]; window = nil;
  [super dealloc];
}

// --- Window delegate ---

- (void)windowWillClose:(NSNotification *)notif {
  dontCloseWindow = YES;
  [self unlinkAll];
}

- (void)windowDidResize:(NSNotification *)notif {
  [(MWTWinWindowContentView *)[[self window] contentView] performLayout:MWLayoutAttributesChanged];
}

// --- Linkage & MCP cord ---

- (void)linkPrune {
  if (![[self links] objectForKey:@"outward"]
      || ![[self window] isVisible]
  ) {
    printf("twin interface pruning (%u)\n", [self retainCount]);
    if (!dontCloseWindow) [[self window] close];
    [self unlinkAll];
    printf("twin interface pruned (%u)\n", [self retainCount]);
  }
}

- (void)handleTWinSetEvent:(NSDictionary *)args {
  NSView *widget = [widgets objectForKey:[args objectForKey:@"widget"]];
  NSString *attr = [args objectForKey:@"attr"];
  NSString *value = [args objectForKey:@"value"];
  NSArray *values = nil;
  NSScanner *scan = [NSScanner scannerWithString:value];

  [self linkableTraceMessage:[NSString stringWithFormat:@"set w=%@ a=%@ v=%@\n", widget, attr, value]];
  
  [scan setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
  if (!([scan scanTWinSExpressionIncludingType:NO into:&values])) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"(couldn't parse '%@')\n", value]];
  }
  
  if (![values isKindOfClass:[NSArray class]]) values = [NSArray arrayWithObject:values];
  
  [widget twinApplyFormAttributes:[NSDictionary dictionaryWithObject:values forKey:attr]];
}

- (void)receive:(id)obj fromLinkFor:(NSString *)linkName {
  NSString *message = nil;
  NSDictionary *args = nil;
  BOOL noAck = NO;

  if (![obj isKindOfClass:[MWMCPMessage class]]) return;
  message = [(MWMCPMessage *)obj messageName];
  args = obj;

  receivedCount++;

  dontSendChanges = YES;
  NS_DURING
    if ([message isEqual:@"create"]) {
      [self parseForm:[args objectForKey:@"form"]];
      
    } else if ([message isEqual:@"event"]) {
      NSString *type = [args objectForKey:@"event"];
    
      // if we get more than, say, 2 event types, then should use a dictionary for dispatching
      if ([type isEqual:@"set"]) {
        [self handleTWinSetEvent:args];
      } else {
        [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown TWin event type: '%@'", type]];
      }
    
      // event message may have an 'ack' argument
      if ([args objectForKey:@"ack"]) ackedSentCount = [[args objectForKey:@"ack"] intValue];
      
    } else if ([message isEqual:@"ack"]) {
      ackedSentCount = [[args objectForKey:@"messages"] intValue];
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
    [self send:[MWMCPMessage messageWithName:@"ack" arguments:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLongLong:receivedCount] forKey:@"messages"]] toLinkFor:@"outward"];
    sentCount++;
  }
}

- (NSView *)recursiveCreateFormWidget:(NSArray *)sexp {
  NSRect zf = {{0, 0}, {0, 0}};
  NSDictionary *widgetMap = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSButton class], @"Button",
    [NSButton class], @"Checkbox",
    [NSButton class], @"RadioButton",
    [MWTWinShapeView class], @"Radio",
    [MWTWinShapeView class], @"Shape",
    [MWTWinShapeView class], @"Fill",
    [MWTWinLinearLayoutView class], @"HBox",
    [MWTWinLinearLayoutView class], @"VBox",
    [MWTWinSpaceView class], @"Space",
    [MWTWinSpaceView class], @"Separator",
    nil
  ];
  NSString *type = nil;
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  int i = 0;
  id createInfo = nil;
  NSView *view = nil, *nameView = nil;
  
  NSParameterAssert([sexp count] >= 2);
  
  if (![[sexp objectAtIndex:i++] isEqual:@"["]) [NSException raise:NSInvalidArgumentException format:@"Form translation: expected [] list, got %@", sexp];
  type = [sexp objectAtIndex:i++];

  for (; i < [sexp count]; i++) {
    NSArray *att = [sexp objectAtIndex:i];
    if (![[att objectAtIndex:0] isEqual:@"("]) break;
    [attributes setObject:[att subarrayWithRange:MWMakeABRange(2, [att count])] forKey:[att objectAtIndex:1]];
  }
  
  createInfo = [[MWTWinWidgetData objectForKey:@"ClassMap"] objectForKey:type];
  
  if ([createSpec isEqual:@"__Special__"]) {
    if ([type isEqual:@"Window"]) {
      NSWindow *w = [[[NSWindow alloc] initWithContentRect:NSMakeRect(300,300,300,300) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
      [self setWindow:w];
      view = [[[MWTWinWindowContentView alloc] initWithFrame:zf] autorelease];
      
      [w setContentView:view];
      [w setDelegate:self];
      [w setReleasedWhenClosed:NO];
      [view twinApplyFormAttributes:attributes];
            
    } else if ([type isEqual:@"Label"] || [type isEqual:@"TypeIn"]) {
      viewClass = TWIN_BOOLEAN_ATTR(@"Password", NO) ? [NSSecureTextField class] : [NSTextField class];
      view = [[[viewClass alloc] initWithFrame:zf] autorelease];
      [view twinConfigureAs:type];
      [view twinApplyFormAttributes:attributes];
      [(NSTextField *)view setTarget:self];
      [(NSTextField *)view setDelegate:self];
    } else {
      [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown widget of type '%@' was listed as __Special__ in widget data.\n", type]];
      view = [[[NSView alloc] initWithFrame:zf] autorelease];
    }
  
  } else if ([createSpec isKindOfClass:[NSString class]]) {
    view = [[[NSClassFroMString(createSpec) alloc] initWithFrame:zf] autorelease];
    [view twinConfigureAs:type];
    [view twinApplyFormAttributes:attributes];
    if ([view respondsToSelector:@selector(setTarget:)])
      [(id)view setTarget:self];
    if ([view respondsToSelector:@selector(setDelegate:)])
      [(id)view setDelegate:self];
  
   } else if ([type isEqual:@"ListBox"]) {
    NSTableView *tv = [[[MWDataSourceRetainingTableView alloc] initWithFrame:zf] autorelease];
    view = [[[NSScrollView alloc] initWithFrame:zf] autorelease];

    [(NSScrollView *)view setDocumentView:tv];
    [view twinConfigureAs:type];
    [tv   twinConfigureAs:type];
    [view twinApplyFormAttributes:attributes];
    [tv   twinApplyFormAttributes:attributes];
    [tv setTarget:self];
    [tv setDelegate:self];
    nameView = tv;
  
  } else if ([type isEqual:@"TextEdit"] || [type isEqual:@"TypeOut"]) {
    // FIXME: implement TypeOut behavior
    NSTextView *tv = [[[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
    NSSize ss = [NSScrollView frameSizeForContentSize:[tv frame].size hasHorizontalScroller:NO hasVerticalScroller:YES borderType:NSBezelBorder];
    view = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, ss.width, ss.height)] autorelease];

    [(NSScrollView *)view setDocumentView:tv];
    [view twinConfigureAs:type];
    [tv   twinConfigureAs:type];
    [view twinApplyFormAttributes:attributes];
    [tv   twinApplyFormAttributes:attributes];
    [tv setDelegate:self];
    nameView = tv;
    
  } else {
    [self linkableErrorMessage:[NSString stringWithFormat:@"Form unknown widget type: '%@'.\n", type]];
    view = [[[NSView alloc] initWithFrame:zf] autorelease];
    
  }
  
  for (; i < [sexp count]; i++) {
    NSView *subview = [self recursiveCreateFormWidget:[sexp objectAtIndex:i]];
    if (subview) [view addSubview:subview];
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

- (void)sendTWinEvent:(NSString *)event widget:(NSString *)name arguments:(NSDictionary *)arguments {
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
  [self send:[MWMCPMessage messageWithName:@"event" arguments:messageArgs] toLinkFor:@"outward"];
}

- (IBAction)tableViewSelectionDidChange:(NSNotification *)notif {
  NSTableView *sender = [notif object];
  NSMutableString *value = [@"(" mutableCopy];
  // FIXME: -[NSArray asTWinSExpression]
  {
    NSEnumerator *e = [sender selectedRowEnumerator];
    NSNumber *r = nil;
    while ((r = [e nextObject])) {
      [value appendString:[NSString stringWithFormat:@"%i", [r intValue] + 1]];
      [value appendString:@" "];
    }
    [value appendString:@")"];
  }

  [self sendTWinEvent:@"set" widget:[revWidgets objectForKey:MWKeyFromObjectIdentity(sender)] arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    value, @"value",
    nil
  ]];
}

- (IBAction)controlTextDidChange:(NSNotification *)notif {
  NSTextField *sender = [notif object];
  [self sendTWinEvent:@"set" widget:[revWidgets objectForKey:MWKeyFromObjectIdentity(sender)] arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    [[sender stringValue] asTWinSExpression], @"value",
    nil
  ]];
}

- (IBAction)twinInvokeAction:(id)sender {
  [self sendTWinEvent:@"invoke" widget:[revWidgets objectForKey:MWKeyFromObjectIdentity(sender)] arguments:nil];
}

- (IBAction)twinCheckboxAction:(id)sender {
  NSString *value = [sender state] == NSOnState ? @"TRUE" : @"FALSE";

  [self sendTWinEvent:@"set" widget:[revWidgets objectForKey:MWKeyFromObjectIdentity(sender)] arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    value, @"value",
    nil
  ]];
}

- (IBAction)twinRadioAction:(id)sender {
  [sender twinPropagateRadioSelection:sender];
}

- (void)radioGroup:(id)sender selected:(NSView *)widget {
  [self sendTWinEvent:@"set" widget:[revWidgets objectForKey:MWKeyFromObjectIdentity(sender)] arguments:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Value", @"attr",
    [revWidgets objectForKey:MWKeyFromObjectIdentity(widget)], @"value",
    nil
  ]];
}

- (NSView *)widgetNamed:(NSString *)name {
  return [widgets objectForKey:name];
}

// ---

- (void)parseForm:(NSString *)form {
  NSArray *sexp = nil;
  NSScanner *scan = [NSScanner scannerWithString:form];
  [scan setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

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