/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWScriptContexts.h"

#import "MWLineString.h"

NSString *MWScriptContextsWillSendDebugMessageNotification = @"MWScriptContextsWillSendDebugMessageNotification";

@implementation MWScriptContexts

- (id)init {
  if (!(self = [super init])) return nil;

  contexts = [[NSMutableDictionary allocWithZone:[self zone]] init];

  return self;
}

- (void)dealloc {
  [contexts autorelease]; contexts = nil;
  [super dealloc];
}

- (NSSet *)linkNames     { return [NSSet setWithObject:@"debug"]; }
- (NSSet *)linksRequired { return [NSSet setWithObject:@"debug"]; }

- (id)contextForLanguageIdentifier:(NSString *)languageIdentifier {
  return [contexts objectForKey:languageIdentifier];
}

- (void)setContext:(id)context forLanguageIdentifier:(NSString *)languageIdentifier {
  [contexts setObject:context forKey:languageIdentifier];
}

- (void)postDebugMessage:(NSString *)s {
  NSLog(@"%@ debug: %@", self, s);
  [[NSNotificationCenter defaultCenter] postNotificationName:MWScriptContextsWillSendDebugMessageNotification object:self];
  [self send:[MWLineString lineStringWithString:s] toLinkFor:@"debug"];
}

@end
