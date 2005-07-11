/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudGUIController.h"

#import "MWCGMudCommon.h"

#import "MWCGMudMessage.h"
#import "MWCGMudIconsView.h"
#import "MWCGMudGraphicsView.h"

#import <AppKit/AppKit.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWToken.h>
#import <MWAppKit/MWAppKit.h>

@interface MWCGMudGUIController (Private)

- (void)handleCGMudMessage:(MWCGMudMessage *)msg;
- (void)setIconsView:(MWCGMudIconsView *)v;

- (MWOutputTextView *)textView;
- (void)setTextView:(MWOutputTextView *)v;

@end

@implementation MWCGMudGUIController

- (id)init {
  if (!(self = [super init])) return nil;

  viewIdentifiers = [[NSMutableDictionary allocWithZone:[self zone]] init];
  identifierViews = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [viewIdentifiers release]; viewIdentifiers = nil;
  [identifierViews release]; identifierViews = nil;
  [iconsView release]; iconsView = nil;
  [textView release]; textView = nil;
  [super dealloc];
}

// --- Linkage ---

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", nil]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[MWCGMudMessage class]]) {
      [self handleCGMudMessage:obj];
      return YES;
    } else if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenGUIShrinkwrap]) {
        [self send:obj toLinkFor:@"outward"];
        [[[self textView] window] makeFirstResponder:[self textView]];
        return YES;
      }
    }
  }
  return NO;
}

- (void)handleCGMudMessage:(MWCGMudMessage *)msg {
  switch ([msg type]) {
    case rt_message: {
      NSString *s = [@"\n" stringByAppendingString:[[[NSString alloc] initWithData:[[msg tail] subdataWithRange:NSMakeRange(0, [[msg tail] length] - 1)] encoding:CGMUD_ENCODING] autorelease]];
      NSDictionary *textAttributes = [self probe:@selector(lpTextAttributes:) ofLinkFor:@"outward"];
      
      NSView *view = [self viewForIdentifier:[NSNumber numberWithUnsignedInt:[msg key]]];
      unsigned int scrollback = scrollbackLength;
      if ([view isKindOfClass:[NSScrollView class]]) {
        view = [(NSScrollView *)view documentView];
      }
      if ([view respondsToSelector:@selector(textStorage)]) {
        NSTextStorage *ts = [(NSTextView*)view textStorage];
        [ts beginEditing];
        [ts appendAttributedString:[[[NSAttributedString alloc] initWithString:s attributes:textAttributes] autorelease]];
        [ts maintainScrollbackOfLength:scrollback];
        [ts endEditing];
      }
    
      break;
    }
  
    case rt_createContainer: {
      const char *bytes = [[msg tail] bytes];
      uint32_t encloser = ntohl(*((uint32_t *)bytes));
      MWLinearLayoutView *view = [[[MWLinearLayoutView alloc] initWithFrame:NSZeroRect] autorelease];

      [view setVertical:[msg flag]];
      [view setPadding:LAYOUT_VIEW_PADDING];
      [view setAlignment:(signed int)[msg uint]];
      [self
        addView:view
        withID:[NSNumber numberWithUnsignedInt:[msg key]]
        inID:[NSNumber numberWithUnsignedInt:encloser]
      ];
      break;
    }
      
    case rt_createComponent: {
      const char *bytes = [[msg tail] bytes];
      uint32_t encloser = ntohl(*((uint32_t *)bytes));
      uint16_t width    = ntohs(*((uint16_t *)(bytes+4)));
      uint16_t height   = ntohs(*((uint16_t *)(bytes+6)));
      NSView *view = nil;
      NSRect frame = NSMakeRect(0, 0, width, height);
      /*
	    d_encloser = getInt();
	    d_width = getShort();
	    d_height = getShort();
	    main.addComponent(d_encloser, getKey(), getParmint(),
			      d_width, d_height);
      */

      switch ([msg uint]) {
        case CTYPE_PROMPTED_TEXT:
          // DON'T provide a prompted text, as the floater does that
          break;
        case CTYPE_GENERAL_TEXT: {
          // There's some mysterious extra padding in the NSTextView that's not accounted for by the textContainerInset...
          EffectsInfo_t *ei = [(NSValue *)[self probe:@selector(lpEffectsInfo:) ofLinkFor:@"outward"] pointerValue];
          MWOutputTextView *tView = [[[MWOutputTextView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width * (ei ? ei->ei_fontWidth : 0) + 12, frame.size.height * (ei ? ei->ei_fontHeight : 0))] autorelease];
          NSRect scrollRect = {
            {0, 0},
            [NSScrollView frameSizeForContentSize:[tView frame].size hasHorizontalScroller:NO hasVerticalScroller:YES borderType:NSBezelBorder]
          };
          view = [[NSScrollView alloc] initWithFrame:scrollRect];
          
          //[tView setTextContainerInset:NSMakeSize(0, 0)];
          [tView setAllowsUndo:NO];
          [tView setEditable:NO];
          [tView setRichText:YES];
          [tView setAutoScrollToEnd:YES];
          
          [(NSScrollView *)view setHasVerticalScroller:YES];
          [(NSScrollView *)view setDocumentView:tView];
          [(NSScrollView *)view setBorderType:NSBezelBorder];
          [self setTextView:tView];
          break;
        }
        case CTYPE_ICON_LIST: {
          NSRect innerFrame = {{0, 0}, [NSScrollView contentSizeForFrameSize:frame.size  hasHorizontalScroller:YES hasVerticalScroller:NO borderType:NSBezelBorder]};
          MWCGMudIconsView *docView = [[MWCGMudIconsView alloc] initWithFrame:innerFrame];
          view = [[NSScrollView alloc] initWithFrame:frame];
          [(NSScrollView *)view setHasHorizontalScroller:YES];
          [(NSScrollView *)view setBorderType:NSBezelBorder];
          [(NSScrollView *)view setDocumentView:docView];
          [self setIconsView:docView];
          break;
        }
        case CTYPE_ICONED_CANVAS:
          view = [[MWCGMudGraphicsView alloc] initWithFrame:frame];
          [(MWCGMudGraphicsView *)view setDelegate:self];
          break;
        case CTYPE_BUTTON_PANEL:
          view = [[NSView alloc] initWithFrame:frame];
          break;
        default:
          [self linkableErrorMessage:[NSString stringWithFormat:@"Unknown component type %u", [msg uint]]];
          break;
      }

      [view autorelease];
      if (view) [[self probe:@selector(lpGUICustomController:) ofLinkFor:@"outward"]
        addView:view
        withID:[NSNumber numberWithUnsignedInt:[msg key]]
        inID:[NSNumber numberWithUnsignedInt:encloser]
      ];
      break;
    }
  }
}

