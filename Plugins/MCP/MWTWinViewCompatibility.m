/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTWinLayoutView.h"
#import "MWTWinViewCompatibility.h"

#import "MWTWinInterface.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

static const float LargeNumberForText = 1.0e7; // borrowed from TextSizingExample

enum MWTWinControlTags { MWTWinNoTag, MWTWinButtonTag, MWTWinCheckboxTag, MWTWinRadioTag, MWTWinTypeInTag, MWTWinLabelTag };

@implementation NSView (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize { return NSMakeSize(50, 50); }
- (NSSize)twinStretch { return NSMakeSize(0, 0); }
- (NSSize)twinShrink { return NSMakeSize(0, 0); }

- (void)twinSetFrameFromLayout:(NSRect)frame { [self setFrame:frame]; }

- (void)twinComputePreferredSize {}
- (void)twinPerformPhysicalLayout {}
- (void)twinRecursivePerformPhysicalLayout {}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {}
- (void)twinConfigureAs:(NSString *)widget {}

- (void)twinPropagateRadioSelection:(NSView *)selected {
  [[self superview] twinPropagateRadioSelection:selected];
}
- (void)twinPropagateRadioState:(NSView *)selected {
  [[self subviews] makeObjectsPerformSelector:@selector(twinPropagateRadioState:) withObject:selected];
}

@end

@implementation NSControl (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize { 
  NSString *key;
  switch ([self tag]) {
    case MWTWinButtonTag: key = @"Button"; break;
    case MWTWinCheckboxTag: key = @"Checkbox"; break;
    case MWTWinRadioTag: key = @"RadioButton"; break;
    case MWTWinLabelTag: key = @"Label"; break;
    case MWTWinTypeInTag: key = @"TypeIn"; break;
    default: return NSMakeSize(20, 20);
  }
  {
    BOOL isTextField = [self isKindOfClass:[NSTextField class]];
    NSSize text = [(
      isTextField
      ? [self attributedStringValue]
      : [(NSButton *)self attributedTitle]
    ) size];
    NSSize extra = NSSizeFromString([[MWTWinWidgetData objectForKey:@"TextExtraSizes"] objectForKey:key]);
    if (isTextField && [(NSTextField*)self isEditable]) {
      text.width = 200;
    }
    return NSMakeSize(ceil(text.width + extra.width), ceil(text.height + extra.height));
  }
}

@end

@implementation NSTextField (MWTWinViewCompatibility)

static const int focusMargin = 3;

- (NSSize)twinStretch { return NSMakeSize([self isEditable] ? MWTWinInfinity : 0, 0); }
- (NSSize)twinShrink { return NSMakeSize([self isEditable] ? MWTWinInfinity : 0, 0); }

- (void)twinSetFrameFromLayout:(NSRect)frame {
  BOOL edge = ([self isBezeled] || [self isBordered]);
  int margin = edge ? focusMargin : 0;
  NSSize s = [[self attributedStringValue] size];
  s.height += (edge ? 3 : 0);
  [self setFrame:NSMakeRect(
    frame.origin.x + margin,
    frame.origin.y + (unsigned)(frame.size.height - s.height) / 2,
    frame.size.width - margin * 2,
    ceil(s.height)
  )];
}

- (void)setStringValue:(NSString *)str {
  [super setStringValue:str];
  if ([[self superview] respondsToSelector:@selector(performLayout:)]) [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  if ((values = [attributes objectForKey:@"Main"]) || (values = [attributes objectForKey:@"main"]) || (values = [attributes objectForKey:@"Value"])) {
    [self setStringValue:[values objectAtIndex:0]];
  }
  if ([attributes objectForKey:@"Center"] || [attributes objectForKey:@"LeftAlign"] || [attributes objectForKey:@"RightAlign"]) {
    [self setAlignment:
      TWIN_BOOLEAN_ATTR(@"LeftAlign",  NO) ? NSLeftTextAlignment   :
      TWIN_BOOLEAN_ATTR(@"RightAlign", NO) ? NSRightTextAlignment  :
                                             NSCenterTextAlignment
    ];
  }
  if ((values = [attributes objectForKey:@"ReadOnly"])) {
    [self setEditable:!TWIN_BOOLEAN_ATTR(@"ReadOnly", NO)];
  }
  // TypeOut attribute not supported
  [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
  [super twinApplyFormAttributes:attributes];
}

- (BOOL)sendAction:(SEL)action to:(id)target {
  if ([target respondsToSelector:@selector(sendTWinEvent:widgetView:arguments:)]) {
    [target sendTWinEvent:@"invoke" widgetView:self arguments:nil];
    [[self window] performSelector:@selector(makeFirstResponder:) withObject:self afterDelay:0];
    return YES;
  } else {
    return [super sendAction:action to:target];
  }  
}


- (void)twinConfigureAs:(NSString *)widget {
  [[self cell] setSendsActionOnEndEditing:NO];
  [[self cell] setScrollable:YES];
  if ([widget isEqual:@"Label"]) {
    [self setTag:MWTWinLabelTag];
    [self setDrawsBackground:NO];
    [self setBordered:NO];
    [self setEditable:NO];
    [self setSelectable:YES];
    [self setAlignment:NSCenterTextAlignment];
  } else if ([widget isEqual:@"TypeIn"]) {
    [self setTag:MWTWinTypeInTag];
    [self setDrawsBackground:YES];
    [self setBezeled:YES];
    [self setEditable:YES];
    [self setSelectable:YES];
    [[self cell] setFont:[[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]]/*FIXME: get this font from mcp filter's config*/];
  }
}

@end

@implementation NSButton (MWTWinViewCompatibility)

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  BOOL layout = NO;
  // Margin attribute not supported
  if ((values = [attributes objectForKey:@"Main"]) || (values = [attributes objectForKey:@"main"])) {
    [self setTitle:[values objectAtIndex:0]];
    layout = YES;
  }
  if ((values = [attributes objectForKey:@"Value"])) {
    [self setState:TWIN_BOOLEAN_ATTR(@"Value", NO) ? NSOnState : NSOffState];
  }
  [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
  [super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
  [self setBordered:YES];
  [self setTransparent:NO];
  [self setBezelStyle:NSRegularSquareBezelStyle];
  if ([widget isEqual:@"Button"]) {
    [self setButtonType:NSMomentaryPushInButton];
    [self setTag:MWTWinButtonTag];
  } else if ([widget isEqual:@"Checkbox"]) {
    [self setButtonType:NSSwitchButton];
    [self setTag:MWTWinCheckboxTag];
  } else if ([widget isEqual:@"RadioButton"]) {
    [self setButtonType:NSRadioButton];
    [self setTag:MWTWinRadioTag];
  }
}

- (void)twinPropagateRadioState:(NSView *)selected {
  if ([self tag] == MWTWinRadioTag)
    [self setState:selected == self ? NSOnState : NSOffState];
}

@end

@implementation MWTWinButton

- (BOOL)sendAction:(SEL)action to:(id)target {
  int select = [target respondsToSelector:@selector(sendTWinEvent:widgetView:arguments:)] ? [self tag] : 0;
  
  switch (select) {
    case MWTWinButtonTag:
      [target sendTWinEvent:@"invoke" widgetView:self arguments:nil];
      return YES;
    case MWTWinCheckboxTag:
      [target sendTWinEvent:@"set" widgetView:self arguments:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Value", @"attr",
        [[MWToken token:[self state] == NSOnState ? @"TRUE" : @"FALSE"] asTWinSExpression], @"value",
        nil
      ]];
      return YES;
    case MWTWinRadioTag:
      [self twinPropagateRadioSelection:self];
      return YES;
    default:
      return [super sendAction:action to:target];
  }
}

@end

@implementation NSTableView (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize {
  // weird, but this is straight from the spec
  NSSize ts = [@"XXXX" sizeWithAttributes:[NSDictionary dictionaryWithObject:[[[[self tableColumns] objectAtIndex:0] dataCell] font] forKey:NSFontAttributeName]];
  ts.width += 4;
  ts.height += 4;
  return ts;
}
- (NSSize)twinStretch { return NSMakeSize(MWTWinInfinity, MWTWinInfinity); }
- (NSSize)twinShrink { return NSMakeSize(MWTWinInfinity, MWTWinInfinity); }

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;
  if ([attributes objectForKey:@"Multiple"])
    [self setAllowsMultipleSelection:TWIN_BOOLEAN_ATTR(@"Multiple", NO)];
  if ((values = [attributes objectForKey:@"Items"])) {
    MWGenericTableViewDataSource *ds = [self dataSource];
    
    // er, slight problem, this will have a nonretain bug if called on a regular NSTableView. (all tables created by TWin are MWDataSourceRetainingTableView s)
    if (!ds) [self setDataSource:ds = [[[MWGenericTableViewDataSource alloc] init] autorelease]];
    
    [ds setRowCount:[values count]];
    [ds setColumn:values forKey:@"Items"];
    [self reloadData];
    
    // resize column to fit data
    {
      NSTableColumn *col = [[self tableColumns] objectAtIndex:0];
      unsigned max = 10;
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [[col dataCell] font], NSFontAttributeName,
        nil
      ];
      NSEnumerator *stringE = [values objectEnumerator];
      NSString *string;
      while ((string = [stringE nextObject])) {
        unsigned len = [string sizeWithAttributes:attrs].width;
        if (max < len) max = len;
      }
      [col setWidth:max + 2];
      [col setMinWidth:max + 2];
      [col setMaxWidth:max + 2];
    }
  }
  if ((values = [attributes objectForKey:@"Value"])) {
    NSEnumerator *e = [values objectEnumerator];
    BOOL mult = [self allowsMultipleSelection];
    id r;
    [self deselectAll:nil];
    while ((r = [e nextObject])) [self selectRow:[r intValue] - 1 byExtendingSelection:mult];
  }
  [super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
  NSTableColumn *col = [[[NSTableColumn alloc] initWithIdentifier:@"Items"] autorelease];
 
  [col setEditable:NO];
  [col setResizable:NO];
  [col setWidth:10000];
  [[col dataCell] setFont:[[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]]/*FIXME: get this font from mcp filter's config*/];
  [self setRowHeight:[[col dataCell] cellSize].height];
  [self addTableColumn:col];

  [self setDoubleAction:@selector(twinInvokeAction:)];
  [self setHeaderView:nil];
  [self setCornerView:nil];
}

@end

@implementation NSTextView (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize {
  NSFont *f = [[self font] screenFont];
  if (!f) f = [self font];
  return NSMakeSize(
    80 * [f advancementForGlyph:[f glyphWithName:@"e"]].width + [[self textContainer] lineFragmentPadding] * 2,
    25 * [f defaultLineHeightForFont]
  );
}
- (NSSize)twinStretch { return NSMakeSize(MWTWinInfinity, MWTWinInfinity); }
- (NSSize)twinShrink { return NSMakeSize(MWTWinInfinity, MWTWinInfinity); }

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  {
    NSString *val = [[attributes objectForKey:@"Value"] componentsJoinedByString:@"\n"]; 
    if (val) [self setString:val];
  }
  if ([attributes objectForKey:@"ReadOnly"])
    [self setEditable:!TWIN_BOOLEAN_ATTR(@"ReadOnly", NO)];

  if ([attributes objectForKey:@"Wrap"]) {
    NSTextContainer *textCon = [self textContainer];
    if (TWIN_BOOLEAN_ATTR(@"Wrap", YES)) {
      [self setHorizontallyResizable:NO];
      [self setFrameSize:[[self superview] bounds].size];
      [self setAutoresizingMask:NSViewWidthSizable];
      [textCon setWidthTracksTextView:YES];
    } else {
      [self setAutoresizingMask:NSViewNotSizable];
      [textCon setWidthTracksTextView:NO];
      [textCon setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
      [self setHorizontallyResizable:YES];
    }
  }

  [super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
  NSTextContainer *textCon = [self textContainer];
  [self setAutoresizingMask:NSViewWidthSizable];

  [textCon setHeightTracksTextView:NO];
  [self setVerticallyResizable:YES];
  [self setMinSize:NSMakeSize(5,5)];
  [self setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
  [self setFont:[[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]]/*FIXME: get this font from mcp filter's config*/];
}

- (void)twinEventAppend:(NSDictionary *)args {
  NSDictionary *attr = [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName];
  NSString *line = [args objectForKey:@"value"];
  NSMutableAttributedString *mstr = [[[NSMutableAttributedString alloc] initWithString:line attributes:attr] autorelease];
  
  NSTextStorage *storage = [self textStorage];

  [mstr replaceCharactersInRange:NSMakeRange(0,0) withString:@"\n"];

  [storage beginEditing];
  [storage appendAttributedString:mstr];
  [storage maintainScrollbackOfLength:[[[(MWTWinInterface *)[self delegate] config] objectAtPath:[MWConfigPath pathWithComponent:@"ScrollbackCharacters"]] intValue]];
  [storage endEditing];
}

@end

@implementation MWOutputTextView (MWTWinViewCompatibility)

- (void)twinConfigureAs:(NSString *)widget {
  [super twinConfigureAs:widget];
  [self setAutoScrollToEnd:YES];
}

@end

@interface NSScrollView (MWTWinViewCompatibility)

- (void)twinSmartScrollbars;

@end

@implementation NSScrollView (MWTWinViewCompatibility)

- (NSSize)twinPreferredSize {
  NSSize s = [[self documentView] twinPreferredSize];
  return [[self class] frameSizeForContentSize:s hasHorizontalScroller:[self hasHorizontalScroller] hasVerticalScroller:[self hasVerticalScroller] borderType:[self borderType]];
}
- (NSSize)twinStretch { return [[self documentView] twinStretch]; }
- (NSSize)twinShrink { return [[self documentView] twinShrink]; }

- (void)twinSmartScrollbars {
  if ([[self documentView] isKindOfClass:[NSTableView class]]) {
    NSArray *columns = [(NSTableView *)[self documentView] tableColumns];
    // this is support specifically for twin listbox. if we get other kinds of twin table views with multiple columns we'll need to extend this
    [self setHasHorizontalScroller:[columns count] ? [[columns objectAtIndex:0] minWidth] > [[self contentView] frame].size.width : NO];
  }
}

- (void)twinSetFrameFromLayout:(NSRect)frame {
  [self setFrame:frame];
  [self twinSmartScrollbars];
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  if ([attributes objectForKey:@"Wrap"])
    [self setHasHorizontalScroller:!TWIN_BOOLEAN_ATTR(@"Wrap", YES)];
  [super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
  [self setBorderType:NSBezelBorder];
  [self setHasVerticalScroller:YES];
  [self setHasHorizontalScroller:NO];
}

@end

@implementation MWTWinScrollView

- (void)reflectScrolledClipView:(NSClipView *)aClipView {
  [super reflectScrolledClipView:aClipView];
  [self twinSmartScrollbars];
}

@end

@implementation MWTWinImageView

- (void)mouseDown:(NSEvent *)event { /* needed for mouseUp to be caught */ }
- (void)mouseUp:(NSEvent *)event {
  [self sendAction:[self action] to:[self target]];
}

- (NSSize)twinPreferredSize { return [[self image] size]; }
- (NSSize)twinStretch { return NSZeroSize; }
- (NSSize)twinShrink { return NSZeroSize; }

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;

  if ((values = [attributes objectForKey:@"Source"])) {
    [(MWURLLoadingImageView *)self setURL:[NSURL URLWithString:[values objectAtIndex:0]]];
  }

  [super twinApplyFormAttributes:attributes];
}

- (void)setImage:(NSImage *)image {
  [super setImage:image];
  if ([[self superview] respondsToSelector:@selector(performLayout:)]) [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
}

- (void)twinConfigureAs:(NSString *)widget {
  NSImageCell *c = [self cell];
  [self setAction:@selector(twinInvokeAction:)];
  [c setImageAlignment:NSImageAlignBottomLeft];
  [c setImageFrameStyle:NSImageFrameNone];
  [c setImageScaling:NSScaleToFit];
}

@end

@implementation MWTWinTabView

- (NSSize)twinPreferredSize { return csPref; }
- (NSSize)twinStretch { return csStretch; }
- (NSSize)twinShrink { return csShrink; }

- (void)twinComputePreferredSize { 
  NSEnumerator *tviE = [[self tabViewItems] objectEnumerator];
  NSTabViewItem *tvi;
  
  NSSize extra = [self frame].size;
  NSSize activeSubviewSize = [[[self subviews] objectAtIndex:0] frame].size;
  
  extra.width -= activeSubviewSize.width;
  extra.height -= activeSubviewSize.height;
  
  csPref = NSMakeSize(0, 0);
  csStretch = NSMakeSize(MWTWinInfinity, MWTWinInfinity);
  csShrink = NSMakeSize(MWTWinInfinity, MWTWinInfinity);
  
  while ((tvi = [tviE nextObject])) {
    NSSize s = [[tvi view] twinPreferredSize];
    if (s.width  > csPref.width ) csPref.width  = s.width ;
    if (s.height > csPref.height) csPref.height = s.height;
    s = [[tvi view] twinStretch];
    if (s.width  < csStretch.width ) csStretch.width  = s.width ;
    if (s.height < csStretch.height) csStretch.height = s.height;
    s = [[tvi view] twinShrink];
    if (s.width  < csShrink.width ) csShrink.width  = s.width ;
    if (s.height < csShrink.height) csShrink.height = s.height;
  }
  csPref.width += extra.width;
  csPref.height += extra.height;

  if (csShrink.width > extra.width) csShrink.width = extra.width;
  if (csShrink.height > extra.height) csShrink.height = extra.height;

  // NSLog(@"%@ computed sizes, total pref = %f %f, stretch = %f %f, shrink = %f %f, extra = %@", self, csPref.width, csPref.height, csStretch.width, csStretch.height, csShrink.width, csShrink.height, NSStringFromSize(extra));
}

/* should be same as MWTWinLayoutView */
- (void)twinRecursivePerformPhysicalLayout {
  NSEnumerator *tviE = [[self tabViewItems] objectEnumerator];
  NSTabViewItem *tvi;
  NSSize properSize = [[[self subviews] objectAtIndex:0] frame].size;
  while ((tvi = [tviE nextObject])) {
    [[tvi view] setFrameSize:properSize];
    [[tvi view] twinRecursivePerformPhysicalLayout];
  }
}

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  [super twinApplyFormAttributes:attributes];
}
- (void)twinConfigureAs:(NSString *)widget {}

- (void)twinNotifyContainerOfSizeChange {
  [(MWTWinLayoutView *)[self superview] performLayout:MWLayoutTWinSizeChanged];
}
- (void)performLayout:(NSString *)reason {
  if ([reason isEqual:MWLayoutSubviewSizeChanged]) return;
  [self twinComputePreferredSize];
  [self twinNotifyContainerOfSizeChange];
}

- (void)twinPropagateRadioState:(NSView *)selected {
  NSEnumerator *tviE = [[self tabViewItems] objectEnumerator];
  NSTabViewItem *tvi;
  while ((tvi = [tviE nextObject]))
    [[tvi view] twinPropagateRadioState:selected];
}

// copied from MWLayoutView

- (void)didAddSubview:(NSView *)v {
  [super didAddSubview:v];
  [self performLayout:MWLayoutSubviewAdded];
}

@end

@implementation NSTabViewItem (MWTWinViewCompatibility)

- (void)twinApplyFormAttributes:(NSDictionary *)attributes {
  NSArray *values;

  if ((values = [attributes objectForKey:@"Main"])) {
    [self setLabel:[values objectAtIndex:0]];
  }

  //[super twinApplyFormAttributes:attributes];
}

- (void)twinConfigureAs:(NSString *)widget {
}

- (void)performLayout:(NSString *)reason {
  if ([reason isEqual:MWLayoutSubviewSizeChanged]) return;
 
  [(MWTWinTabView *)[self tabView] performLayout:MWLayoutTWinSizeChanged];
}

@end

// ---

@implementation MWDataSourceRetainingTableView

- (void)dealloc {
  [[self dataSource] autorelease];
  [super dealloc];
}

- (void)setDataSource:(id)ds {
  [ds retain];
  [[self dataSource] autorelease];
  [super setDataSource:ds];
}

@end
