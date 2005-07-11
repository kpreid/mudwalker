/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <ObjcUnit/ObjcUnit.h>

#import "MWLibraryMenuController.h"
#import "MWMudLibrary.h"
#import <AppKit/NSMenu.h>

@interface MWLibraryMenuControllerTest_MockUserDefaults : NSObject {
  NSMutableDictionary *data;
}

- (void)setObject:(id)obj forKey:(id)key;

@end

@implementation MWLibraryMenuControllerTest_MockUserDefaults

- (id)init {
  if (!(self = [super init])) return nil;
  
  data = [[NSMutableDictionary alloc] init];
  
  return self;
}

- (void)dealloc {
  [data autorelease];
  [super dealloc];
}

- (id)objectForKey:(id)key { return [data objectForKey:key]; }
- (id)dictionaryForKey:(id)key { return [data objectForKey:key]; }
- (void)setObject:(id)obj forKey:(id)key { 
  [data setObject:obj forKey:key]; 
  [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:self];
}

@end

@interface MWLibraryMenuControllerTest : TestCase {
  NSMenu *menu;
  MWLibraryMenuControllerTest_MockUserDefaults *ud;
  MWMudLibrary *l;
  MWLibraryMenuController *lmc;
} @end

@implementation MWLibraryMenuControllerTest

- (void)setUp {
  ud = [[MWLibraryMenuControllerTest_MockUserDefaults alloc] init];
  l = [[MWMudLibrary alloc] initWithUserDefaults:(NSUserDefaults *)ud];
  menu = [[NSMenu alloc] init];
  lmc = [[MWLibraryMenuController alloc] init];
  [lmc setMenu:menu];
  [lmc setLibrary:l];
}

- (void)tearDown {
  [menu release]; menu = nil;
  [ud release]; ud = nil;
  [l release]; l = nil;
  [lmc release]; lmc = nil;
}

- (void)testNothing {
  [self assertInt:[l libItemNumberOfChildren] equals:0];
  [self assertInt:[[lmc menu] numberOfItems] equals:0];
}

- (void)testOneAddress {
  [ud setObject:[NSDictionary
      dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Test", @"name",
      nil]
      forKey:@"telnet://foo"]
    forKey:@"MWLibraryAddresses"];
  [self assertInt:[l libItemNumberOfChildren] equals:1 message:@"nOC"];
  
  [self assertInt:[menu numberOfItems] equals:1 message:@"nOI"];
  
  NSMenuItem *item = [menu itemAtIndex:0];
  [self assert:[item title] equals:@"Test"];
}

@end