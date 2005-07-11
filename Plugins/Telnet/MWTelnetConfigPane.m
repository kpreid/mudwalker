/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTelnetConfigPane.h"

@implementation MWTelnetConfigPane

// --- Encoding menu ---

static int encodingSort(id a, id b, void *context) {
  return [
    [NSString localizedNameOfStringEncoding:[a unsignedIntValue]]
    compare:
    [NSString localizedNameOfStringEncoding:[b unsignedIntValue]]
  ];
}

- (void)fillEncodingsMenu {
  NSMutableArray *sortedEncodings = [NSMutableArray array];
  const NSStringEncoding *encoding;
  
  for (encoding = [NSString availableStringEncodings]; *encoding != 0; encoding++) {
    [sortedEncodings addObject:[NSNumber numberWithUnsignedInt:*encoding]];
  }
  [sortedEncodings sortUsingFunction:encodingSort context:NULL];
  
  {
    NSEnumerator *encNumE = [sortedEncodings objectEnumerator];
    NSNumber *encNum;
    while ((encNum = [encNumE nextObject])) {
      NSStringEncoding enc = [encNum unsignedIntValue];
       
      if ([cEncoding indexOfItemWithTag:enc] == -1) {
        [cEncoding addItemWithTitle:[NSString localizedNameOfStringEncoding:enc]];
        //[cEncoding addItemWithTitle:[NSString stringWithFormat:@"%@  [%i]", [NSString localizedNameOfStringEncoding:enc], enc]];
        [[cEncoding lastItem] setTag:enc];
      }
    }
  }
  
  [cEncoding setAutoenablesItems:NO];
}

- (void)mainViewDidLoad {
  [super mainViewDidLoad];

  [self fillEncodingsMenu];

  [caLineEnding setTagToObjectLookups:[NSDictionary dictionaryWithObjectsAndKeys:
    @"\r", [NSNumber numberWithInt:0],
    @"\n", [NSNumber numberWithInt:1],
    @"\r\n", [NSNumber numberWithInt:2],
    @"\n\r", [NSNumber numberWithInt:3],
    nil
  ]];
}

@end
