/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import <MudWalker/MWConcreteLinkable.h>
#import <MudWalker/MWPlugin.h>

@class NSSound;

@interface MWTelnetFilter : MWConcreteLinkable <MWPlugin> {
  char cLineEnding[3];
  float cPromptTimeout;
  BOOL cPromptBlankOnReceive;
  BOOL cPromptBlankOnSend;
  
  NSMutableData *lineBuffer;
  
  int scanState;
  BOOL lastLineWasPrompt; // if lastLineWasPrompt and we receive a blank line before we send anything, don't pass it inward
  BOOL hadNonemptyPrompt; // was the last MWPromptRole we sent in nonblank
  unsigned char scanSubnegOption;
  NSMutableData *scanSubnegData;
  
  NSTimer *unterminatedPromptTimer;
  
  // state info for telnet negotiation using algorithm described in RFC 1143; 'us' and 'him' indicate the state of options on each side of the connection
  // if we use extended telnet options we'll need larger buffers here
  unsigned char us[256], usq[256], him[256], himq[256];
  
  NSSound *beepSound;
}

- (void)sendSubnegotiation:(unsigned char)opt data:(NSData *)data;

@end
