/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTriggerFilter.h"

#import <Cocoa/Cocoa.h>
#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWAppUtilities.h>

#import "MWApplication.h"
#import "MWConnectionDocument.h"

#import "MWMCPMessage.h"

#import <pcre.h>

static NSCharacterSet *schemeCharacters, *urlEndTerminator, *urlEndChop;

@implementation MWTriggerFilter

+ (void)initialize {
  if (!schemeCharacters) {
    schemeCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-."] retain];
    urlEndTerminator = [[NSCharacterSet characterSetWithCharactersInString:@"<> \"'"] retain];
    urlEndChop = [[NSCharacterSet characterSetWithCharactersInString:@".,:\"';[]()"] retain];
  }
}


// --- Utilities ---

- (void)send:(id)obj toChannelLinkWithIdentifier:(NSString *)ident {
  NSString *linkName = [@"channel_" stringByAppendingString:ident];
  if (![[self links] objectForKey:linkName]) {
    id wc;
  
    MWConnectionDocument *doc = [self probe:@selector(lpDocument:) ofLinkFor:@"inward"];
  
    if (!doc) {
      [self linkableErrorMessage:@"could not find document in order to create output window\n"];
      return;
    }
  
    wc = [doc outputWindowOfClass:NSClassFromString(@"MWTextOutputWinController") group:@"MWTriggerFilter-channel" reuse:YES connect:NO display:YES];
    [wc link:@"outward" to:linkName of:self];
  }
  [self send:obj toLinkFor:linkName];
}

#if 1
- (id)convertTkMOOTag:(NSScanner *)scan {
  NSString *tag;
  if (!(
       [scan scanString:@"{"/*}*/ intoString:NULL]
    && [scan scanUpToString:@" " intoString:&tag]
  )) goto failure;
  
  if ([tag hasSuffix:@":"]) {
    NSString *value;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (![scan mwScanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:/*{*/@"} "] possiblyQuotedBy:'"' intoString:&value]) goto failure;
    [dict setObject:value forKey:[tag substringToIndex:[tag length] - 1]];

    while (![scan scanString:/*{*/@"}" intoString:NULL] && ![scan isAtEnd]) {
      if (!(
           [scan mwScanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@": "] possiblyQuotedBy:'"' intoString:&tag]
        && [scan scanString:@":" intoString:NULL]
        && [scan mwScanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:/*{*/@"} "] possiblyQuotedBy:'"' intoString:&value]
      )) goto failure;
      [dict setObject:value forKey:tag];
    }
    return dict;
    
  } else if ([tag isEqualToString:@"~"]) {
    NSString *content;
    [scan setScanLocation:[scan scanLocation] + 1]; // skip space
    [scan mwScanBackslashEscapedStringUpToCharacter:'}' intoString:&content];
    [scan scanString:/*{*/@"}" intoString:NULL];
    return [[[NSAttributedString alloc] initWithString:content attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:MWDisplayProportionalAttribute]] autorelease];
  } else {
    NSMutableArray *kids = [NSMutableArray array];
    NSMutableAttributedString *buf = [[[NSMutableAttributedString alloc] init] autorelease];
    while (![scan scanString:/*{*/@"}" intoString:NULL] && ![scan isAtEnd]) {
      [kids addObject:[self convertTkMOOTag:scan]];
    }
    //NSLog(@"tag %@, kids %@", [tag description], [kids description]);
    if ([tag isEqualToString:@"link"]) {
      Class msgClass = NSClassFromString(@"MWMCPMessage");
      // fixme: there ought to somehow room for alternate MCP implementations (which wouldn't be allowed to use the MW* namespace), perhaps
    
      [buf setAttributedString:[kids objectAtIndex:1]];
      if (msgClass) {
        [buf addAttribute:NSLinkAttributeName value:[msgClass messageWithName:@"dns-com-awns-jtext-pick" arguments:[NSDictionary dictionaryWithObjectsAndKeys:
          [[kids objectAtIndex:0] objectForKey:@"address-type"], @"type", // sigh
          [[kids objectAtIndex:0] objectForKey:@"args"], @"args",
          nil
        ]] range:NSMakeRange(0, [buf length])];
      }
      
    } else if ([tag isEqualToString:@"header"]) {
      NSFont *font = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]];
      
      // FIXME: shouldn't be using the font explicitly. text OWC ought to have more symbolic attributes..
      font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * 1.5];
     
      [buf setAttributedString:[kids objectAtIndex:0]];
      [buf addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [buf length])];
      
    } else if ([tag isEqualToString:@"hgroup"]) {
      NSEnumerator *e = [kids objectEnumerator];
      NSAttributedString *s;
      while ((s = [e nextObject])) {
        [buf appendAttributedString:s];
      }
    } else {
      return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"<Unknown tag %@>", tag]] autorelease];
    }
    //NSLog(@"buf %@", buf);
    return buf;
  }
  
  failure:
  [scan setScanLocation:[[scan string] length]];
  return [[[NSAttributedString alloc] initWithString:[[scan string] substringFromIndex:[scan scanLocation]]] autorelease];
}
#endif