- (IBAction)serverButtonPressed:(id)sender {

  id tID = [self identifierForView:sender];
  NSRange midR;
  if ([tID respondsToSelector:@selector(rangeOfString:)] && (midR = [tID rangeOfString:@"-Button-"]).length) {
    NSString *sub = [tID substringWithRange:MWMakeABRange(midR.location + midR.length, [(NSString *)tID length])];
    [self send:[MWCGMudMessage messageWithType:rt_buttonHit key:[sub intValue] flag:0 uint:0 tail:nil] toLinkFor:@"outward"];
  }
}

// --- View tracking ---

- (void)addView:(NSView *)newView withID:(id)newID inID:(id)outerID {
  NSView *outerView = [outerID isEqual:@"MWRoot"] ? [self probe:@selector(lpGUIRootView:) ofLinkFor:@"outward"] : [self viewForIdentifier:outerID];
  if (!outerView) {
    [self linkableErrorMessage:[NSString stringWithFormat:@"GUI CC: outer view '%@' doesn't exist\n", outerID]];
    return;
  }
  [outerView addSubview:newView];
  [self addViewIdentifier:newID forView:newView];
}

- (void)addViewIdentifier:(id)ident forView:(NSView *)view {
  [viewIdentifiers setObject:ident forKey:MWKeyFromObjectIdentity(view)];
  [identifierViews setObject:view forKey:ident];
}

- (void)forgetView:(NSView *)view {
  id ident = [viewIdentifiers objectForKey:MWKeyFromObjectIdentity(view)];
  [identifierViews removeObjectForKey:ident];
  [viewIdentifiers removeObjectForKey:view];
}

- (NSView *)viewForIdentifier:(id)ident {
  return [identifierViews objectForKey:ident];
}

- (id)identifierForView:(NSView *)view {
  return [viewIdentifiers objectForKey:MWKeyFromObjectIdentity(view)];
}

// --- Accessors ---

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  
  scrollbackLength = [(NSNumber *)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"ScrollbackCharacters"]] unsignedIntValue];
}

- (MWCGMudIconsView *)iconsView { return iconsView; }
- (void)setIconsView:(MWCGMudIconsView *)v {
  [iconsView autorelease];
  iconsView = [v retain];
}

- (MWOutputTextView *)textView { return textView; }
- (void)setTextView:(MWOutputTextView *)v {
  [textView autorelease];
  textView = [v retain];
}

@end
