/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/


#import "MWURLLoadingImageView.h"


@implementation MWURLLoadingImageView

- (void)dealloc {
  [urlHandle removeClient:self];
  [urlHandle autorelease]; urlHandle = nil;
  [theURL autorelease]; theURL = nil;
  [super dealloc];
}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender {
  NSData *data = [sender resourceData];
  NSImage *theImage = nil;
  //NSLog(@"%@ finished loading from %@", self, sender);

  // NOTE: uhm, we want XBM support. ought to be able to provide a translator for NSImage to use automatically but the interface is not public
  
  if (!memcmp([data bytes], "#define ", 8)) {
    // it's an XBM, probably.

#   if CHAR_BIT != 8
#     error "this won't work"
#   endif
    
    NSScanner *scanner = [NSScanner scannerWithString:[[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease]];
    
    int width, height;
    NSBitmapImageRep *bitmapObj = nil;
    unsigned char *bitmapBuf;
    int byteIndex = 0;

    if (!([scanner scanString:@"#define" intoString:NULL]
       && [scanner scanUpToString:@"_width" intoString:NULL]
       && [scanner scanString:@"_width" intoString:NULL]
       && [scanner scanInt:&width]
       && [scanner scanString:@"#define" intoString:NULL]
       && [scanner scanUpToString:@"_height" intoString:NULL]
       && [scanner scanString:@"_height" intoString:NULL]
       && [scanner scanInt:&height]
       && [scanner scanUpToString:@"{"/*}*/ intoString:NULL]
       && [scanner scanString:@"{"/*}*/ intoString:NULL]
    )) {
      NSLog(@"Bad XBM header at character %i: \n%@", [scanner scanLocation], [scanner string]);
      goto badXBM;
    }
    
    bitmapObj = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:1 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceBlackColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    bitmapBuf = [bitmapObj bitmapData];
    
    for (byteIndex = 0; ![scanner scanString:/*{*/@"}" intoString:NULL] && byteIndex < width * height; byteIndex++) {
      unsigned int theByte, bit;
      if (![scanner scanHexInt:&theByte]) {
        NSLog(@"Bad XBM data at character %i, bitmap byte %i: \n%@", [scanner scanLocation], byteIndex, [scanner string]);
        goto badXBM;
      }
      // copy byte, with bits reversed
      bitmapBuf[byteIndex] = 0;
      for (bit = 0; bit < 8; bit++)
        bitmapBuf[byteIndex] |= (!!(theByte & (1 << (7-bit)))) << bit;
      [scanner scanString:@"," intoString:NULL];
      [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL]; // NSScanner bug?
    }
    
    theImage = [[[NSImage alloc] initWithSize:NSMakeSize(width, height)] autorelease];
    [theImage addRepresentation:bitmapObj];
    
    badXBM:;
  } else {
    theImage = [[[NSImage alloc] initWithData:[sender resourceData]] autorelease];
  }
  [self setImage:theImage];
  [self setNeedsDisplay:YES];
}

- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender {}
- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender {}
- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newData {}
- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason {
  NSLog(@"%@ failed from %@: %@", self, sender, reason);
}

- (NSURL *)URL { return theURL; }
- (void)setURL:(NSURL *)newVal {
  [urlHandle autorelease];
  [theURL autorelease];
  theURL = [newVal retain];
  urlHandle = [[theURL URLHandleUsingCache:YES] retain];

  [self setImage:nil];
  [urlHandle addClient:self];
  [urlHandle loadInBackground];
}

@end
