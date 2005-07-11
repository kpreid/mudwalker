/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWLinkTraceConsole.h"

@implementation MWLinkTraceConsole

- (id)init {
  if (!(self = [super init])) return nil;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(traceLine:) name:MWLinkTraceNotification object:nil];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)traceLine:(NSNotification *)notif {
  [self send:[MWLineString lineStringWithString:[[notif userInfo] objectForKey:@"message"] role:nil] toLinkFor:@"inward"];
}

- (NSSet *)linkNames { return [NSSet setWithObject:@"inward"]; }

- (NSSet *)linksRequired { return [NSSet setWithObject:@"inward"]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if (![link isEqual:@"inward"]) return NO;

  if ([obj isKindOfClass:[MWToken class]]) {
    if ([obj isEqual:MWTokenCloseConnection] || [obj isEqual:MWTokenLogoutConnection]) {
      [self unlinkAll];
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

- (NSString *)linkableUserDescription {
  return MWLocalizedStringHere(@"LinkTraceConsoleDescription"); 
}

- (id)lpConnectionDescription:(NSString *)link { return [self linkableUserDescription]; }

@end
