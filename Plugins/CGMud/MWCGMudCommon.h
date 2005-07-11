/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "CGMud/Mud.h"
#import "CGMud/Request.h"
#import "CGMud/Effects.h"

#define LAYOUT_VIEW_PADDING 2

#define CTYPE_PROMPTED_TEXT	1
#define CTYPE_GENERAL_TEXT	2
#define CTYPE_ICON_LIST		3
#define CTYPE_ICONED_CANVAS	4
#define CTYPE_BUTTON_PANEL	5

#define CGMUD_ENCODING NSISOLatin1StringEncoding

#define RAWKEY_UPLEFT      1
#define RAWKEY_UP          2
#define RAWKEY_UPRIGHT     3
#define RAWKEY_LEFT        4
#define RAWKEY_CENTER      5
#define RAWKEY_RIGHT       6
#define RAWKEY_DOWNLEFT    7
#define RAWKEY_DOWN        8
#define RAWKEY_DOWNRIGHT   9
#define RAWKEY_PLUS       10
#define RAWKEY_MINUS      11
#define RAWKEY_HELP	  32
