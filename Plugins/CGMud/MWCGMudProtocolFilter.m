/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudProtocolFilter.h"

#import <MudWalker/MudWalker.h>

// fixme: should not have dependencies on these
#import "MWGUIOutputWinController.h"
#import "MWOutputWinController.h"
#import "MWConnectionDocument.h"
#import "MWRemoteTextHolder.h"

#import "MWCGMudCommon.h"
#import "MWCGMudMessage.h"
#import "MWCGMudGUIController.h"
#import "MWCGMudGraphicsView.h"
#import "MWCGMudIconsView.h"

#include <netinet/in.h>

static char requestTypeNames[rt_illegal + 1][32] = {
  "rt_first",
  "rt_killClient",
  "rt_nukeClient",
  "rt_runClient",
  "rt_message",
  "rt_enterWizardMode",
  "rt_leaveWizardMode",
  "rt_setContinue",
  "rt_changePassword",
  "rt_setPrompt",
  "rt_deleteProc",
  "rt_effects",
  "rt_editString",
  "rt_editProc",
  "rt_getString",
  "rt_flushSymbol",
  "rt_defineEffect",
  "rt_queryFile",
  "rt_shutDown",
  "rt_flush",
  "rt_syncShutDown",
  "rt_beginClient",
  "rt_endClient",
  "rt_askPlayer",
  "rt_creationCheck",
  "rt_createPlayer",
  "rt_loginPlayer",
  "rt_lookup",
  "rt_findName",
  "rt_readProc",
  "rt_writeProcNew",
  "rt_runProc",
  "rt_log",
  "rt_inputLine",
  "rt_setSync",
  "rt_rawKey",
  "rt_regionSelect",
  "rt_buttonHit",
  "rt_flushEffect",
  "rt_textResize",
  "rt_incRef",
  "rt_decRef",
  "rt_symbolEnter",
  "rt_symbolDelete",
  "rt_useTable",
  "rt_unuseTable",
  "rt_describeBuiltin",
  "rt_describe",
  "rt_graphicsFlip",
  "rt_voiceFlip",
  "rt_soundFlip",
  "rt_musicFlip",
  "rt_doEditProc",
  "rt_editStringDone",
  "rt_replaceProc",
  "rt_editProcDone",
  "rt_getStringDone",
  "rt_effectDone",
  "rt_queryFileDone",
  "rt_createContainer",
  "rt_createComponent",
  "rt_makeFrame",
  "rt_illegal"
};

static NSBundle *myBundle;

static void cgmud_crypt(CHAR_T *pp, BOOL_T decrypt, ULONG_T sessionKey);

enum { MWCGUnconnected, MWCGReady, MWCGbeginClientWait, MWCGUserNameRequest, MWCGUserPasswordRequest, MWCGrunClientWait };

@interface MWCGMudProtocolFilter (Private)

- (void)sendBeginClient;
- (void)processOutwardString:(NSString *)str;
- (void)processUserEvent:(NSEvent *)event;
- (void)closeConnection;
- (void)closedConnection;

- (void)processServerMessageType:(RequestType_t)type key:(uint32_t)key  flag:(BOOL)flag uint:(uint16_t)uint tail:(NSData *)tail;

- (void)packageAndSendMessageType:(uint8_t)type key:(uint32_t)key flag:(BOOL)flag uint:(uint16_t)uint tail:(NSData *)tail;
- (void)sendMessageOutward:(MWCGMudMessage *)msg;

@end

@implementation MWCGMudProtocolFilter

// --- Plugin principal class and URL handler ---

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  [registry registerClass:self forURLScheme:@"cgmud"];
}

+ (Class)schemeDefaultOutputWindowClass:(NSString *)scheme {
  //return NSClassFromString(@"MWGUIOutputWinController");
  return NSClassFromString(@"MWTextOutputWinController");
}
+ (BOOL)schemeUsesStandardTextFilters:(NSString *)scheme {
  return NO;
}

