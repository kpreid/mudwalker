/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/
#import "MWURLFormatter.h"
#import <MudWalker/MWUtilities.h>

@implementation MWURLFormatter

- (NSString *)stringForObjectValue:(id)anObject {
  if ([anObject respondsToSelector:@selector(absoluteString)]) {
    return [(NSURL *)anObject absoluteString];
  } else if ([anObject isKindOfClass:[NSString class]]) {
    return (NSString *)anObject;
  } else {
    return [anObject description];
  }
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  NSURL *newURL;

  if (![string rangeOfString:@"//"].length)
    string = [NSString stringWithFormat:@"telnet://%@", string];
   
  newURL = [NSURL URLWithString:string];
  //NSLog(@"%@ got '%@' %p => '%@' >>%@ :// %@ : %i  %@<<", self, string, string, newURL, [newURL scheme], [newURL host], [newURL port], [newURL path]);
  
  if (!newURL) {
    if (error) *error = MWLocalizedStringHere(@"MWURLFormatter-invalid");
    return NO;
  } else if (![[newURL scheme] length]) {
    if (error) *error = MWLocalizedStringHere(@"MWURLFormatter-noScheme");
    return NO;
  } else if (![[newURL host] length]) {
    if (error) *error = MWLocalizedStringHere(@"MWURLFormatter-noHost");
    return NO;
  //} else if (![newURL port]) {
  //  if (error) *error = MWLocalizedStringHere(@"MWURLFormatter-noPort");
  //  return NO;
  } else {
    if (anObject) *anObject = newURL;
    return YES;
  }
}


@end
