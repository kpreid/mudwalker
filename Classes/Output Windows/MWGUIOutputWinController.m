/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWGUIOutputWinController.h"

#import <MudWalker/MudWalker.h>

@implementation MWGUIOutputWinController

// --- Initialization ------------------------------------------------------------

- (MWGUIOutputWinController *)init {
  if (!(self = (MWGUIOutputWinController *)[super init])) return nil;
  
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];

  [self setTitle:NSLocalizedString(@"GUI Window",nil)];
}

- (void)dealloc {
  [title release];
  title = nil;
  [super dealloc];
}

- (NSString *)outputWindowNibName {return @"GUIOutputWindow";}

// --- Input/output ------------------------------------------------------------

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", @"controller", nil]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([super receive:obj fromLinkFor:link]) return YES;

  if ([link isEqual:@"outward"]) {
    [self send:obj toLinkFor:@"controller"];
    return YES;
  } else if ([link isEqual:@"controller"]) {
    if ([obj isKindOfClass:[MWToken class]] && [obj isEqual:MWTokenGUIShrinkwrap]) {
      [self shrinkwrap];
      return YES;
    } else {
      [self send:obj toLinkFor:@"outward"];
      return YES;
    }
  } else {
    return NO;
  }
}

- (id)probe:(SEL)sel fromLinkFor:(NSString *)link {
  if ([self respondsToSelector:sel]) {
    return [self performSelector:sel withObject:link];
  } else {
    if ([link isEqual:@"outward"])
      return [self probe:sel ofLinkFor:@"controller"];
    else if ([link isEqual:@"controller"])
      return [self probe:sel ofLinkFor:@"outward"];
    else
      return nil;
  }
}

// Probe methods
- (id)lpHandlesGUI:(NSString *)link { return [NSNumber numberWithInt:1]; }

- (id)lpGUIRootView:(NSString *)link { [self window]; return customContainer; }

- (id)lpGUICustomController:(NSString *)link { return [[[self links] objectForKey:@"controller"] otherObject:self]; }

- (void)linkPrune {
  if (![[self links] objectForKey:@"outward"] && ![self probe:@selector(lpDontPruneGUIWindow:) ofLinkFor:@"controller"]) {
    [[self window] performClose:self];
  }
}

// --- GUI management ---

- (NSRect)customAreaBounds {
  return [customContainer bounds];
}

- (void)shrinkwrap {
  NSEnumerator *e = [[customContainer subviews] objectEnumerator];
  NSView *subview = nil;
  NSSize maxExtent = {0, 0};
  NSSize chrome = {0, 0};
  
  if (0) {
    NSRect myBounds = [[[self window] contentView] bounds];
    NSRect custFrame = [customContainer frame];
    chrome = NSMakeSize(
      myBounds.size.width - custFrame.size.width,
      myBounds.size.height - custFrame.size.height
    );
  }
  
  while ((subview = [e nextObject])) {
    NSRect r = [subview frame];
    if (r.origin.x + r.size.width > maxExtent.width)
      maxExtent.width = r.origin.x + r.size.width;
    if (r.origin.y + r.size.height > maxExtent.height)
      maxExtent.height = r.origin.y + r.size.height;
  }
  
  [[self window] setContentSize:NSMakeSize(
    maxExtent.width + chrome.width,
    maxExtent.height + chrome.height
  )];
  
  [[self window] center];
}

// --- Actions and validation ---

- (IBAction)mwOpenConnection:(id)sender {
  NSBeep();
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(mwOpenConnection:)) {
    return NO;
  } else {
    return [super validateUserInterfaceItem:item];
  }
}

// --- Window management ------------------------------------------------------------

- (NSString *)computeWindowTitle {
  return [NSString stringWithFormat:@"%@: %@", [super computeWindowTitle], [self title]];
}

// --- Accessors ------------------------------------------------------------

- (NSString *)title { return title; }
- (void)setTitle:(NSString *)str {
  [title autorelease];
  title = [str retain];
  [self updateWindowTitle];
}

@end
