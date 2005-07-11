/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTextOutputWinController.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppKit.h>

#import "MWConnectionDocument.h"
#import "MWAppDelegate.h"
#import "MWTextTerminalPane.h"

static NSString *Splats = nil;

// FIXME: rename or perhaps remove this macro
#define pane ((MWTextTerminalPane *)terminalPane)

@implementation MWTextOutputWinController

+ (void)initialize {
  if (!Splats) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    // just a little hidden default
    int length = [ud integerForKey:@"password-splat-length"];
    if (!length) {
      length = 12;
      [ud setInteger:length forKey:@"password-splat-length"];
    }
    {
      unichar splats[length];
      int i;
      for (i = 0; i < length; i++) splats[i] = 0x2022;
      Splats = [[NSString stringWithCharacters:splats length:length] retain];
    }
  }
}

// --- Initialization ---

- (MWTextOutputWinController *)init {
  if (!(self = (MWTextOutputWinController *)[super init])) return nil;

  MWTOOLBAR_ITEM(@"mwClearScrollback", self, @selector(mwClearScrollback:));
  MWTOOLBAR_ITEM(@"autoScrollLock", self, @selector(autoScrollLock:));

  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (NSString *)outputWindowNibName {return @"TextOutputWindow";}

// --- Input/output ------------------------------------------------------------

- (void)inputClientReceive:(id)obj {
  if ([[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"InputLocalEcho"]] intValue]) {
    if ([obj isKindOfClass:[MWLineString class]]) {
      if ([[obj role] isEqual:MWPasswordRole]) {
        [self receive:[MWLineString lineStringWithString:Splats role:MWEchoRole] fromLinkFor:@"outward"];
      } else {
        [self receive:[MWLineString lineStringWithString:[obj string] role:MWEchoRole] fromLinkFor:@"outward"];
      }
    } else if ([obj isKindOfClass:[NSEvent class]]) {
      // ignore
    } else {
      [self receive:[MWLineString lineStringWithString:[obj description] role:MWEchoRole] fromLinkFor:@"outward"];
    }
  }
  
  [super inputClientReceive:obj];
}

// FIXME: make the pane part of the responder chain
- (IBAction)mwClearScrollback:(id)sender {
  [pane mwClearScrollback:sender];
}
- (IBAction)autoScrollLock:(id)sender {
  [pane autoScrollLock:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(mwClearScrollback:) || action == @selector(autoScrollLock:)) {
    return [pane validateUserInterfaceItem:item];
  } else {
    return [super validateUserInterfaceItem:item];
  }
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqualToString:@"outward"]) {
    if ([obj isKindOfClass:[MWLineString class]] && [[(MWLineString *)obj role] isEqualToString:MWStatusRole]) {
      [pane setStatusBar:0 toString:[(MWLineString *)obj string]];
      return YES;
  
    } else if ([obj isKindOfClass:[MWToken class]]) {
      NSString *name = [(MWToken *)obj name];
      NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:[@"TextOutputToken_" stringByAppendingString:name] value:@"nolocalizedstring" table:nil];
      if ([msg isEqualToString:@"nolocalizedstring"]) {
        msg = [NSString stringWithFormat:MWLocalizedStringHere(@"TextOutputTokenGeneric_%@"), name];
      }
      // let super handle the token if it wants, then pretend we received some text instead
      [super receive:obj fromLinkFor:link];
      obj = [MWLineString lineStringWithString:msg role:MWLocalRole];
    }
  }

  // special prompt-role handling
  if ([link isEqualToString:@"outward"] && [obj isKindOfClass:[MWLineString class]] && [[(MWLineString *)obj role] isEqualToString:MWPromptRole] && [[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"ReceivePromptShow"]] intValue]) {
    NSAttributedString *const previousPrompt = [[self extInputManager] inputPrompt];
  
    [super receive:obj fromLinkFor:link]; // this WILL succeed
    
    if (
      previousPrompt && [[(MWLineString *)obj attributedString] isEqualToAttributedString:previousPrompt]
      && [[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"ReceivePromptShowDifferent"]] intValue]
    ) {
      // if the prompt is the same and we're only showing different ones, then return anyway
      return YES;
    }
    
  } else {
    if ([super receive:obj fromLinkFor:link]) return YES;
  }
  

  if (![link isEqualToString:@"outward"]) return NO;
  
  if ([obj isKindOfClass:[MWLineString class]]) {
    MWLineString *const lsobj = obj;
    NSString *const role = [(MWLineString *)obj role];

    // use symbolic attributes so that local and echo strings can be live-colored
    if (role) {
      NSMutableAttributedString *replace;
      
      if ([role isEqualToString:MWEchoRole] && [[self extInputManager] inputPrompt] && ![[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"ReceivePromptShow"]] intValue]) {
        // echoed lines, instead of usual role-marking-addition procedure, get current prompt (if any) prepended - but not if prompts are also being displayed in output, because that turns out ugly.
        replace = [[[[self extInputManager] inputPrompt] mutableCopy] autorelease];
        [replace appendAttributedString:[lsobj attributedString]];
      } else {
        replace = [[[NSMutableAttributedString alloc] initWithString:MWLocalizedStringHere(([NSString stringWithFormat:@"(%@(@))", role])) attributes:[NSDictionary dictionary]] autorelease];
        [replace replaceCharactersInRange:[[replace string] rangeOfString:@"@"] withAttributedString:[lsobj attributedString]];
      }
      
      [replace addAttributes:[NSDictionary dictionaryWithObject:role forKey:MWRoleAttribute] range:NSMakeRange(0, [replace length])];

      [pane adjustAndDisplayAttributedString:replace completeLine:YES];
    } else {
    
      [pane adjustAndDisplayAttributedString:[lsobj attributedString] completeLine:YES];
    }
    
  } else if ([obj isKindOfClass:[NSAttributedString class]]) {
    [pane adjustAndDisplayAttributedString:obj completeLine:NO];

  } else {
    [pane adjustAndDisplayAttributedString:[[[NSAttributedString alloc] initWithString:[obj description] attributes:[NSDictionary dictionary]] autorelease] completeLine:YES];

  }
  return YES;
}

- (id)lpTextWindowSize:(NSString *)link {
  return [pane lpTextWindowSize:link];
}

// --- Text view delegate ---

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)linkObj atIndex:(unsigned)charIndex {
  if ([linkObj isKindOfClass:[NSURL class]]) {
    return NO;
  } else {
    [self send:linkObj toLinkFor:@"outward"];
    return YES;
  }
}

// --- Window management ------------------------------------------------------------

/*
- (void)windowDidBecomeKey:(NSNotification *)notif {
  [[self window] makeFirstResponder:outputDisplay];
}

- (void)windowDidBecomeMain:(NSNotification *)notif {
  [super windowDidBecomeMain:notif];
  [[self window] makeFirstResponder:outputDisplay];
}
*/

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize {
  // fixme: why does this method exist?
  return proposedFrameSize;
}

- (void)windowDidResize:(NSNotification *)notif {
  [self send:MWTokenWindowSizeChanged toLinkFor:@"outward"];
}

// --- GCC protocol checking workaround ---

- (id <MWConfigSupplier>)config { return [super config]; }
	
@end