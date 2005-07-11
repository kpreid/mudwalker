/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTelnetFilter.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWConfigPane.h>

#import "MWConnectionDocument.h"
#import "MWOutputWinController.h"

#import "MWANSIColorFilter.h"
#import "MWEncodingFilter.h"
#import "MWTelnetConfigPane.h"

#define TELOPTS
#define TELCMDS
#include <arpa/telnet.h>
#define TELOPT_CHARSET 42

#define ESC 27

// see RFC 1143
#define TQ_NO       0
#define TQ_YES      1
#define TQ_WANTNO   2
#define TQ_WANTYES  3
// NOTE that values for himq are boolean true/false.
#define TQ_EMPTY    NO
#define TQ_OPPOSITE YES

#define TELOPT_DEBUG 1

const static unsigned char IACvar = IAC;

enum MWTelnetScanStates {scNorm, scCR, scLF, scIAC, scWILL, scWONT, scDO, scDONT, scSubnegNumber, scSubnegData, scSubnegIAC};

@interface MWTelnetFilter (Private)

- (void)parseTelnet:(NSData *)inData;
- (void)tpFinishLine:(BOOL)isPrompt;

- (void)sendWindowSize;

@end

@implementation MWTelnetFilter

// --- Plugin principal class and URL handler ---

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  [registry registerClass:self forURLScheme:@"telnet"];
  if ([registry respondsToSelector:@selector(registerPreferencePane:forScope:)])
    [registry registerPreferencePane:[MWTelnetConfigPane class] forScope:MWConfigScopeAll];
}

+ (Class)schemeDefaultOutputWindowClass:(NSString *)scheme {
  return NSClassFromString(@"MWTextOutputWinController"); // FIXME: plugin should not have to know this class name
}
+ (BOOL)schemeUsesStandardTextFilters:(NSString *)scheme {
  return YES;
}

+ (void)scheme:(NSString *)scheme buildFiltersForInnermost:(id <MWLinkable>)inner config:(id <MWConfigSupplier>)configToUse {
  NSMutableArray *linkables = [NSMutableArray arrayWithObjects:
    [[[MWTCPConnection   alloc] init] autorelease],
    [[[MWTelnetFilter    alloc] init] autorelease],
    [[[MWEncodingFilter  alloc] init] autorelease],
    [[[MWANSIColorFilter alloc] init] autorelease],
    inner,
    nil
  ];
  if (NSClassFromString(@"MWMCProtocolFilter")) [linkables insertObject:[[[NSClassFromString(@"MWMCProtocolFilter") alloc] init] autorelease] atIndex:[linkables count] - 1]; // FIXME: generalization needed
  
  [MWLink buildFilterChain:linkables config:configToUse];
}


// --- Initialization ---

- (MWTelnetFilter *)init {
  if (!(self = (MWTelnetFilter *)[super init])) return nil;

  strcpy(cLineEnding, "\r\n");
  cPromptTimeout = 0.3;
  
  lineBuffer = [[NSMutableData allocWithZone:[self zone]] init];
  scanSubnegData = [[NSMutableData allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [lineBuffer release]; lineBuffer = nil;
  [scanSubnegData release]; scanSubnegData = nil;
  [unterminatedPromptTimer release]; unterminatedPromptTimer = nil;
  [beepSound release]; beepSound = nil;
  [super dealloc];
}

// --- Configuration ---

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  
  [(NSString *)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"LineEnding"]] getCString:cLineEnding maxLength:2];
  
  cPromptTimeout = [(id)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:MWConfigureTelnetPromptTimeout]] floatValue];
  
  cPromptBlankOnReceive = [(id)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"TelnetPromptBlankOnReceive"]] intValue];
  cPromptBlankOnSend = [(id)[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"TelnetPromptBlankOnSend"]] intValue];
}

