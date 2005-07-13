/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWAppKitPalette.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

@implementation MWAppKitPalette

- (id)init {
  if (!(self = [super init])) return nil;

  [NSView registerViewResourceDraggingDelegate:self];
  
  return self;
}

- (void)dealloc {
  [prototypeURLFormatter autorelease]; prototypeURLFormatter = nil;
  [super dealloc];
}

- (void)finishInstantiate {
  prototypeURLFormatter = [[MWURLFormatter alloc] init];

  [self associateObject:prototypeURLFormatter
                 ofType:IBFormatterPboardType
               withView:urlFormatterProxy];
}


- (NSArray *)viewResourcePasteboardTypes {
  return [NSArray array];
}

- (BOOL)acceptsViewResourceFromPasteboard:(NSPasteboard *)pasteboard forObject:(id)object atPoint:(NSPoint)point {
  return NO;
}

- (void)depositViewResourceFromPasteboard:(NSPasteboard *)pasteboard onObject:(id)object atPoint:(NSPoint)point {
}

- (BOOL)shouldDrawConnectionFrame {
  return YES;
}

@end

