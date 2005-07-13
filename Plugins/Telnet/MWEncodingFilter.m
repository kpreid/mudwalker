/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWEncodingFilter.h"

#import <MudWalker/MudWalker.h>

@implementation MWEncodingFilter

- (MWEncodingFilter *)init {
  if (!(self = (MWEncodingFilter *)[super init])) return nil;

  encoding = NSASCIIStringEncoding;
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

// --- Linkage ---

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[NSData class]]) {
      [self send:[[[NSString alloc] initWithData:obj encoding:encoding] autorelease] toLinkFor:@"inward"];
    } else if ([obj isKindOfClass:[MWLineData class]]) {
      [self send:[MWLineString lineStringWithString:[[[NSString alloc] initWithData:[obj data] encoding:encoding] autorelease] role:[obj role]] toLinkFor:@"inward"];
    } else {
      [self send:obj toLinkFor:@"inward"];
    }
    return YES;
  } else if ([link isEqual:@"inward"]) {
    id outObj;
    
    if ([obj isKindOfClass:[MWLineString class]]) {
      outObj = [[[MWLineData alloc] initWithData:[[(MWLineString *)obj string] dataUsingEncoding:encoding allowLossyConversion:YES] role:[(MWLineString *)obj role]] autorelease];
    } else if ([obj isKindOfClass:[NSString class]]) {
      outObj = [(NSString *)obj dataUsingEncoding:encoding allowLossyConversion:YES];
    } else if ([obj isKindOfClass:[MWLineData class]]) {
      outObj = obj;
    } else if ([obj isKindOfClass:[NSData class]]) {
      outObj = obj;
    } else {
      outObj = obj;
    }

    [self send:outObj toLinkFor:@"outward"];
    return YES;
  }
  return NO;
}

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  
  encoding = [(NSNumber *)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"CharEncoding"]] unsignedIntValue];
}

@end
