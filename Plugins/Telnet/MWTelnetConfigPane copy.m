/*\  
 * MudWalker Source
 * Copyright 2001-2002 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTelnetConfigPane.h"

#define LINE_ENDING_POP_CR 0
#define LINE_ENDING_POP_LF 1
#define LINE_ENDING_POP_CRLF 2
#define LINE_ENDING_POP_LFCR 3

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
}

// --- Control updating and config setting ---

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];

  if (!path || [path isEqual:[MWConfigPath pathWithComponent:@"CharEncoding"]]) {
    NSNumber *value = [[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"CharEncoding"]];
    [cEncoding selectItemAtIndex:[cEncoding indexOfItemWithTag:[value unsignedIntValue]]];
  }

  if (!path || [path isEqual:[MWConfigPath pathWithComponent:@"LineEnding"]]) {
    NSString *value = [[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"LineEnding"]];

    int tag;
    if      ([value isEqualToString:@"\r"]) tag = LINE_ENDING_POP_CR;
    else if ([value isEqualToString:@"\n"]) tag = LINE_ENDING_POP_LF;
    else if ([value isEqualToString:@"\r\n"]) tag = LINE_ENDING_POP_CRLF;
    else if ([value isEqualToString:@"\n\r"]) tag = LINE_ENDING_POP_LFCR;
    else tag = -1; // !!!

    [cLineEnding selectItemAtIndex:[cLineEnding indexOfItemWithTag:tag]];
  }

  if (!path || [path isEqual:[MWConfigPath pathWithComponent:MWConfigureTelnetPromptTimeout]]) {
    NSNumber *value = [[notif object] objectAtPath:[MWConfigPath pathWithComponent:MWConfigureTelnetPromptTimeout]];
    [cPromptTimeout setObjectValue:value];
  }
}

- (IBAction)cEncodingAction:(id)sender {
  MWConfigPath *path = [MWConfigPath pathWithComponent:@"CharEncoding"];
  NSNumber *newValue = [NSNumber numberWithUnsignedInt:[[sender selectedItem] tag]];
  if (![newValue isEqual:[[self configTarget] objectAtPath:path]]) 
    [[self configTarget] setObject:newValue atPath:path];
}

- (IBAction)cLineEndingAction:(id)sender {
  MWConfigPath *path = [MWConfigPath pathWithComponent:@"LineEnding"];
  NSString *newValue;
  switch ([[sender selectedItem] tag]) {
    case LINE_ENDING_POP_CR: newValue = @"\r"; break;
    case LINE_ENDING_POP_LF: newValue = @"\n"; break;
    case LINE_ENDING_POP_CRLF: newValue = @"\r\n"; break;
    case LINE_ENDING_POP_LFCR: newValue = @"\n\r"; break;
    default: newValue = @"\n"; break;
  }
  if (![newValue isEqual:[[self configTarget] objectAtPath:path]]) 
    [[self configTarget] setObject:newValue atPath:path];
}

- (IBAction)cPromptTimeoutAction:(id)sender {
  MWConfigPath *path = [MWConfigPath pathWithComponent:MWConfigureTelnetPromptTimeout];
  if (![(id)[sender objectValue] isEqual:[[self displaySupplier] objectAtPath:path]])
    [[self configTarget] setObject:(id)[sender objectValue] atPath:path];
}

@end