// --- Linkage ---

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[NSData class]]) {
      [self parseTelnet:obj];
    } else if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenConnectionClosed]) {
        [lineBuffer setLength:0];
        [self send:obj toLinkFor:@"inward"];
      } else {
        [self send:obj toLinkFor:@"inward"];
      }
    } else {
      [self send:obj toLinkFor:@"inward"];
    }
    return YES;
  } else if ([link isEqual:@"inward"]) {
    NSMutableData *d = nil;
    
    if ([obj isKindOfClass:[MWLineData class]]) {
      d = [[[obj data] mutableCopy] autorelease];
      [d appendBytes:cLineEnding length:strlen(cLineEnding)];
      /* continue */
    } else if ([obj isKindOfClass:[NSData class]]) {
      d = obj;
      /* continue */
    } else if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenWindowSizeChanged]) {
        [self sendWindowSize];
        return YES;
      } else {
        [self send:obj toLinkFor:@"outward"];
        return YES;
      }
    } else {
      [self send:obj toLinkFor:@"outward"];
      return YES;
    }

    // implement blank-on-send
    if (hadNonemptyPrompt && cPromptBlankOnSend) {
      [self send:[[[MWLineData alloc] initWithData:[NSData data] role:MWPromptRole] autorelease] toLinkFor:@"inward"];
      hadNonemptyPrompt = NO;
    }
    
    {
      NSMutableData *escaped = [NSMutableData dataWithCapacity:[d length] + 4];
      const unsigned char *eScan = [d bytes];
      const unsigned char *eEnd = eScan + [d length];
      for (; eScan < eEnd; eScan++) {
        const unsigned char *seqStart = eScan;
        // scan to the next IAC
        while (eScan < eEnd && *eScan != IAC) eScan++;
        if (eScan > seqStart) {
          // found some normal chars
          [escaped appendBytes:seqStart length:eScan - seqStart];
        }
        if (eScan < eEnd) {
          // then there was an IAC
          const unsigned char iac2[2] = {IAC, IAC};
          [escaped appendBytes:iac2 length:2];
        }
      }
      d = escaped;
    }

    lastLineWasPrompt = NO;
    [self send:d toLinkFor:@"outward"];
    return YES;
  }
  return NO;
}

/* "Liking" a telnet option means it's OK for the server to use it. */
static __inline__ BOOL weLikeOption(MWTelnetFilter *self, unsigned const char opt) {
  switch (opt) {
    case TELOPT_BINARY:
    case TELOPT_SGA:
    case TELOPT_NAWS: // why would the _server_ use this?
    case TELOPT_CHARSET:
      return YES;
    case TELOPT_ECHO:
    case TELOPT_TM:
    case TELOPT_SNDLOC:
    case TELOPT_TTYPE:
    case TELOPT_EOR:
    case TELOPT_EXOPL:
    case 200: // fixme: some option that Achaea supports that I couldn't find any information about
      return NO;
    default:
      // FIXME: make this optionally an error
      [self linkableTraceMessage:[NSString stringWithFormat:@"Server wanted to enable option %i which I haven't heard of\n", opt]];
      return NO;
  }
}

/* Supporting a telnet option means it's OK for us to enable it. */
static __inline__ BOOL weSupportOption(MWTelnetFilter *self, unsigned const char opt) {
  switch (opt) {
    case TELOPT_BINARY: // we're effectively always in binary mode. shouldn't be a problem nowadays
    case TELOPT_SGA: // we never send a GA anyway
    case TELOPT_NAWS:
    case TELOPT_CHARSET:
      return YES;
    case TELOPT_ECHO:
    case TELOPT_TM:
    case TELOPT_SNDLOC:
    case TELOPT_TTYPE: // FIXME: implement terminal type negotiation
    case TELOPT_TSPEED:
    case TELOPT_LFLOW:
    case TELOPT_LINEMODE:
    case TELOPT_XDISPLOC:
      return NO;
    default:
      // FIXME: make this optionally an error
      [self linkableTraceMessage:[NSString stringWithFormat:@"Server wanted me to enable option %i %s which I haven't heard of\n", opt, TELOPT_OK(opt) ? TELOPT(opt) : ""]];
      return NO;
  }
}