+ (void)scheme:(NSString *)scheme buildFiltersForInnermost:(id <MWLinkable>)inner config:(id <MWConfigSupplier>)configToUse {
  [MWLink buildFilterChain:[NSArray arrayWithObjects:
    [[[MWTCPConnection       alloc] init] autorelease],
    [[[MWCGMudProtocolFilter alloc] init] autorelease],
    inner,
    nil
  ] config:configToUse];
}

// ---  ---

+ (void)initialize {
  [super initialize];
  myBundle = [NSBundle bundleForClass:self];
  [self initializeEffects];
}

- (MWCGMudProtocolFilter *)init {
  if (!(self = (MWCGMudProtocolFilter *)[super init])) return nil;

  state = MWCGUnconnected;
  messageBuffer = [[NSMutableData allocWithZone:[self zone]] init];
  
  [self initializeEffectsState];
  
  return self;
}

- (void)dealloc {
  [cFont autorelease]; cFont = nil;
  [messageBuffer autorelease]; messageBuffer = nil;
  [effectsCache autorelease]; effectsCache = nil;
  [pens autorelease]; pens = nil;
  [cursorData autorelease]; cursorData = nil;
  [textAttributes autorelease]; textAttributes = nil;
  [activeImage autorelease]; activeImage = nil;
  [tileCache autorelease]; tileCache = nil;
  [iconCache autorelease]; iconCache = nil;
  [activeEffects autorelease]; activeEffects = nil;
  [soundRepeats autorelease]; soundRepeats = nil;
  [super dealloc];
}

