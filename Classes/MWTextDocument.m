/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWTextDocument.h"

#import <MudWalker/MudWalker.h>
#import "MWTextDocumentWinController.h"

NSString *MWTextDocument_PlainType = @"NSStringPboardType";
static NSStringEncoding defaultFileEncoding = NSUTF8StringEncoding;

@implementation MWTextDocument

- (id)init {
  if (!(self = [super init])) return nil;
  
  textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
  [textStorage setDelegate:self];
    
  return self;
}

- (void)dealloc {
  [textStorage autorelease]; textStorage = nil;
  [super dealloc];
}

- (void)makeWindowControllers {
  id wc = [[[MWTextDocumentWinController allocWithZone:[self zone]] init] autorelease];
  [self addWindowController:wc];
  [wc setReadOnly:readOnly];
}

- (IBAction)saveDocument:(id)sender {
  if (readOnly)
    NSBeep();
  else
    [super saveDocument:sender];
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
  if ([type isEqualToString:MWTextDocument_PlainType]) {
    return [[textStorage string] dataUsingEncoding:defaultFileEncoding allowLossyConversion:YES];
  } else {
    return nil;
  }
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
  if ([type isEqualToString:MWTextDocument_PlainType]) {
    NSString *str = [[[NSString alloc] initWithData:data encoding:defaultFileEncoding] autorelease];
    
    if (str) {
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [[[MWRegistry defaultRegistry] config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]], NSFontAttributeName,
        nil
      ];
      [textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:str attributes:attrs] autorelease]];
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

// --- Accessors ---

- (NSTextStorage *)textStorage { return textStorage; }

- (void)setReadOnly:(BOOL)newVal {
  readOnly = newVal;
  { NSEnumerator *e = [[self windowControllers] objectEnumerator];
    MWTextDocumentWinController *wc;
    while ((wc = [e nextObject])) {
      [wc setReadOnly:readOnly];
    }
  }
}

@end
