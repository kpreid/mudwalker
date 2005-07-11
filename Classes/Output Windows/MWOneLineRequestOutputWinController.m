/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWOneLineRequestOutputWinController.h"

#import <MudWalker/MudWalker.h>

@implementation MWOneLineRequestOutputWinController

// --- Initialization ------------------------------------------------------------

- (MWOneLineRequestOutputWinController *)init {
  if (!(self = (MWOneLineRequestOutputWinController *)[super init])) return nil;

  return self;
}

- (void)dealloc {
  [message autorelease];
  message = nil;
  [super dealloc];
}

- (NSString *)outputWindowNibName {return @"OneLineRequestOutputWindow";}

// --- Input/output ------------------------------------------------------------

- (BOOL)inputClientActive { return NO; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if (![link isEqualToString:@"outward"])
    return [super receive:obj fromLinkFor:link];
  
  if ([obj isKindOfClass:[MWLineString class]] && [[(MWLineString *)obj role] isEqualToString:MWStatusRole]) {
    [self setMessage:[obj string]];
    return YES;
  } else if ([super receive:obj fromLinkFor:link]) {
    return YES;
  } else {
    [inputField setObjectValue:[obj description]];
    return YES;
  }
}

- (void)linkPrune {
  if (![[self links] objectForKey:@"outward"]) {
    [[self window] performClose:self];
  }
}

// --- Window management ------------------------------------------------------------

- (IBAction)buttonCancel:(id)sender {
  [[self window] close];
}
- (IBAction)buttonOK:(id)sender {
  [self send:[inputField stringValue] toLinkFor:@"outward"];
  [[self window] close];
}

- (void)windowDidBecomeKey:(NSNotification *)notif {
  [[self window] makeFirstResponder:inputField];
}

- (NSString *)computeWindowTitle {
  return [NSString stringWithFormat:@"%@: %@", [super computeWindowTitle], [[[self extInputManager] inputPrompt] string]];
}
	
// --- Accessors ------------------------------------------------------------

- (void)setInputPrompt:(NSAttributedString *)str {
  [super setInputPrompt:str];
  [self updateWindowTitle];
}

- (NSString *)message { return message; }
- (void)setMessage:(NSString *)str {
  [message autorelease];
  message = [str retain];
  [details setObjectValue:message];
}

- (void)setExtInputManager:(id <MWExtInputManager>)newVal {
  [super setExtInputManager:newVal];
  [newVal setActive:NO];
}

@end