- (void)sendWindowSize {
  if (us[TELOPT_NAWS]) {
    NSValue *value = [self probe:@selector(lpTextWindowSize:) ofLinkFor:@"inward"];
    NSSize winSize = value ? [value sizeValue] : NSMakeSize(0,0);
  
    NSMutableData *d = [NSMutableData dataWithLength:4];
    uint16_t *size = (uint16_t *)[d mutableBytes];
  
    size[0] = htons((uint16_t)winSize.width);
    size[1] = htons((uint16_t)winSize.height);
    //printf("sending NAWS %f,%f %s\n", winSize.width, winSize.height, [[d description] cString]);
    [self sendSubnegotiation:TELOPT_NAWS data:d];
  }
}

- (void)sendSubnegotiation:(unsigned char)opt data:(NSData *)data {
  NSMutableData *msg = [NSMutableData data];
  unsigned char begin[3] = {IAC, SB, opt};
  unsigned char end[2] = {IAC, SE};
  [msg appendBytes:begin length:3];
  [msg appendData:data];
  [msg appendBytes:end length:2];
  [self send:[[msg copy] autorelease] toLinkFor:@"outward"];
}

- (void)enabledOurOption:(unsigned char)opt {
  switch (opt) {
    case TELOPT_NAWS:
      [self sendWindowSize];
      break;
    default:
      break;
  }
}
- (void)disabledOurOption:(unsigned char)opt {
}

- (void)processSubnegotiationOption:(unsigned char)opt data:(NSData *)data {
  const unsigned char *bytes = [data bytes],
    *scan = bytes,
    *end = bytes + [data length];
  switch (opt) {
    case TELOPT_CHARSET: {
      // See RFC 2066
      unsigned char sep;
      switch (bytes[*(scan++)]) {
        case 01:{// REQUEST
          NSStringEncoding myEncoding = [[self probe:@selector(lpCurrentStringEncoding:) ofLinkFor:@"inward"] intValue]; // FIXME: access config instead
          NSMutableSet *theirEncodingNames = [NSMutableSet set];
          const unsigned char *scanend;
          BOOL ttable = !memcmp(scan, "[TTABLE]", 8);
          if (ttable) scan += 9;
          sep = *(scan++);
          for (scanend = scan; scanend < end; scanend++) {
            if (*scanend == sep) {
              [theirEncodingNames addObject:[NSString stringWithCString:scan length:scanend - scan]];
              scan = scanend + 1;
            }
          }
          [theirEncodingNames addObject:[NSString stringWithCString:scan length:scanend - scan]];
          // Done parsing the subnegotiation, now we act on it
          
          {
            NSEnumerator *tenE = [theirEncodingNames objectEnumerator];
            NSString *ten;
            BOOL found = NO;
            while ((ten = [tenE nextObject])) {
              if ((NSStringEncoding)CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)ten)) == myEncoding) {
                NSMutableData *d = [NSMutableData data];
                uint8_t accepted = 2;
                [d appendBytes:&accepted length:1];
                [d appendData:[ten dataUsingEncoding:NSASCIIStringEncoding] ];
                [self sendSubnegotiation:TELOPT_CHARSET data:d];
                found = YES;
                break;
              }
            }
            // FIXME: be willing to change encoding config based on server report
            
            if (!found) {
              uint8_t rejected = 3;
              [self sendSubnegotiation:TELOPT_CHARSET data:[NSData dataWithBytes:&rejected length:1]];
            }
          }
          
          break;
        }
        case 02: // ACCEPTED
        case 03: // REJECTED
        case 04: // TTABLE-IS
        case 05: // TTABLE-REJECTED
        case 06: // TTABLE-ACK
        case 07: // TTABLE-NAK
          // we should never receive any of these since we never REQUEST
          break;
      }
      break;
    }
    default:
      break;
  }
}