// --- Filtering ---

- (void)processLineFromInward:(NSAttributedString *)astr role:(NSString *)role {
  id <MWConfigSupplier> const myConfig = [self config];
  NSString *const str = [astr string];
  
  MWConfigPath *const aliasDir = [MWConfigPath pathWithComponent:@"Aliases"];
  MWenumerate([[myConfig allKeysAtPath:aliasDir] objectEnumerator], NSString *, aliasKey) {
    MWConfigPath *const aliasPath = [aliasDir pathByAppendingComponent:aliasKey];

    if ([[myConfig objectAtPath:[aliasPath pathByAppendingComponent:@"inactive"]] boolValue])
      continue;

    NSString *const match = [myConfig objectAtPath:[aliasPath pathByAppendingComponent:@"match"]];
    
    if (![match length])
      continue;
   
    BOOL const isWordAlias = [[NSCharacterSet alphanumericCharacterSet] characterIsMember:[match characterAtIndex:[match length] - 1]];
   
    if ([str hasPrefix:match]
        && (
             [str length] == [match length]
          || !isWordAlias
          || [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[str characterAtIndex:[match length]]])) {

      NSString *const argstr = (isWordAlias && [str length] > [match length]) ? [str substringFromIndex:[match length] + 1] : [str substringFromIndex:[match length]];

      NSMutableDictionary *const scriptSendArguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        self, @"linkable",
        @"outward", @"_MWScriptResultHint",
        [NSNumber numberWithInt:1], @"count",
        str, [NSNumber numberWithInt:0],
        argstr, [NSNumber numberWithInt:1],
        nil
      ];
      
      NSString *const scriptLocation = [NSString stringWithFormat:@"alias \"%@\" (%@)", [[self config] objectAtPath:[aliasPath pathByAppendingComponent:@"name"]], aliasKey];
     
      MWScriptContexts *const scriptContext = [self probe:@selector(lpScriptContexts:) ofLinkFor:@"inward"];
      
      [[myConfig objectAtPath:[aliasPath pathByAppendingComponent:@"script"]] 
        evaluateWithArguments:scriptSendArguments 
        contexts:scriptContext 
        location:scriptLocation
      ];
      return;
    }
  }
  
  [self send:[MWLineString lineStringWithAttributedString:astr role:role] toLinkFor:@"outward"];
}

