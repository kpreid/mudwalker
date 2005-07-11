/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWANSIColorFilter.h"

// fixme: inappropriate dependency
#import "MWColorConverter.h"

#import <MudWalker/MudWalker.h>

enum Brightness { Dim = -1, Normal, Bright };

@interface MWANSIColorFilter (Private)

- (void)resetAttributes;
- (void)applyAttributesToString:(NSMutableAttributedString *)astr range:(NSRange)r;
- (void)attributify:(NSMutableAttributedString *)astr;

@end

@implementation MWANSIColorFilter

- (MWANSIColorFilter *)init {
  if (!(self = (MWANSIColorFilter *)[super init])) return nil;

  [self resetAttributes];
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

// --- Linkage ---

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[MWLineString class]]) {
      NSMutableAttributedString *s = [[obj attributedString] mutableCopy];
      [self attributify:s];
      [self send:[MWLineString lineStringWithAttributedString:s role:[obj role]] toLinkFor:@"inward"];
    } else if ([obj isKindOfClass:[NSAttributedString class]]) {
      NSMutableAttributedString *s = [obj mutableCopy];
      [self attributify:s];
      [self send:[[s copy] autorelease] toLinkFor:@"inward"];
    } else if ([obj isKindOfClass:[NSString class]]) {
      NSMutableAttributedString *s = [[[NSMutableAttributedString alloc] initWithString:obj attributes:[NSDictionary dictionary]] autorelease];
      [self attributify:s];
      [self send:[[s copy] autorelease] toLinkFor:@"inward"];
    } else {
      [self send:obj toLinkFor:@"inward"];
    }
    return YES;
  } else if ([link isEqual:@"inward"]) {
    // no outward processing needed that I know of (unless we implement arrow key codes or other such)
    [self send:obj toLinkFor:@"outward"];
    return YES;
  }
  return NO;
}

// --- Utilities ---

/*
  Algorithm for applying attributes appropriately:
  
  0. Have a set of variables for current attributes
  1. Find an attribute-change sequence (^[[...m)
  2. Modify the variables according to the above ...
  3. Apply all attributes to the text from there to the next ^[[, or the end of the string.
  4. Delete change sequence.
  5. Repeat.
  
  Note that state must be preserved in instance vars since styles run over line breaks.
*/

- (void)attributeDebug:(NSString *)where {
  if (0) NSLog(
    @"%@: fg%i bg%i br%i u%i b%i i%i",
    where,
    styleForeColor,
    styleBackColor,
    styleBrightness,
    styleUnderline,
    styleBlinking,
    styleInverse
  );
}

- (void)attributify:(NSMutableAttributedString *)astr {
  NSString *sstr = [astr string];
  unsigned int lastMatchLocation = 0, len;
  NSRange foundEscRange;
  BOOL first = YES;
  
  [self attributeDebug:[NSString stringWithFormat:@"entering attributify (%@)", [astr string]]];
  
  while ((foundEscRange = [sstr rangeOfString:@"\x1b[" options:0 range:MWMakeABRange(lastMatchLocation, (len = [sstr length]))]).length) {
    NSRange foundToEndOfStringRange = MWMakeABRange(foundEscRange.location, len);
    NSRange endEscRange = [sstr rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet] options:0 range:foundToEndOfStringRange]; 
    NSRange escRange = MWMakeABRange(foundEscRange.location, endEscRange.location + endEscRange.length);
    NSString *endEscChar = nil;

    if (first) {
      first = NO;
      [self applyAttributesToString:astr range:NSMakeRange(0, foundEscRange.location)];
    }

    if (!endEscRange.length) {
      // unterminated sequence, abort!
      return;
    }
    
    endEscChar = [sstr substringWithRange:endEscRange];
    if ([endEscChar isEqual:@"m"]) {
      NSArray *ansiNumberStrings = [[sstr substringWithRange:MWMakeABRange(foundEscRange.location + 2, endEscRange.location)] componentsSeparatedByString:@";"];
      NSEnumerator *e = [ansiNumberStrings objectEnumerator];
      NSString *aString;
      //printf("found escape with %s\n", [[ansiNumberStrings description] cString]);
      
      while ((aString = [e nextObject])) {
        int code = [aString intValue];
        //printf("processing code %i\n", code);
        switch (code / 10) {
          case 0: case 2: {
            BOOL yesNo = !(code / 10);
            //printf("0 or 2 code, yesNo = %i, c%%10 = %i\n", yesNo, code % 10);
            switch (code % 10) {
              case  0: [self resetAttributes]; break;
              case  1: styleBrightness = yesNo * Bright; break;
              case  2: styleBrightness = yesNo * Dim; break; // relies on normal brightness == 0
              case  4: styleUnderline = yesNo; break;
              case  5: styleBlinking = yesNo; break;
              case  7: styleInverse = yesNo; break;
            }
            //printf("after, sBri = %i, sUnd = %i\n", styleBrightness, styleUnderline);
            break;
          }
          case 3: styleForeColor = code - 30; break;
          case 4: styleBackColor = code - 40; break;
          default:
            break;
        }
      }
    }
    
    [self applyAttributesToString:astr range:foundToEndOfStringRange];
    [astr replaceCharactersInRange:escRange withString:@""];
    lastMatchLocation = foundEscRange.location;
  }
  
  // If there are no escapes at all in the string, apply the remembered attributes
  if (first) {
    [self applyAttributesToString:astr range:NSMakeRange(0, [astr length])];
  }

  
  [self attributeDebug:@"leaving attributify"];
}

- (void)applyAttributesToString:(NSMutableAttributedString *)astr range:(NSRange)r {
  [astr addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:styleBrightness], MWANSIBrightnessAttribute,
    [NSNumber numberWithInt:styleUnderline ], MWANSIUnderlineAttribute,
    [NSNumber numberWithInt:styleBlinking  ], MWANSIBlinkingAttribute,
    [NSNumber numberWithInt:styleInverse   ], MWANSIInverseAttribute,
    [NSNumber numberWithInt:styleForeColor ], MWANSIForegroundAttribute,
    [NSNumber numberWithInt:styleBackColor ], MWANSIBackgroundAttribute,
    nil
  ] range:r];
}

- (void)resetAttributes {
  styleForeColor = MWCOLOR_INDEX_DFORE;
  styleBackColor = MWCOLOR_INDEX_DBACK;
  styleBrightness = Normal;
  styleUnderline = styleBlinking = styleInverse = NO;
}

@end
