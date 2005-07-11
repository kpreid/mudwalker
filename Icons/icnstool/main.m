#import "IconFamily.h"
#import <Foundation/Foundation.h>
#import <MudWalker/MWUtilities.h>

int main(int argc, char *argv[]) {
  NSAutoreleasePool *const pool = [[NSAutoreleasePool alloc] init];

  if (argc != 2) {
    printf("Usage: %s <filename>   (without .icns extension)", argv[0]);
    return 1;
  }
  NSString *const filebase = [NSString stringWithCString:argv[1]];
  
  NSDictionary *const sizes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedLong:kSmall32BitData],
      [NSNumber numberWithUnsignedLong:kSmall8BitData],
      [NSNumber numberWithUnsignedLong:kSmall8BitMask],
      [NSNumber numberWithUnsignedLong:kSmall1BitMask],
    nil],
    [NSNumber numberWithInt:16],
    [NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedLong:kLarge32BitData],
      [NSNumber numberWithUnsignedLong:kLarge8BitData],
      [NSNumber numberWithUnsignedLong:kLarge8BitMask],
      [NSNumber numberWithUnsignedLong:kLarge1BitMask],
    nil],
    [NSNumber numberWithInt:32],
    [NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedLong:kHuge32BitData],
      [NSNumber numberWithUnsignedLong:kHuge8BitData],
      [NSNumber numberWithUnsignedLong:kHuge8BitMask],
      [NSNumber numberWithUnsignedLong:kHuge1BitMask],
    nil],
    [NSNumber numberWithInt:48],
    [NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedLong:kThumbnail32BitData],
      [NSNumber numberWithUnsignedLong:kThumbnail8BitMask],
    nil],
    [NSNumber numberWithInt:128],
  nil];
  
  IconFamily *const family = [IconFamily iconFamilyWithSystemIcon:'APPL'];
  
  MWenumerate ([sizes keyEnumerator], NSNumber *, size) {
  
    NSString *const imagePath = [filebase stringByAppendingString:[NSString stringWithFormat:@"-intermediate-%i.png", [size intValue]]];
    NSImage *const imageOfAppropriateSize = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    
    if (!imageOfAppropriateSize) {
      NSLog(@"Could not open image %@", imagePath);
      return 1;
    }
    
    MWenumerate([[sizes objectForKey:size] objectEnumerator], NSNumber *, elementKey) {
      //NSLog(@"%@ %@ -> %@", size, imageOfAppropriateSize, elementKey);
      [family 
        setIconFamilyElement:[elementKey unsignedLongValue]
        fromBitmapImageRep:[[imageOfAppropriateSize representations] objectAtIndex:0]];
    }
  }
  
  [family writeToFile:[filebase stringByAppendingPathExtension:@"icns"]];
  
  [pool release];
  return 0;
}