#define tpAppend(b) do { unsigned char c = (b); [lineBuffer appendBytes:&c length:1]; } while(0)
#define tpComplain ;
// FIXME: it would be better for tpSendOption to queue till the end of inward parsing, in case sending outward causes receiving
#define tpSendOption(mode, opt) do { \
  char resp[3] = {IAC, mode, opt}; \
  if (TELOPT_DEBUG) [self linkableTraceMessage:[NSString stringWithFormat:@"Sending %s %s\n", TELCMD(mode), TELOPT_OK(opt) ? TELOPT(opt) : ""]]; \
  [self send:[NSData dataWithBytes:resp length:3] toLinkFor:@"outward"]; \
} while (0)
- (void)parseTelnet:(NSData *)inData {
  const unsigned char *inScan = [inData bytes];
  const unsigned char *inEnd = inScan + [inData length];
  int beeps = 0;

  if (unterminatedPromptTimer) {
    //NSLog(@"cancelling prompt timer");
    [unterminatedPromptTimer invalidate];
    [unterminatedPromptTimer release];
    unterminatedPromptTimer = nil;
  }
  
  for (/*inScan = [inData bytes]*/; inScan < inEnd; inScan++) {
    switch (scanState) {
    
      case scNorm:
        switch (*inScan) {
          case IAC: scanState = scIAC; break;
          case '\r': scanState = scCR; [self tpFinishLine:NO]; break;
          case '\n': scanState = scLF; [self tpFinishLine:NO]; break;
          case '\a': beeps++; break;
          default: [lineBuffer appendBytes:inScan length:1]; break;
        }
        break;
        
      case scCR: case scLF:
        // if char after CR/LF is the other one, ignore it; otherwise display it
        if (*inScan != (scanState == scCR ? '\n' : '\r')) inScan--;
        scanState = scNorm;
        break;
        
      case scIAC:
        scanState = scNorm; // most of the time, we switch back to normal scan, but sometimes not, so we set this now so it can be changed in the switch
        switch (*inScan) {
          case IAC:  [lineBuffer appendBytes:&IACvar length:1]; break;
          case DONT: scanState = scDONT; break;
          case DO:   scanState = scDO; break;
          case WONT: scanState = scWONT; break;
          case WILL: scanState = scWILL; break;
          case SB:   scanState = scSubnegNumber; break;
          case GA:   [self tpFinishLine:YES]; break;
          case EL:   tpComplain; break;
          case EC:   tpComplain; break;
          case AYT:  tpComplain; break;
          case AO:   tpComplain; break;
          case IP:   tpComplain; break;
          case BREAK:tpComplain; break;
          case DM:   break;
          case NOP:  break;
          case SE:   tpComplain; break;
          case EOR:  [self tpFinishLine:YES]; break;
          case ABORT:tpComplain; break;
          case SUSP: tpComplain; break;
          default:   tpComplain; break;
        }
        break;
       
      // Handling of WILL/WONT/DO/DONT is as described in RFC 1143. See that document for explanation of the algorithm.
      // This is slightly less than idiomatic C, as I wanted to match the RFC's description as closely as reasonable
      // Right now, we never request an option. If we ever need to, see the RFC for how to do it properly.
        
      case scWILL: {
        unsigned const char thisOption = *inScan;
        if (TELOPT_DEBUG) [self linkableTraceMessage:[NSString stringWithFormat:@"Got WILL %i %s\n", thisOption, TELOPT_OK(thisOption) ? TELOPT(thisOption) : ""]];

        switch (him[thisOption]) {
          default:
            [self linkableErrorMessage:@"Funny state in option negotiation\n"];
          case TQ_NO:
            if (weLikeOption(self, thisOption)) {
              him[thisOption] = TQ_YES;
              tpSendOption(DO, thisOption);
            } else {
              tpSendOption(DONT, thisOption);
            }
            break;
          case TQ_YES:
            /* ignore */
            break;
          case TQ_WANTNO:
            [self linkableErrorMessage:@"Server responded WILL to my DONT.\n"];
            if (himq[thisOption] == TQ_EMPTY) him[thisOption] = TQ_NO;
                                         else him[thisOption] = TQ_YES;
            break;
          case TQ_WANTYES:
            if (himq[thisOption] == TQ_EMPTY) him[thisOption] = TQ_YES;
            else {
              him[thisOption] = TQ_WANTNO;
              himq[thisOption] = TQ_EMPTY;
              tpSendOption(DONT, thisOption);
            }
            break;
        }
              
        scanState = scNorm;
        break;
      }
      
      case scWONT: {
        unsigned char thisOption = *inScan;
        if (TELOPT_DEBUG) [self linkableTraceMessage:[NSString stringWithFormat:@"Got WONT %i %s\n", thisOption, TELOPT_OK(thisOption) ? TELOPT(thisOption) : ""]];

        switch (him[thisOption]) {
          default:
            [self linkableErrorMessage:@"Funny state in option negotiation\n"];
          case TQ_NO:
            /* ignore */
            break;
          case TQ_YES:
            him[thisOption] = TQ_NO;
            tpSendOption(DONT, thisOption);
            break;
          case TQ_WANTNO:
            if (himq[thisOption] == TQ_EMPTY) him[thisOption] = TQ_NO;
            else {
              him[thisOption] = TQ_WANTYES;
              himq[thisOption] = TQ_EMPTY;
              tpSendOption(DO, thisOption);
            }
            break;
          case TQ_WANTYES:
            if (himq[thisOption] == TQ_EMPTY) him[thisOption] = TQ_NO;
            else {
              him[thisOption] = TQ_NO;
              himq[thisOption] = TQ_EMPTY;
            }
            break;
        }

        scanState = scNorm;
        break;
      }
      
      case scDO: {
        unsigned const char thisOption = *inScan;
        if (TELOPT_DEBUG) [self linkableTraceMessage:[NSString stringWithFormat:@"Got DO %i %s\n", thisOption, TELOPT_OK(thisOption) ? TELOPT(thisOption) : ""]];

        switch (us[thisOption]) {
          default:
            [self linkableErrorMessage:@"Funny state in option negotiation\n"];
          case TQ_NO:
            if (weSupportOption(self, thisOption)) {
              us[thisOption] = TQ_YES;
              tpSendOption(WILL, thisOption);
              [self enabledOurOption:thisOption];
            } else {
              tpSendOption(WONT, thisOption);
            }
            break;
          case TQ_YES:
            /* ignore */
            break;
          case TQ_WANTNO:
            [self linkableErrorMessage:@"Server responded DO to my WONT.\n"];
            if (usq[thisOption] == TQ_EMPTY) us[thisOption] = TQ_NO;
                                        else us[thisOption] = TQ_YES;
            break;
          case TQ_WANTYES:
            if (usq[thisOption] == TQ_EMPTY) us[thisOption] = TQ_YES;
            else {
              us[thisOption] = TQ_WANTNO;
              usq[thisOption] = TQ_EMPTY;
              tpSendOption(WONT, thisOption);
            }
            break;
        }

        scanState = scNorm;
        break;
      }
      
      case scDONT: {
        unsigned char thisOption = *inScan;
        if (TELOPT_DEBUG) [self linkableTraceMessage:[NSString stringWithFormat:@"Got DONT %i %s\n", thisOption, TELOPT_OK(thisOption) ? TELOPT(thisOption) : ""]];

        switch (us[thisOption]) {
          default:
            [self linkableErrorMessage:@"Funny state in option negotiation\n"];
          case TQ_NO:
            /* ignore */
            break;
          case TQ_YES:
            us[thisOption] = TQ_NO;
            tpSendOption(WONT, thisOption);
            [self disabledOurOption:thisOption];
            break;
          case TQ_WANTNO:
            if (usq[thisOption] == TQ_EMPTY) us[thisOption] = TQ_NO;
            else {
              us[thisOption] = TQ_WANTYES;
              usq[thisOption] = TQ_EMPTY;
              tpSendOption(WILL, thisOption);
            }
            break;
          case TQ_WANTYES:
            if (usq[thisOption] == TQ_EMPTY) us[thisOption] = TQ_NO;
            else {
              us[thisOption] = TQ_NO;
              usq[thisOption] = TQ_EMPTY;
            }
            break;
        }

        scanState = scNorm;
        break;
      }
      
      case scSubnegNumber:
        scanSubnegOption = *inScan;
        scanState = scSubnegData;
        [scanSubnegData setLength:0];
        break;
      case scSubnegData:
        if (*inScan == IAC) scanState = scSubnegIAC;
        else [scanSubnegData appendBytes:inScan length:1];
        break;
      case scSubnegIAC:
        if (*inScan == IAC) [scanSubnegData appendBytes:&IACvar length:1];
        else if (*inScan == SE) {
           [self processSubnegotiationOption:scanSubnegOption data:scanSubnegData];
          scanState = scNorm;
        } else ;
        // ignoring other IAC+xx seqs - should we be doing something else?
        break;
      default:
        [self linkableErrorMessage:[NSString stringWithFormat:@"bad state %i in telnet state machine\n", scanState]];
        scanState = scNorm;
        break;
        
    } // switch(scanState)
  } // for(inScan < inEnd...)
  
  if (beeps) {
    // fixme: is this an OK way to get the system beep sound?
    if (!beepSound) beepSound = [[NSClassFromString(@"NSSound") alloc] initWithContentsOfFile:[[NSUserDefaults standardUserDefaults]         stringForKey:@"com.apple.sound.beep.sound"] byReference:NO];
    while (beeps--) {
      [self send:beepSound toLinkFor:@"inward"];
    }
  }
  
  // here, start a timer to call tpFinishLine with isPrompt, IF the line buffer contains characters (which implies that they are not part of a line).
  if ([lineBuffer length] && cPromptTimeout) {
    //NSLog(@"creating prompt timer, buffer is '%@'", [[[NSString alloc] initWithData:lineBuffer encoding:NSASCIIStringEncoding] autorelease]);
    unterminatedPromptTimer = [[NSTimer
      scheduledTimerWithTimeInterval:cPromptTimeout
      target:self
      selector:@selector(timedFinishPrompt:)
      userInfo:nil
      repeats:NO
    ] retain];
  }
}

