/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWInterpreterConsole.h"

#import <MudWalker/MWInterpreter.h>
#import "MWTextOutputWinController.h"

@implementation MWInterpreterConsole

- (id)initWithInterpreter:(id <MWInterpreter>)terp {
  if (!(self = [super init])) return nil;
  
  interpreter = [terp retain];
  
  return self;
}

- (void)dealloc {
  [interpreter release]; interpreter = nil;
  [super dealloc];
}

- (void)openWindow {
  MWTextOutputWinController *tw = [[[MWTextOutputWinController alloc] init] autorelease];
  
  [tw link:@"outward" to:@"inward" of:self];
  [tw showWindow:nil];
}

- (void)processString:(NSString *)str {
  [self send:[interpreter evaluateLines:str] toLinkFor:@"inward"];
}

- (NSSet *)linkNames { return [NSSet setWithObject:@"inward"]; }

- (NSSet *)linksRequired { return [NSSet setWithObject:@"inward"]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if (![link isEqual:@"inward"]) return NO;

  if ([obj isKindOfClass:[MWToken class]]) {
    if ([obj isEqual:MWTokenCloseConnection] || [obj isEqual:MWTokenLogoutConnection]) {
      [self unlinkAll];
    } else if ([obj isEqual:MWTokenWindowSizeChanged]) {
      // do nothing
    } else {
      return NO;
    }
    return YES;
  } else if ([obj isKindOfClass:[MWLineString class]]) {
    [self processString:[(MWLineString *)obj string]];
    return YES;
  }
  return NO;
}

- (NSString *)linkableUserDescription {
  return [NSString stringWithFormat:@"%@%@", 
    MWLocalizedStringHere(@"InterpreterConsoleDescription"),
    [[interpreter class] localizedLanguageName]
  ]; 
}

- (id)lpConnectionDescription:(NSString *)link { return [self linkableUserDescription]; }

@end
