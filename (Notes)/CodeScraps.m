/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This file is for code sections smaller than a file that are no longer used, but might be of interest later. 
\*/

// Should create a shell terminal:

  if (0) {
    MWTextOutputWinController *tw = [[[MWTextOutputWinController alloc] init] autorelease];
    MWNSFileHandleConnection *fhc = [[[MWNSFileHandleConnection alloc] init] autorelease];
    id <MWLinkableObject> ef = [[[NSClassFromString(@"MWEncodingFilter") alloc] init] autorelease];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *outPipe = [NSPipe pipe];
  
    [fhc setConfig:[[MWRegistry defaultRegistry] config]];
    [ef setConfig:[[MWRegistry defaultRegistry] config]];
  
    [task setLaunchPath:@"/usr/bin/login"];
    [task setArguments:[NSArray arrayWithObject:@"-fp"]];
    [task setStandardInput:[outPipe fileHandleForReading]];
    [task setStandardOutput:[inPipe fileHandleForWriting]];
    [task setStandardError:[inPipe fileHandleForWriting]];
  
    [fhc setReadHandle:[inPipe fileHandleForReading]];
    [fhc setWriteHandle:[outPipe fileHandleForWriting]];
  
    [tw link:@"outward" to:@"inward" of:ef];
    [ef link:@"outward" to:@"inward" of:fhc];
    [tw showWindow:nil];
  }


// Inline image display from MWTriggerFilter

  while (0 && (aRange = [buf rangeOfString:@"<img "]).length) {
    NSRange endMarker = [buf rangeOfString:@">" options:0 range:MWMakeABRange(aRange.location, [buf length])];
    NSString *mid = nil;
    NSAttributedString *imstr = nil;
    
    if (!endMarker.length) break;
    
    mid = [buf substringWithRange:MWMakeABRange(aRange.location + aRange.length, endMarker.location)];
    
    {
      NSString *path = [[MWRegistry defaultRegistry] pathForResourceFromSearchPath:[NSString stringWithFormat:@"%@", mid]];
      NSTextAttachment *tach = [
        [[NSTextAttachment alloc] initWithFileWrapper:
          [[[NSFileWrapper alloc] initWithPath:path] autorelease]
        ]
      autorelease];
      imstr = [NSAttributedString attributedStringWithAttachment:tach];
    }
    
    [abuf replaceCharactersInRange:MWMakeABRange(aRange.location, endMarker.location + endMarker.length) withAttributedString:imstr];
  }



- (BOOL)tabView:(NSTabView *)view shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
  return (NSResponder *)view == [[self window] firstResponder] ? YES : [[self window] makeFirstResponder:nil];
}

