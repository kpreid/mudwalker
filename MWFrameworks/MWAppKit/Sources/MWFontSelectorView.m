/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWFontSelectorView.h"

#import <MudWalker/MWUtilities.h>

enum {
  version0 = 0,
  version1
};
static const int currentVersion = version1;

@implementation MWFontSelectorView

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (void)commonFontSelectorInit {
  [self setCell:[[[NSButtonCell alloc] init] autorelease]];
  
  [[self cell] setBordered:YES];
  [[self cell] setTransparent:NO];
  [[self cell] setBezelStyle:NSShadowlessSquareBezelStyle];
  [[self cell] setImagePosition:NSNoImage];
  
  [self setObjectValue:[self objectValue]];
}

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;
  
  [self commonFontSelectorInit];
  [self setObjectValue:[NSFont userFontOfSize:12]];
   
  return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super initWithCoder:decoder])) return nil;
  [self commonFontSelectorInit];
  switch ([decoder versionForClassName:@"MWFontSelectorView"]) {
    case version0:
      [self setObjectValue:[NSFont userFontOfSize:12]];
      break;
    case version1:
      [self setObjectValue:[decoder decodeObject]];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWFontSelectorView!", [decoder versionForClassName:@"MWFontSelectorView"]];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[self window]];
  [font autorelease]; font = nil;
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:font];
}

- (void)updateFontPanel {
  [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
}

- (void)fsvWindowDidBecomeKey:(NSNotification *)notif {
  if ([[self window] firstResponder] == self)
    [self updateFontPanel];
}

- (BOOL)acceptsFirstResponder { return YES; }

- (BOOL)becomeFirstResponder {
  BOOL r = [super becomeFirstResponder];
  if (r && [[self window] isKeyWindow])
    [self updateFontPanel];
  return r;
}

- (void)viewDidMoveToWindow {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fsvWindowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:[self window]];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[self window]];
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget {
  [[self window] makeFirstResponder:self];
  [self updateFontPanel];
  [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
  return YES;
}

- (void)changeFont:(id)sender {
  [self setObjectValue:[sender convertFont:[self font]]];
  [NSApp sendAction:[self action] to:[self target] from:self];
}

- (id)objectValue { return font; }
- (void)setObjectValue:(id)newVal {
  [font autorelease];
  font = [newVal retain];
  [[self cell] setTitle:font ? [NSString stringWithFormat:@"%@ %0.2fpt", [font displayName], [font pointSize]] : MWLocalizedStringHere(@"MWFontSelectorView-noFont")];
  [[self cell] setFont:font];
}

@end