- (void)processLineFromOutward:(NSAttributedString *)astr role:(NSString *)role {
  NSMutableAttributedString *abuf = [[astr mutableCopy] autorelease];
  NSMutableString *buf = [abuf mutableString];
  NSRange aRange;
    
  NSString *useChannel = nil;
  BOOL lineGagged = NO;
  
  if ((aRange = [buf rangeOfString:@"!!SOUND("]).length || (aRange = [buf rangeOfString:@"!!MUSIC("]).length) {
    NSCharacterSet *spaceChars = [NSCharacterSet whitespaceCharacterSet];
    BOOL cMSPAnchored = NO; // FIXME
    NSScanner *scan = [NSScanner scannerWithString:buf];
    
    // values
    BOOL isMusic = NO;
    NSString *filename = nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if (cMSPAnchored && aRange.location != 0) goto MSPABORT;
    [scan setScanLocation:aRange.location];
    [scan mwSetCharactersToBeSkippedToEmptySet];
    
    if (!(
       [scan scanString:@"!!" intoString:NULL]
    )) goto MSPABORT;
    if ([scan scanString:@"SOUND" intoString:NULL]) {
      isMusic = NO;
    } else if ([scan scanString:@"MUSIC" intoString:NULL]) {
      isMusic = YES;
    } else {
      goto MSPABORT;
    }
    if (!(
       [scan scanString:@"(" intoString:NULL]
    && [scan scanUpToCharactersFromSet:spaceChars intoString:&filename]
    )) goto MSPABORT;
    [scan scanCharactersFromSet:spaceChars intoString:NULL];
    while (![scan scanString:@")" intoString:NULL]) {
      NSString *key, *value;
      if ([scan isAtEnd]) goto MSPABORT;
      if (!(
         [scan scanUpToString:@"=" intoString:&key]
      && [scan scanString:@"=" intoString:NULL]
      && [scan scanUpToCharactersFromSet:spaceChars intoString:&value]
      && [scan scanCharactersFromSet:spaceChars intoString:NULL]
      )) goto MSPABORT;
      [params setObject:value forKey:key];
    }
    
    [abuf deleteCharactersInRange:MWMakeABRange(aRange.location, [scan scanLocation])];
    // FIXME: wildcards. and repeats/priority/downloading.
    
    { 
      NSSound *snd;
    
      if (!(
           (snd = [NSSound soundNamed:filename])
        || (snd = [[[NSSound alloc] initWithContentsOfFile:[[MWRegistry defaultRegistry] pathForResourceFromSearchPath:[NSString stringWithFormat:@"MSP/%@", filename]]] autorelease])
      )) goto MSPABORT;
    
      [self send:[NSSound soundNamed:filename] toLinkFor:@"inward"];
    }
    
    MSPABORT: ;
    
  } 
  
#if 1
  // tkMOO text tagging. FIXME: add disable switch for this, maybe move it into more sensible location
  if ([buf hasPrefix:@"tkmootag: "]) {
    NSScanner *scan = [NSScanner scannerWithString:buf];
    [scan scanString:@"tkmootag: " intoString:NULL];
    
    // NSLog(@"%@", buf);
    
    [abuf setAttributedString:[self convertTkMOOTag:scan]];
  }
#endif
   
  aRange = NSMakeRange(0,[buf length]);  
  while ((aRange = [buf rangeOfString:@"://" options:0 range:aRange]).length) {
    NSString *urlString = nil;
    NSURL *url = nil;
    unsigned len = [buf length];
    NSMutableAttributedString *abufTemp = [[abuf mutableCopy] autorelease];
    int schemeLength = 0;

    while (aRange.location > 0 && [schemeCharacters characterIsMember:[buf characterAtIndex:aRange.location-1]]) {
      aRange.location--;
      aRange.length++;
      schemeLength++;
    }
    if (schemeLength < 1) goto MATCH_FAILED; // zero-length scheme is not a useful URL
    
    while ((aRange.location + aRange.length) < len && ![urlEndTerminator characterIsMember:[buf characterAtIndex:aRange.location + aRange.length]]) aRange.length++;
    
    urlString = [buf substringWithRange:aRange];
    while ([urlEndChop characterIsMember:[urlString characterAtIndex:[urlString length]-1]]) urlString = [urlString substringToIndex:[urlString length]-1];
    
    //NSLog(@"Matched URL '%@'", urlString);
    
    url = [NSURL URLWithString:urlString];
    if (url) {
      [abufTemp addAttributes:[NSDictionary dictionaryWithObject:url forKey:NSLinkAttributeName] range:aRange];
      abuf = abufTemp;
    }
    
    MATCH_FAILED: aRange = MWMakeABRange(aRange.location + aRange.length, [buf length]);
  }
      
  // Triggers
  // FIXME: ought to precompile the regexen
  // FIXME: convert this huge mess into a method object
  if (![role isEqual:MWLocalRole]) {
    MWConfigPath *dir = [MWConfigPath pathWithComponent:@"Triggers"];
    NSEnumerator *trigKeyE = [[[self config] allKeysAtPath:dir] objectEnumerator];
    NSString *trigKey;
    BOOL noMoreTriggers = NO;
    while (!noMoreTriggers && (trigKey = [trigKeyE nextObject])) {
      MWConfigPath *const trigPath = [dir pathByAppendingComponent:trigKey];
      BOOL matched = NO, noMoreInLine = NO;
      NSArray *const patterns = [[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"patterns"]] componentsSeparatedByLineTerminators];
      
      NSRange matchedRange = {0, 0};
      
      NSEnumerator *const patE = [patterns objectEnumerator];
      NSString *pat = nil; /* prevent false 'used uninitialized' warning */
      if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"inactive"]] boolValue]) continue;
      
      /* iterate over patterns OR multiple matches in a line */
      while (!noMoreTriggers && !noMoreInLine && (matched || (pat = [patE nextObject]))) {
        if ([pat length] == 0)
          continue;
      
        const char *error = NULL;
        int errorLocation = 0;
        pcre *re = pcre_compile(
          [pat UTF8String],
          PCRE_UTF8 | ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"matchIgnoreCase"]] boolValue] ? PCRE_CASELESS : 0),
          &error, &errorLocation, NULL);

        NSData *dataForMatch = [buf dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        
#       define MW_OVECTORSIZE 60
        int re_numset = 0; /* prevent false 'used uninitialized' warning */
        int re_ovector[MW_OVECTORSIZE];

        if (re && (re_numset = pcre_exec(
            re, NULL,
            [dataForMatch bytes], [dataForMatch length],
            NSMaxRange(matchedRange), 0, re_ovector, MW_OVECTORSIZE
          )) >= 0
        ) {
          matchedRange = MWMakeABRange(re_ovector[0], re_ovector[1]);
          
          if (matchedRange.length <= 0) // prevent an infinite loop
            noMoreInLine = YES;
          
          {

            /* --- Script environment setup --- */

            NSMutableDictionary *const scriptBaseArguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
              self, @"linkable",
              [NSNumber numberWithInt:re_numset - 1], @"count",
              nil
            ];
            
            { int i;
              for (i = 0; i < re_numset; i++) {
                [scriptBaseArguments setObject:[buf substringWithRange:MWMakeABRange(re_ovector[i * 2], re_ovector[i * 2 + 1])] forKey:[NSNumber numberWithInt:i]];
              }
            }
            
            NSMutableDictionary *const scriptReturnArguments = [[scriptBaseArguments mutableCopy] autorelease];
            [scriptReturnArguments setObject:@"return" forKey:@"_MWScriptResultHint"];
    
            NSMutableDictionary *const scriptSendArguments = [[scriptBaseArguments mutableCopy] autorelease];
            [scriptSendArguments setObject:@"outward" forKey:@"_MWScriptResultHint"];
            
            NSString *const scriptLocation = [NSString stringWithFormat:@"trigger \"%@\" (%@)", [[self config] objectAtPath:[trigPath pathByAppendingComponent:@"name"]], trigKey];

            MWScriptContexts *scriptContext = [self probe:@selector(lpScriptContexts:) ofLinkFor:@"inward"];

            /* --- Perform trigger actions --- */
    
            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doCommandLink"]] boolValue]) {
              id const command = [[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doCommandLink_command"]] 
                evaluateWithArguments:scriptReturnArguments 
                contexts:scriptContext 
                location:scriptLocation
              ];
              if (command)
                [abuf addAttributes:[NSDictionary dictionaryWithObject:[MWLineString lineStringWithString:MWForceToString(command)] forKey:NSLinkAttributeName] range:matchedRange];
            }
    
            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doChannel"]] boolValue]) {
              NSString *const channelName = MWForceToString([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doChannel_name"]] 
                evaluateWithArguments:scriptReturnArguments 
                contexts:scriptContext 
                location:scriptLocation
              ]);
              useChannel = channelName;
            }
    
            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doSubstitute"]] boolValue]) {
              NSString *const replacement = MWForceToString([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doSubstitute_replacement"]] 
                evaluateWithArguments:scriptReturnArguments 
                contexts:scriptContext 
                location:scriptLocation
              ]);
              [abuf replaceCharactersInRange:matchedRange withString:replacement];
              matchedRange = NSMakeRange(matchedRange.location, [replacement length]);
            }
    
            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doTerminate"]] boolValue])
              noMoreTriggers = YES;

            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"doGag"]] boolValue])
              lineGagged = YES;

            if ([[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"matchOncePerLine"]] boolValue])
              noMoreInLine = YES;
              
            [[[self config] objectAtPath:[trigPath pathByAppendingComponent:@"script"]] 
              evaluateWithArguments:scriptSendArguments 
              contexts:scriptContext 
              location:scriptLocation
            ];
          }

        } else if (!re) {
          [self localMessage:[NSString stringWithFormat:NSLocalizedString(@"MWTriggerFilter-reCompileFailed%@%@",nil), pat, [NSString stringWithCString:error]]];
        } else {
          switch (re_numset) {
            case PCRE_ERROR_NOMATCH:
              //NSLog(@"    failed to match");
              break;
            default:
              [self localMessage:[NSString stringWithFormat:NSLocalizedString(@"MWTriggerFilter-reMatchError%i%@",nil), re_numset, pat]];
              break;
          }
        }
        
        matched = re && re_numset >= 0;
      
        pcre_free(re);
      } // end patE
    } // end trigKeyE
  }
  
  
  
  // Done with misc sub-line processing, now determine the destination of the complete line
  if (!lineGagged) {
    MWLineString *ls = [MWLineString lineStringWithAttributedString:[[abuf copy] autorelease] role:role];
  
    if (useChannel) {
      [self send:ls toChannelLinkWithIdentifier:useChannel];
    } else {
      [self send:ls toLinkFor:@"inward"];
    }
  }
}