// --- Linkage ---

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", @"inward", @"getString", @"newGUI", nil]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
  
    if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenConnectionOpened]) {
        [self sendBeginClient];
        state = MWCGbeginClientWait;
        return YES;
      } else if ([obj isEqual:MWTokenConnectionClosed]) {
        [self closedConnection];
        if (state == MWCGReady) {
          [self unlink:@"inward"];
        } else {
          [self send:MWTokenPingSend toLinkFor:@"outward"];
        }
        return YES;
      }
      return NO;
    } else if ([obj isKindOfClass:[NSData class]]) {
      unsigned int mbLen;
      [messageBuffer appendData:obj];
      while (mbLen = [messageBuffer length], (mbLen >= sizeof(uint16_t) && mbLen >= ntohs(*((uint16_t *)[messageBuffer bytes]) + REQ_LEN))) {
        // the buffer contains a complete message, time to parse it
        MWCGMudMessage *msg = [MWCGMudMessage messageWithData:messageBuffer];
        
        [messageBuffer setData:[messageBuffer subdataWithRange:MWMakeABRange([msg messageLength], [messageBuffer length])]];
        
        [self processServerMessageType:[msg type] key:[msg key] flag:[msg flag] uint:[msg uint] tail:[msg tail]];
      }
      return YES;
    } else {
      [self send:obj toLinkFor:@"inward"];
      return YES;
    }
  } else if ([link isEqual:@"inward"]) {
    if ([obj isKindOfClass:[MWToken class]]) {
      if ([obj isEqual:MWTokenLogoutConnection]) {
        [self closeConnection];
      } else {
        [self send:obj toLinkFor:@"outward"];
      }
      return YES;
    } else if ([obj isKindOfClass:[NSString class]]) {
      [self linkableErrorMessage:@"Warning: MWCGMudProtocolFilter received NSString from inward, not currently correctly supported."];
      [self processOutwardString:obj];
      return YES;
    } else if ([obj isKindOfClass:[MWLineString class]]) {
      [self processOutwardString:[obj string]];
      return YES;
    } else if ([obj isKindOfClass:[NSEvent class]]) {
      [self processUserEvent:obj];
      return YES;
    } else if ([obj isKindOfClass:[MWCGMudMessage class]]) {
      [self sendMessageOutward:obj];
      return YES;
    } else {
      return NO;
    }
    
  } else if ([link isEqual:@"getString"]) {
    if ([obj isKindOfClass:[NSString class]]) {
      NSMutableData *tail;
      if (!inGetString) return YES; /* uncertain what appropriate return value is */
      inGetString = NO;
      tail = [NSMutableData data];
      [tail appendData:[obj dataUsingEncoding:CGMUD_ENCODING allowLossyConversion:YES]];
      [tail appendBytes:"" length:1];
      
      [self packageAndSendMessageType:rt_getStringDone
            key:0 flag:1 uint:0 tail:tail];
            
      [self unlink:@"getString"];
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

- (void)unregisterLinkFor:(NSString *)linkName {
  [super unregisterLinkFor:linkName];
  if ([linkName isEqual:@"outward"]) {
    [self closedConnection];
  } else if ([linkName isEqual:@"getString"]) {
    if (inGetString) {
      [self packageAndSendMessageType:rt_getStringDone
          key:0 flag:0 uint:0 tail:[NSData dataWithBytes:"" length:1]];
      inGetString = NO;
    }
  }
}


- (void)closeConnection {
  [self packageAndSendMessageType:rt_endClient key:0 flag:0 uint:0 tail:nil];
}

- (void)closedConnection {
  if (state != MWCGUnconnected) {
    [messageBuffer setLength:0];
    [self resetEffectsState];
    inGetString = 0;
    state = MWCGUnconnected;
    [self localMessage:NSLocalizedString(@"SDisconnected",nil)];
  }
}

- (void)unlinkAll {
  // send an endClient if we happen to be connected
  [self closeConnection];
  [super unlinkAll];
}

- (NSValue *)lpEffectsInfo:(NSString *)link { return [NSValue valueWithPointer:&effectsInfo]; }
- (NSDictionary *)lpTextAttributes:(NSString *)link { return textAttributes; }

// --- Protocol utilities ---

// hmm, i will probably eventually need a MWCGMudMessage to pass around for special functions

// see proto.doc for message format

- (void)enterUserNameRequestState {
  state = MWCGUserNameRequest;
  [self send:[MWLineString lineStringWithString:MWLocalizedStringHere(@"CGCharacterNamePrompt") role:MWPromptRole] toLinkFor:@"inward"];
}

- (void)sendBeginClient {
  int i;
  NSScreen *mainScreen = [NSScreen mainScreen];
  NSRect visibleFrame = [mainScreen visibleFrame];
  NSFont *font = [textAttributes objectForKey:NSFontAttributeName];
  
  // magic value to confirm protocol
  for (i = 0; i < BEGIN_KEY_LEN; i++) effectsInfo.ei_key[i] = i * i;

  strcpy(effectsInfo.ei_graphicsType, "Cocoa/MudWalker"); // fixme: put our version in this string
  effectsInfo.ei_graphicsRows = visibleFrame.size.height;
  effectsInfo.ei_graphicsCols = visibleFrame.size.width;
  effectsInfo.ei_graphicsColours = CGMUD_PEN_COUNT;
  effectsInfo.ei_fontAscent = [font ascender];
  effectsInfo.ei_fontDescent = [font descender];
  effectsInfo.ei_fontLeading = 0;
  effectsInfo.ei_fontHeight = [font defaultLineHeightForFont];
  effectsInfo.ei_fontWidth = ceil([font advancementForGlyph:[font glyphWithName:@"e"]].width);
  effectsInfo.ei_textWidth = 80; // fixme: width and height should be determined from text output window size (?)
  effectsInfo.ei_textHeight = 24;
  effectsInfo.ei_version = 0;
  effectsInfo.ei_canEdit = !!NSClassFromString(@"MWRemoteTextHolder");
  effectsInfo.ei_canGetString = YES;
  effectsInfo.ei_canQueryFile = NO;
  effectsInfo.ei_canWizard = YES;
  effectsInfo.ei_graphicsOn = YES;
  effectsInfo.ei_graphicsPalette = YES;
  effectsInfo.ei_voiceOn = YES;
  effectsInfo.ei_soundOn = YES;
  effectsInfo.ei_musicOn = YES;
  
  if (!effectsInfo.ei_canEdit) [self linkableErrorMessage:@"MWRemoteTextHolder not present. Local editing will not be available.\n"];
  
  [self packageAndSendMessageType:rt_beginClient key:0 flag:0 uint:0 tail:[NSData dataWithBytes:&effectsInfo length:sizeof(effectsInfo)]];
}

- (void)prepareNewGUI {
  if (![[(id)self probe:@selector(lpHandlesGUI:) ofLinkFor:@"newGUI"] boolValue]) {
    id w;
    MWCGMudGUIController *cc;
  
    MWConnectionDocument *doc = [(id)self probe:@selector(lpDocument:) ofLinkFor:@"inward"];
  
    if (!doc) {
      [self linkableErrorMessage:@"could not find document in order to create output window\n"];
      return;
    }
  
    w = [doc outputWindowOfClass:NSClassFromString(@"MWGUIOutputWinController") group:@"cgmudmain" reuse:YES connect:NO display:YES];
    cc = [[[MWCGMudGUIController alloc] init] autorelease];
    [w link:@"controller" to:@"outward" of:cc];
    [w link:@"outward" to:@"newGUI" of:self];

    {
      MWLinearLayoutView *outer = [[[MWLinearLayoutView alloc] initWithFrame:NSMakeRect(0,0,0,0)] autorelease];
      [outer setVertical:YES];
      [outer setPadding:LAYOUT_VIEW_PADDING];
      [cc addView:outer withID:[NSNumber numberWithUnsignedInt:0] inID:@"MWRoot"];
    }
  }
}

#define STATE_ONLY(s) if (state != (s)) { [self linkableErrorMessage:[NSString stringWithFormat:@"Unexpected message of type %s in state %i", requestTypeNames[type], state]]; break; }
#define WRONG_MSG_DIRECTION [self linkableErrorMessage:[NSString stringWithFormat:@"Got message of type %s that the server shouldn't be sending", requestTypeNames[type]]]
- (void)processServerMessageType:(RequestType_t)type key:(uint32_t)key  flag:(BOOL)flag uint:(uint16_t)uint tail:(NSData *)tail {
  if (type > rt_illegal) type = rt_illegal;
  [self linkableTraceMessage:[NSString stringWithFormat:@"<-- %-18s key=%lu flag=%u uint=%u %u\n", requestTypeNames[type], key, flag, uint, [tail length]]];
    
  switch (type) {
  
    case rt_first:
      [self linkableErrorMessage:@"received rt_first??\n"];
      break;

    case rt_killClient:
      [self closeConnection];
      break;
      
    case rt_nukeClient:
      [self unlink:@"outward"];
      break;
    
    case rt_runClient:
      state = MWCGReady;
      break;
      
    case rt_message: {
      [self send:[MWCGMudMessage messageWithType:type key:key flag:flag uint:uint tail:tail] toLinkFor:@"inward"];
      break;
    }
    
    case rt_enterWizardMode: {
      inWizardMode = YES;
      [self send:[MWLineString lineStringWithString:MWLocalizedStringHere(@"CGWizardModePrompt") role:MWPromptRole] toLinkFor:@"inward"];
      break;
    }
    
    case rt_leaveWizardMode: {
      inWizardMode = NO;
      break;
    }
    
    /*case rt_setContinue:*/ 
    /*case rt_changePassword:*/ 
    
    case rt_setPrompt:
      [self send:[MWLineString lineStringWithString:[[[NSString alloc] initWithData:[tail subdataWithRange:NSMakeRange(0, [tail length] - 1)] encoding:CGMUD_ENCODING] autorelease] role:MWPromptRole] toLinkFor:@"inward"];
      break;
      
    /*case rt_deleteProc:*/ 

    case rt_effects:
      [self linkableTraceMessage:[NSString stringWithFormat:@"%i: ", key]];
      [self processEffects:tail component:key];
      [self linkableTraceMessage:[NSString stringWithFormat:@"\n"]];
      break;
      
    case rt_editString: {
      MWRemoteTextHolder *th = [[NSClassFromString(@"MWRemoteTextHolder") alloc] init];
      {
        unsigned promptEnd, tLen = [tail length];
        const char *tBytes = [tail bytes];
        for (promptEnd = 0; promptEnd < tLen && tBytes[promptEnd] != 0; promptEnd++);
        [th setTitle:[[[NSString alloc] initWithData:[tail subdataWithRange:NSMakeRange(0, promptEnd)] encoding:CGMUD_ENCODING] autorelease]];
        [th setString:[[[NSString alloc] initWithData:[tail subdataWithRange:MWMakeABRange(promptEnd + 1, [tail length])] encoding:CGMUD_ENCODING] autorelease]];
      }
      [[th metadata] setDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"editString", @"type", nil]];
      [th setDelegate:self];
      [th openView];
      break;
    }
    
    /*case rt_editProc*/
    
    case rt_getString: {
      MWConnectionDocument *doc = [(id)self probe:@selector(lpDocument:) ofLinkFor:@"inward"];
      id w;
      NSString *prompt, *message;
      unsigned int split;
      
      if (inGetString) {
        [self linkableErrorMessage:@"got rt_getString while already in getString mode"];
        return;
      }
      if (!doc) {
        [self linkableErrorMessage:@"could not find document in order to create output window"];
        [self packageAndSendMessageType:rt_getStringDone key:0 flag:0 uint:0 tail:nil];
        break;
      }
      w = [doc outputWindowOfClass:NSClassFromString(@"MWOneLineRequestOutputWinController") group:@"cgmudaux" reuse:YES connect:NO display:YES];
      
      split = strlen((char *)[tail bytes]);
      prompt = [[[NSString alloc] initWithData:[tail subdataWithRange:NSMakeRange(0, split)] encoding:CGMUD_ENCODING] autorelease];
      message = [[[NSString alloc] initWithData:[tail subdataWithRange:MWMakeABRange(split + 1, [tail length] - 1)] encoding:CGMUD_ENCODING] autorelease];
      
      [w link:@"outward" to:@"getString" of:self];

      [self send:[MWLineString lineStringWithString:prompt role:MWPromptRole] toLinkFor:@"getString"];
      [self send:message toLinkFor:@"getString"];
      
      inGetString = YES;
      
      [w showWindow:self];
      
      break;
    }
    
    /* case rt_flushSymbol: */
    
    case rt_defineEffect: {
      uint8_t refcount = *((char *)[tail bytes]); 
      [effectsCache setObject:[tail subdataWithRange:MWMakeABRange(1 + refcount * 4, [tail length])] forKey:[NSNumber numberWithUnsignedLong:key]];
      break;
    }
      
    /* case rt_queryFile: */
    
    case rt_shutDown:
    case rt_flush:
    case rt_syncShutDown:
      WRONG_MSG_DIRECTION; break;
    
    case rt_beginClient:
      STATE_ONLY(MWCGbeginClientWait)
      switch (uint) {
        case 0: [self localIzedMessage:@"CGSinglePlayerInUse"]; [self closeConnection]; break;
        case 1: state = MWCGReady;
        case 2: {
          NSString *accountKey = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"SelectedAccount"]];
          if (accountKey) {
            NSMutableData *tail = [NSMutableData data];
            [tail appendData:[[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", key, @"username", nil]] dataUsingEncoding:CGMUD_ENCODING allowLossyConversion:YES]];
            [tail appendBytes:"\0" length:1];
            [self packageAndSendMessageType:rt_askPlayer key:1 flag:0 uint:0 tail:tail];
          }
          [self enterUserNameRequestState];
          break;
        }
        default: break;
      }
      sessionKey = key;
      break;
      
    case rt_endClient:
      // this is an acknowledgement of a clean close
      [self unlink:@"outward"];
      break;
      
    case rt_askPlayer:
      STATE_ONLY(MWCGUserNameRequest)
      switch (key) {
        case 0: [self localIzedMessage:@"CGCharCreationDenied"]; break;
        case 1: [self localIzedMessage:@"CGConfirmCharCreation"]; break;
        case 2: [self localIzedMessage:@"CGCharCreationNeedsPW"]; break;
        case 3: [self localIzedMessage:@"CGCharNot"]; break;
        case 4: [self localIzedMessage:@"CGCharRemoteAdminDenied"]; break;
        case 5: {
          NSString *accountKey = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"SelectedAccount"]];
          if (accountKey) {
            NSMutableData *tail = [NSMutableData data];
            [tail appendData:[[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"Accounts", key, @"password", nil]] dataUsingEncoding:CGMUD_ENCODING allowLossyConversion:YES]];
            [tail setLength:PASSWORD_LEN];
            cgmud_crypt([tail mutableBytes], 0, sessionKey);
            [self packageAndSendMessageType:rt_loginPlayer key:0 flag:0 uint:0 tail:tail];
          }
          [self send:[MWLineString lineStringWithString:MWLocalizedStringHere(@"CGCharacterPasswordPrompt") role:MWPromptRole] toLinkFor:@"inward"];
          state = MWCGUserPasswordRequest;
          break;
        }
        case 6: [self localIzedMessage:@"CGCharAlreadyLoggedIn"]; break;
        default: [self linkableErrorMessage:[NSString stringWithFormat:@"Received funny key %lu in rt_askPlayer", key]];
      }
      break;
      
    /* case rt_creationCheck: */
    /* case rt_createPlayer: */
      
    case rt_loginPlayer:
      STATE_ONLY(MWCGUserPasswordRequest)
      switch (key) {
        case 0: [self localIzedMessage:@"CGCharLoginSuccessful"]; state = MWCGrunClientWait; break;
        case 1: [self localIzedMessage:@"CGCharIncorrectPassword"]; break;
        case 2: [self enterUserNameRequestState]; break;
        default: [self linkableErrorMessage:[NSString stringWithFormat:@"Received funny key %lu in rt_loginPlayer", key]];
      }
      break;
      
    /* case rt_lookup: */
    /* case rt_findName: */
    /* case rt_readProc: */
    /* case rt_writeProcNew: */
    /* case rt_runProc: */
    
    case rt_log:
    case rt_inputLine:
    case rt_setSync:
    case rt_rawKey:
    case rt_regionSelect:
    case rt_buttonHit:
      WRONG_MSG_DIRECTION; break;
      
    case rt_flushEffect:
      [effectsCache removeObjectForKey:[NSNumber numberWithUnsignedLong:key]];
      break;

    case rt_textResize:
    case rt_incRef:
    case rt_decRef:
    case rt_symbolEnter:
    case rt_symbolDelete:
    case rt_useTable:
    case rt_unuseTable:
    case rt_describeBuiltin:
    case rt_describe:
    case rt_graphicsFlip:
    case rt_voiceFlip:
    case rt_soundFlip:
    case rt_musicFlip:
    case rt_doEditProc:
    case rt_editStringDone:
    case rt_replaceProc:
    case rt_editProcDone:
    case rt_getStringDone:
    case rt_effectDone:
    case rt_queryFileDone:
      WRONG_MSG_DIRECTION; break;
    
    case rt_createContainer:
    case rt_createComponent: {
      [self prepareNewGUI];
      [self send:[MWCGMudMessage messageWithType:type key:key flag:flag uint:uint tail:tail] toLinkFor:@"newGUI"];
      break;
    }
        
    case rt_makeFrame:
      if (![[self links] objectForKey:@"newGUI"]) break;
      
      [self send:MWTokenGUIShrinkwrap toLinkFor:@"newGUI"];
      
      {
        id wc = [[[self links] objectForKey:@"newGUI"] otherObject:self];
        [self unlink:@"inward"];
        [self unlink:@"newGUI"];
        [self link:@"inward" to:@"outward" of:wc];
        [wc showWindow:self];
      }
      break;
    
    default:
      [self linkableErrorMessage:[NSString stringWithFormat:@"Couldn't handle message type=%s key=%u flag=%u uint=%u %@\n",
        requestTypeNames[type], key, flag, uint, [tail description]]];
      break;
  }
}
#undef STATE_ONLY
#undef WRONG_MSG_DIRECTION

