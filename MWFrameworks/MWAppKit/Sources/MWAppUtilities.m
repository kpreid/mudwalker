/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#include "MWAppUtilities.h"

NSString * MWEventToStringCode(NSEvent *event) {
  NSMutableString *code = [NSMutableString stringWithCapacity:3];
  unsigned flags = [event modifierFlags];
  
  if (flags & NSShiftKeyMask) [code appendString:@"$"];
  if (flags & NSControlKeyMask) [code appendString:@"^"];
  if (flags & NSAlternateKeyMask) [code appendString:@"~"];
  if (flags & NSCommandKeyMask) [code appendString:@"@"];
  if (flags & NSNumericPadKeyMask) [code appendString:@"#"];
  
  [code appendString:@"'"];
  [code appendString:[event charactersIgnoringModifiers]];
  
  return [[code copy] autorelease];
}

NSString * MWEventToHumanReadableString(NSEvent *event) {
  // FIXME: localization, support non-key events
  NSMutableString *code = [NSMutableString string];
  unsigned flags = [event modifierFlags];
  
  if (flags & NSNumericPadKeyMask) [code appendString:@"keypad "];
  if (flags & NSShiftKeyMask) [code appendString:@"shift-"];
  if (flags & NSControlKeyMask) [code appendString:@"control-"];
  if (flags & NSAlternateKeyMask) [code appendString:@"option-"];
  if (flags & NSCommandKeyMask) [code appendString:@"command-"];
  
  [code appendString:[event charactersIgnoringModifiers]];
  
  return [[code copy] autorelease];
}