- (void)timedFinishPrompt:(NSTimer *)timer {
  //NSLog(@"prompt timer fired, buffer is '%@'", [[[NSString alloc] initWithData:lineBuffer encoding:NSASCIIStringEncoding] autorelease]);
  [self tpFinishLine:YES];
}

- (void)tpFinishLine:(BOOL)isPrompt {
  if (isPrompt || [lineBuffer length] || !lastLineWasPrompt) {
  
    if (hadNonemptyPrompt && !isPrompt && cPromptBlankOnReceive) {
      [self send:[[[MWLineData alloc] initWithData:[NSData data] role:MWPromptRole] autorelease] toLinkFor:@"inward"];
      hadNonemptyPrompt = NO;
    } else if (isPrompt && [lineBuffer length]) {
      hadNonemptyPrompt = YES;
    }
  
    // This may be called many times due to large amounts of text being received in one chunk...so we create an autorelease pool to avoid having large amounts of temporary memory.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NS_DURING
      [self send:[[[MWLineData alloc] initWithData:[[lineBuffer copy] autorelease] role:(isPrompt ? MWPromptRole : nil)] autorelease] toLinkFor:@"inward"];
    NS_HANDLER
      [pool release];
      [localException raise];
    NS_ENDHANDLER
    [pool release];
  }
  lastLineWasPrompt = isPrompt;
  [lineBuffer setLength:0];
}

@end
