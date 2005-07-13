/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWLibraryMenuController.h"

#import <AppKit/NSMenu.h>
#import <AppKit/NSImage.h>
#import "MWMudLibrary.h"
#import "MWLibraryItem.h"

@implementation MWLibraryMenuController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWLibraryDidChangeNotification object:theLibrary]; 
  [theMenu autorelease]; theMenu = nil;
  [theLibrary autorelease]; theLibrary = nil;
  [super dealloc];
}

- (void)update {
  if (!theMenu)
    return;

  while ([theMenu numberOfItems])
    [theMenu removeItemAtIndex:0];
    
  int i, n = [theLibrary libItemNumberOfChildren];
  for (i = 0; i < n; i++) {
    id <MWLibraryItem> const libItem = [theLibrary libItemChildAtIndex:i];
    NSMenuItem *const menuItem = [[[NSMenuItem alloc] init] autorelease];
    
    if ([(id)[libItem objectForKey:@"name"] length])
      [menuItem setTitle:(id)[libItem objectForKey:@"name"]];
    else
      [menuItem setTitle:[[libItem objectForKey:@"location"] description]];
    {
      NSImage *const img = [[[libItem libItemImage] copy] autorelease];
      [img setScalesWhenResized:YES];
      [img setSize:NSMakeSize(16, 16)];
      [menuItem setImage:img];
    }
    [menuItem setTarget:libItem];
    [menuItem setAction:@selector(performOpenAction:)];
     
    [theMenu addItem:menuItem];
  }
}

- (void)libraryDidChange:(NSNotification *)notif {
  [self update];
}

- (NSMenu *)menu { 
  return theMenu;
}

- (void)setMenu:(NSMenu *)newVal {
  [theMenu autorelease];
  theMenu = [newVal retain];
}

- (void)setLibrary:(MWMudLibrary *)newVal {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWLibraryDidChangeNotification object:theLibrary]; 
  [theLibrary autorelease];
  theLibrary = [newVal retain];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDidChange:) name:MWLibraryDidChangeNotification object:theLibrary]; 
  [self update];
}

@end