- (void)remoteTextHolderShouldSave:(MWRemoteTextHolder *)th {
  [self packageAndSendMessageType:rt_editStringDone key:0 flag:YES uint:0 tail:[[th string] dataUsingEncoding:CGMUD_ENCODING allowLossyConversion:YES]];
  [th hasBeenSaved];
}

- (void)processOutwardString:(NSString *)str {
  NSData *strData = [str dataUsingEncoding:CGMUD_ENCODING allowLossyConversion:YES];
  switch (state) {
    case MWCGUserNameRequest: {
      NSMutableData *tail = [NSMutableData data];
      [tail appendData:strData];
      [tail appendBytes:"\0" length:1];
      [self packageAndSendMessageType:rt_askPlayer key:1 flag:0 uint:0 tail:tail];
      break;
    }
    case MWCGUserPasswordRequest: {
      NSMutableData *tail = [NSMutableData data];
      [tail appendData:strData];
      [tail setLength:PASSWORD_LEN];
      cgmud_crypt([tail mutableBytes], 0, sessionKey);
      [self packageAndSendMessageType:rt_loginPlayer key:0 flag:0 uint:0 tail:tail];
      break;
    }
    case MWCGReady: {
      NSMutableData *tail = [NSMutableData data];
      [tail appendData:strData];
      [tail appendBytes:"\0" length:1];
      [self packageAndSendMessageType:rt_inputLine key:0 flag:0 uint:0 tail:tail];
      break;
    }
    default: [self linkableTraceMessage:[NSString stringWithFormat:@"Ignoring outward string in state %i\n", state]]; break;
  }
}