- (void)processTokenFromOutward:(NSString *)name {
  MWToken *token = [MWToken token:name];
    
  NSEnumerator *linkNameE = [[self links] keyEnumerator];
  NSString *linkName;
  while ((linkName = [linkNameE nextObject]))
    if ([linkName hasPrefix:@"channel_"])
      [self send:token toLinkFor:linkName];
  [self send:token toLinkFor:@"inward"];

  if ([name isEqual:[MWTokenConnectionOpened name]]) {
    [[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"LoginScript"]] 
      evaluateWithArguments:[NSMutableDictionary dictionaryWithObjectsAndKeys:
        self, @"linkable",
        @"outward", @"_MWScriptResultHint",
        nil
      ] 
      contexts:[self probe:@selector(lpScriptContexts:) ofLinkFor:@"inward"] 
      location:MWLocalizedStringForClass(@"login script", [MWTriggerFilter class])
    ];
  }
}

- (void)processTokenFromInward:(NSString *)name {
  if ([name isEqual:[MWTokenLogoutConnection name]]) {
    MWScript *const logoutScript = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"LogoutScript"]];
    if (logoutScript && [[logoutScript source] length]) {
      [logoutScript
        evaluateWithArguments:[NSMutableDictionary dictionaryWithObjectsAndKeys:
          self, @"linkable",
          @"outward", @"_MWScriptResultHint",
          nil
        ] 
        contexts:[self probe:@selector(lpScriptContexts:) ofLinkFor:@"inward"] 
        location:MWLocalizedStringForClass(@"login script", [MWTriggerFilter class])
      ];
      return;
    } else {
      [self localIzedMessage:@"MWTriggerFilter-NoLogoutScript"];
    }
  }
  
  [self send:[MWToken token:name] toLinkFor:@"outward"];
}

