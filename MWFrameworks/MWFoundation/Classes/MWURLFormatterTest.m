/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>
#import <MudWalker/MWURLFormatter.h>

@interface MWURLFormatterTest : TestCase {
  MWURLFormatter *formatter;
} @end

@implementation MWURLFormatterTest

- (void)setUp {
  formatter = [[MWURLFormatter alloc] init];
}

- (void)tearDown {
  [formatter release]; formatter = nil;
}

- (void)testWithSchemeHostPort {
  NSURL *obj = nil;
  NSString *string = @"telnet://127.1:35211";
  NSString *error = nil;
  BOOL res = [formatter getObjectValue:&obj forString:string errorDescription:&error];
  
  [self assertTrue:res];
  [self assert:obj equals:[NSURL URLWithString:@"telnet://127.1:35211"]];
  [self assertNil:error];
}

- (void)testWithHostPort {
  NSURL *obj = nil;
  NSString *string = @"127.1:35211";
  NSString *error = nil;
  BOOL res = [formatter getObjectValue:&obj forString:string errorDescription:&error];
  
  [self assertTrue:res message:@"res false"];
  [self assert:obj equals:[NSURL URLWithString:@"telnet://127.1:35211"]];
  [self assertNil:error message:@"error not nil"];
}

- (void)testWithSchemeHost {
  NSURL *obj = nil;
  NSString *string = @"telnet://127.1";
  NSString *error = nil;
  BOOL res = [formatter getObjectValue:&obj forString:string errorDescription:&error];
  
  [self assertTrue:res];
  [self assert:obj equals:[NSURL URLWithString:@"telnet://127.1"]];
  [self assertNil:error];
}

- (void)testWithScheme {
  NSURL *obj = nil;
  NSString *string = @"telnet://";
  NSString *error = nil;
  BOOL res = [formatter getObjectValue:&obj forString:string errorDescription:&error];
  
  [self assertFalse:res];
  [self assertNil:obj];
}
@end