- (void)processUserEvent:(NSEvent *)event {
  const unichar character = [[event characters] characterAtIndex:0];
  int rawKey = -1;
  if ([event modifierFlags] & (NSNumericPadKeyMask | NSFunctionKeyMask)) {
    switch (character) {
      case '7': rawKey = RAWKEY_UPLEFT; break;
      case '8': rawKey = RAWKEY_UP; break;
      case '9': rawKey = RAWKEY_UPRIGHT; break;
      case '4': rawKey = RAWKEY_LEFT; break;
      case '5': rawKey = RAWKEY_CENTER; break;
      case '6': rawKey = RAWKEY_RIGHT; break;
      case '1': rawKey = RAWKEY_DOWNLEFT; break;
      case '2': rawKey = RAWKEY_DOWN; break;
      case '3': rawKey = RAWKEY_DOWNRIGHT; break;
      case '+': rawKey = RAWKEY_PLUS; break;
      case '-': rawKey = RAWKEY_MINUS; break;
      case NSHelpFunctionKey: rawKey = RAWKEY_HELP; break;
      default:
        NSBeep();
        break;
    }
  } else {
    NSBeep();
  }
  if (rawKey != -1) [self packageAndSendMessageType:rt_rawKey key:rawKey flag:0 uint:0 tail:nil];
}