- (void)processUserEvent:(NSEvent *)event {
  NSString *code = MWEventToStringCode(event);
  NSString *send = [[self config] objectAtPath:[MWConfigPath pathWithComponents:@"KeyCommands", code, @"command", nil]];
  
  if (send) {
    [self send:[MWLineString lineStringWithString:send role:nil] toLinkFor:@"outward"];
    [self send:[MWLineString lineStringWithString:send role:MWEchoRole] toLinkFor:@"inward"];
  } else {
    NSBeep();
  }
}

// --- Linkage ---

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  if ([link isEqual:@"outward"]) {
    if ([obj isKindOfClass:[MWLineString class]]) {
      [self processLineFromOutward:[obj attributedString] role:[obj role]];
    } else if ([obj isKindOfClass:[NSAttributedString class]]) {
      [self linkableErrorMessage:@"Warning: MWTriggerFilter received NSAttributedString from outward, not currently correctly supported."];
      [self processLineFromOutward:obj role:nil];
    } else if ([obj isKindOfClass:[NSString class]]) {
      [self linkableErrorMessage:@"Warning: MWTriggerFilter received NSString from outward, not currently correctly supported."];
      [self processLineFromOutward:[[[NSAttributedString alloc] initWithString:obj attributes:[NSDictionary dictionary]] autorelease] role:nil];
    } else if ([obj isKindOfClass:[MWToken class]]) {
      [self processTokenFromOutward:[(MWToken *)obj name]];
    } else {
      [self send:obj toLinkFor:@"inward"];
    }
    return YES;
  } else if ([link isEqual:@"inward"]) {


    if ([obj isKindOfClass:[MWLineString class]]) {
      [self processLineFromInward:[obj attributedString] role:[obj role]];
    } else if ([obj isKindOfClass:[NSAttributedString class]]) {
      [self linkableErrorMessage:@"Warning: MWTriggerFilter received NSAttributedString from inward, not currently correctly supported."];
      [self processLineFromInward:obj role:nil];
    } else if ([obj isKindOfClass:[NSString class]]) {
      [self linkableErrorMessage:@"Warning: MWTriggerFilter received NSString from inward, not currently correctly supported."];
      [self processLineFromInward:[[[NSAttributedString alloc] initWithString:obj attributes:[NSDictionary dictionary]] autorelease] role:nil];
    } else if ([obj isKindOfClass:[MWToken class]]) {
      [self processTokenFromInward:[(MWToken *)obj name]];
    } else if ([obj isKindOfClass:[NSEvent class]]) {
      [self processUserEvent:obj];
    } else {
      [self send:obj toLinkFor:@"outward"];
    }
    return YES;
 /* else if link is a channel... */
 } else {
   return NO;
 }
}

- (id)lpConnectionQualification:(NSString *)link { 
  if ([link hasPrefix:@"channel_"]) {
    return [link substringFromIndex:8];
  } else if ([link isEqual:@"inward"]) {
    return [self probe:@selector(lpConnectionQualification:) ofLinkFor:@"outward"];
  } else if ([link isEqual:@"outward"]) {
    return [self probe:@selector(lpConnectionQualification:) ofLinkFor:@"inward"];
  } else {
    return nil;
  }
}

@end
