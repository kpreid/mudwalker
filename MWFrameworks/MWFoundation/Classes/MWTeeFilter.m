/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTeeFilter.h"

@implementation MWTeeFilter

- (NSSet *)linkNames { return [NSSet setWithObjects:@"inward", @"outward", @"teeInward", @"teeOutward", nil]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqualToString:@"inward"]) {
    [self send:obj toLinkFor:@"teeOutward"];
    [self send:obj toLinkFor:@"outward"];
    return YES;
  } else if ([link isEqualToString:@"outward"]) {
    [self send:obj toLinkFor:@"teeInward"];
    [self send:obj toLinkFor:@"inward"];
    return YES;
  } else {
    return NO;
  }
}

@end