- (void)packageAndSendMessageType:(RequestType_t)type key:(uint32_t)key  flag:(BOOL)flag uint:(uint16_t)Puint tail:(NSData *)tail {
  MWCGMudMessage *msg = [MWCGMudMessage messageWithType:type key:key flag:flag uint:Puint tail:tail];
  
  [self linkableTraceMessage:[NSString stringWithFormat:@"--> %-18s key=%lu flag=%u uint=%u %@\n", requestTypeNames[type], key, flag, Puint, [tail description]]];
  
  [self sendMessageOutward:msg];
}

- (void)sendMessageOutward:(MWCGMudMessage *)msg {
  [self send:[msg data] toLinkFor:@"outward"];
}

// --- Accessors ---

- (void)setFont:(NSFont *)newVal {
  [newVal retain]; [cFont release]; cFont = newVal;
}

// --- Configuration ---

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  
  [self setFont:[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]]];
}

@end


// --- Password obscurer copied from CGMud/Library/main.c ---

static void
cgmud_swapBits(BYTE_T *p, UINT_T index1, UINT_T index2)
{
    BYTE_T byte1, byte2, mask1, mask2, new1, new2;
    UINT_T mod1, mod2;

    mod1 = index1 % CHAR_BIT;
    mod2 = index2 % CHAR_BIT;
    index1 /= CHAR_BIT;
    index2 /= CHAR_BIT;
    if (index1 != index2) {
	mask1 = 1 << mod1;
	mask2 = 1 << mod2;
	byte1 = *(p + index1);
	byte2 = *(p + index2);
	new1 = byte1;
	new2 = byte2;
	new1 &= ~mask1;
	new2 &= ~mask2;
	byte1 >>= mod1;
	byte2 >>= mod2;
	byte1 &= 1;
	byte2 &= 1;
	byte1 <<= mod2;
	byte2 <<= mod1;
	new1 |= byte2;
	new2 |= byte1;
	*(p + index1) = new1;
	*(p + index2) = new2;
    }
}

