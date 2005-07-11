/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Convenience macros for creating toolbar items.
\*/

#import <MudWalker/MWUtilities.h>

// change a toolbar item's appearance and action, but only if the action isn't already changed
#define MWTOOLBAR_ITEM_CHANGE(item, key, sel) do {\
  if (sel != [item action]) {\
    [item setPaletteLabel:MWLocalizedStringHere(@"TBL_" key)];\
    [item setLabel:       MWLocalizedStringHere(@"TBL_" key)];\
    [item setToolTip:     MWLocalizedStringHere(@"TBT_" key)];\
    [item setAction:sel];\
    [item setImage:[NSImage imageNamed:@"TB_" key]];\
  }\
} while(0)

// NOTE: self->toolbarItems bad

#define MWTOOLBAR_ITEM(key, targ, sel) do {\
  NSToolbarItem *item=[[[NSToolbarItem alloc] initWithItemIdentifier:key] autorelease];\
  [item setTarget:targ];\
  [self->toolbarItems setObject:item forKey:key];\
  MWTOOLBAR_ITEM_CHANGE(item, key, sel);\
} while (0)
    