static void
cgmud_crypt(CHAR_T *pp, BOOL_T decrypt, ULONG_T sessionKey)
{
#define SWAP_COUNT	50
    BYTE_T key[4];
    BYTE_T *p;
    int i;
    static BYTE_T swaps[SWAP_COUNT * 2] = {
	119,  55,
	 78,  45,
	149,  48,
	 35,  90,
	 77, 133,
	 10,  14,
	 80, 136,
	 17,  36,
	111,  46,
	 74,  51,
	 29,  12,
	102,  19,
	156, 138,
	 99, 112,
	118,  26,
	  5, 116,
	128, 109,
	 62, 104,
	 52, 134,
	  2,  33,
	 72, 150,
	106,  93,
	 16,  60,
	132,  92,
	 47,  63,
	  1,  97,
	113,  38,
	 85,  32,
	 11,   0,
	 98, 139,
	  7,  58,
	  4, 142,
	 56,  64,
	125,  34,
	 54, 103,
	130,  76,
	127,  79,
	 50,  24,
	 70,  89,
	 94,  18,
	 71, 135,
	140, 131,
	 44, 153,
	  6,  13,
	115,  87,
	107,  95,
	114, 141,
	 49, 151,
	 27,  83,
	 65, 126
    };

    /* session key is to be applied in a big-endian nature */
    key[0] = sessionKey >> 24;
    key[1] = sessionKey >> 16;
    key[2] = sessionKey >> 8;
    key[3] = sessionKey;
    p = (BYTE_T *) pp;
    if (! decrypt) {
	for (i = 0; i != PASSWORD_LEN; i += 1) {
	    *p++ ^= key[i % 4];
	}
    }
    p = (BYTE_T *) pp;
    for (i = 0; i != SWAP_COUNT; i += 1) {
	cgmud_swapBits(p, swaps[i * 2], swaps[i * 2 + 1]);
    }
    if (decrypt) {
	for (i = 0; i != PASSWORD_LEN; i += 1) {
	    *p++ ^= key[i % 4];
	}
    }
}
