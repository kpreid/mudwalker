/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWTextTerminalPane.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWOutputTextView.h>
#import <MWAppKit/MWNSTextStorageAdditions.h>
#import "MWTextOutputWinController.h"
#import "MWColorConverter.h"

@interface MWTextTerminalPane (Private)

- (void)adjustAttributedString:(NSMutableAttributedString *)mstr;
- (NSDictionary *)defaultOutputAttributes;
- (void)setupStyleStuff:(NSNotification *)notif;

@end

@implementation MWTextTerminalPane

- (id)init {
  if (!(self = [super init])) return nil;

  hasCompleteLine = YES;
  
  statusBars = [[NSMutableArray allocWithZone:[self zone]] init];
  statusBarFont = [NSFont userFixedPitchFontOfSize:9];
  statusBarAttributes = [[NSDictionary allocWithZone:[self zone]] initWithObjectsAndKeys:
    statusBarFont, NSFontAttributeName,
    nil
  ];

  return self;
}

- (void)dealloc {
  [lastLineReceived autorelease]; lastLineReceived = nil;
  [defaultOutputAttributes autorelease]; defaultOutputAttributes = nil;
  [defaultParagraphStyle autorelease]; defaultParagraphStyle = nil;
  [displayColorCache autorelease]; displayColorCache = nil;
  [statusBars autorelease]; statusBars = nil;
  [statusBarAttributes autorelease]; statusBarAttributes = nil;
  [statusBarFont autorelease]; statusBarFont = nil;
  [super dealloc];
}

- (void)mainViewDidLoad {
  [mainTextView setAllowsUndo:NO];
  [mainTextView setEditable:NO];
  [mainTextView setImportsGraphics:NO];
  [mainTextView setRichText:NO];
  [mainTextView setUsesFontPanel:NO];
  [mainTextView setAutoScrollToEnd:YES];
  if ([mainTextView respondsToSelector:@selector(setLinkTextAttributes:)]) {
    // quick fix. we're doing our own attribute management so we don't want this automatic feature.
    // fixme: consider letting Cocoa handle this for us
    [mainTextView setLinkTextAttributes:[NSDictionary dictionary]];
  }
  [super mainViewDidLoad];
}

- (NSString *)summaryTitle {
  if ([self lastLineReceived]) 
    // FIXME: truncate-with-... to sane length
    return [NSString stringWithFormat:@"%@: %@", [super summaryTitle], [self lastLineReceived]];
  else
    return [super summaryTitle];
}

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  [self setupStyleStuff:notif];
}

- (void)setupStyleStuff:(NSNotification *)notif {
  NSMutableParagraphStyle *const specialParaStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  id <MWConfigSupplier> myConfig = [self config];
  NSString *const changedSetting = [[[[notif userInfo] objectForKey:@"path"] components] objectAtIndex:0];

  if (!changedSetting || [changedSetting isEqual:@"ColorSets"] || [changedSetting isEqual:@"SelectedColorSet"] || [changedSetting isEqual:@"TextFontMonospaced"] || [changedSetting isEqual:@"TextFontProportional"] || [changedSetting isEqual:@"TextWrapIndent"] || [changedSetting isEqual:@"ColorBrightBold"]) {
    float const indent = [[myConfig objectAtPath:[MWConfigPath pathWithComponent:@"TextWrapIndent"]] floatValue];
    NSFont *const font = [myConfig objectAtPath:[MWConfigPath pathWithComponent:@"TextFontMonospaced"]];
  
    if (indent < 0)
      [specialParaStyle setFirstLineHeadIndent:[specialParaStyle firstLineHeadIndent] + -indent];
    else
      [specialParaStyle setHeadIndent:[specialParaStyle headIndent] + indent];

    {
      NSMutableArray *const newDCC = [NSMutableArray array];
      NSDictionary *const colors = [myConfig objectAtPath:[MWConfigPath pathWithComponents:
        @"ColorSets",
        [myConfig objectAtPath:[MWConfigPath pathWithComponent:@"SelectedColorSet"]],
        @"ColorDictionary",
        nil
      ]];
      
      int i;
      for (i = 0; i < MWCOLOR_MAXINDEX; i++) {
        NSColor *color = [colors objectForKey:MWColorNameForIndex(i)];
        if (!color)
          color = [NSColor grayColor];
        [newDCC addObject:color];
      }

      [displayColorCache release];
      displayColorCache = [newDCC retain];
    }
    
    [self setDefaultOutputAttributes:
      [NSDictionary dictionaryWithObjectsAndKeys:
        [displayColorCache objectAtIndex:MWCOLOR_GROUP_NORMAL + MWCOLOR_INDEX_DFORE], NSForegroundColorAttributeName,
        font, NSFontAttributeName,
        specialParaStyle, NSParagraphStyleAttributeName,
        nil
      ]
    ];

    // update display to match new style    
    [mainTextView setBackgroundColor:[displayColorCache objectAtIndex:MWCOLOR_GROUP_NORMAL + MWCOLOR_INDEX_DBACK]];
    [mainTextView setNeedsDisplay:YES];
    [self adjustAttributedString:[mainTextView textStorage]];

    if (!changedSetting || [changedSetting isEqual:@"TextFontMonospaced"] || [changedSetting isEqual:@"TextWrapIndent"] || [changedSetting isEqual:@"ColorBrightBold"])
      [(MWTextOutputWinController *)delegate send:MWTokenWindowSizeChanged toLinkFor:@"outward"];
  }
  
  if ([changedSetting isEqual:@"InputPromptInOutput"])
    [self setInputPrompt:[[delegate terminalPaneExtInputManager:self] inputPrompt]];
}

- (void)adjustAttributedString:(NSMutableAttributedString *)mstr {
  id <MWConfigSupplier> myConfig = [self config];
  BOOL colorBrightBold = [[myConfig objectAtPath:[MWConfigPath pathWithComponent:@"ColorBrightBold"]] boolValue];
  NSFont *proportionalFont = [myConfig objectAtPath:[MWConfigPath pathWithComponent:@"TextFontProportional"]];
  unsigned index = 0, len = [mstr length];

  for (index = 0; index < len; ) {
     NSRange r;
     NSMutableDictionary *attrs = [[[self defaultOutputAttributes] mutableCopy] autorelease];
     NSDictionary *prevAttrs = [mstr attributesAtIndex:index effectiveRange:&r];
     NSDictionary *origAttrs = [prevAttrs objectForKey:@"MWOriginalAttributes"];
     
     if (!origAttrs) origAttrs = prevAttrs;
     [attrs addEntriesFromDictionary:origAttrs];
     [attrs setObject:origAttrs forKey:@"MWOriginalAttributes"];
     
     {
       id aObj;
       BOOL isBright = (aObj = [attrs objectForKey:MWANSIBrightnessAttribute]) && [aObj intValue] > 0;
       BOOL isDim = aObj && [aObj intValue] < 0;
       BOOL isInverse = (aObj = [attrs objectForKey:MWANSIInverseAttribute]) && [aObj boolValue];
       unsigned colorOffset =  isBright ? MWCOLOR_GROUP_BRIGHT : isDim ? MWCOLOR_GROUP_DIM : MWCOLOR_GROUP_NORMAL;
       
       NSColor *ansiForeColor;
       NSColor *ansiBackColor;
       id ansiForeAttr = [attrs objectForKey:MWANSIForegroundAttribute];
       id ansiBackAttr = [attrs objectForKey:MWANSIBackgroundAttribute];

       id roleAttr     = [attrs objectForKey:MWRoleAttribute];
       id linkAttr     = [attrs objectForKey:NSLinkAttributeName];
       BOOL isProportional = (aObj = [attrs objectForKey:MWDisplayProportionalAttribute]) && [aObj boolValue];
       
       //printf("colorOffset is %u, foreAttr = %i, backAttr = %i\n", colorOffset, [ansiForeAttr intValue], [ansiBackAttr intValue]);

       ansiForeColor = [displayColorCache objectAtIndex: (
         ansiForeAttr ? [ansiForeAttr intValue] + colorOffset : 
         [roleAttr isEqual:MWLocalRole] ? MWCOLOR_SP_LOCAL :
         [roleAttr isEqual:MWEchoRole ] ? MWCOLOR_SP_ECHO :
         MWCOLOR_INDEX_DFORE + colorOffset
       )];
       ansiBackColor = [displayColorCache objectAtIndex: (
         ansiBackAttr ? [ansiBackAttr intValue] + colorOffset :
         MWCOLOR_INDEX_DBACK + colorOffset
       )];
       
       if ([roleAttr isEqual:MWLocalRole] || isProportional) {
         [attrs setObject:proportionalFont forKey:NSFontAttributeName];
       }
       
       if ((colorBrightBold && (isBright || isDim)) || [roleAttr isEqual:MWLocalRole]) [attrs
         setObject:[[NSFontManager sharedFontManager]
           convertWeight:!isDim
           ofFont:[attrs objectForKey:NSFontAttributeName]
         ]
         forKey:NSFontAttributeName
       ];
        
       if (![origAttrs objectForKey:NSForegroundColorAttributeName]) {
         [attrs setObject:
           linkAttr ? [displayColorCache objectAtIndex:MWCOLOR_SP_LINK] :
           isInverse ? ansiBackColor :
           ansiForeColor
         forKey:NSForegroundColorAttributeName];
       }
       if (![origAttrs objectForKey:NSBackgroundColorAttributeName]) {
         [attrs setObject:isInverse ? ansiForeColor : ansiBackColor forKey:NSBackgroundColorAttributeName];
       }
       if (![origAttrs objectForKey:NSUnderlineStyleAttributeName]) {
         if (linkAttr) [attrs setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName];
       }
       
       if ((aObj = [attrs objectForKey:MWANSIUnderlineAttribute]) && [aObj boolValue]) {
         [attrs setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName];
       }
     }
    
     [mstr setAttributes:attrs range:r];
     index = r.location + r.length;
  }
  
  [mstr fixAttributesInRange:NSMakeRange(0, [mstr length])];
}

- (void)adjustAndDisplayAttributedString:(NSAttributedString *)input completeLine:(BOOL)completeLine {
  NSTextStorage *const storage = [mainTextView textStorage];
  NSMutableAttributedString *const mstr = [[input mutableCopy] autorelease];

  if ((completeLine || hasCompleteLine) && [storage length]) {
    [mstr
      replaceCharactersInRange:NSMakeRange(0,0)
      withAttributedString:[[[NSAttributedString alloc]
        initWithString:@"\n"
        attributes:[NSDictionary dictionary]
      ] autorelease]
    ];
  }

  [self adjustAttributedString:mstr]; 

  [storage beginEditing];
  
  [storage replaceCharactersInRange:NSMakeRange([storage length] - [self lengthOfInputSectionInTextStorage], 0) withAttributedString:mstr];
  
  if (![mainTextView autoScrollLock]) [storage maintainScrollbackOfLength:[(NSNumber*)[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"ScrollbackCharacters"]] intValue] + [self lengthOfInputSectionInTextStorage]];
  [storage endEditing];
  hasCompleteLine = completeLine;

  [self setLastLineReceived:[mstr string]];
}

- (unsigned)lengthOfInputSectionInTextStorage {
  return ([[[delegate terminalPaneExtInputManager:self] inputPrompt] length] + 1) * !!promptExistsInOutput;
}

// --- Actions ---

- (IBAction)mwClearScrollback:(id)sender {
  NSTextStorage *const storage = [mainTextView textStorage];
  NSAttributedString *const s = [[[NSAttributedString alloc] initWithString:@""] autorelease];

  [storage setAttributedString:s];
  [mainTextView didChangeText];
}

- (IBAction)autoScrollLock:(id)sender {
  [mainTextView autoScrollLock:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  if (action == @selector(mwClearScrollback:)) {
    return !![[mainTextView textStorage] length];
  } else if (action == @selector(autoScrollLock:)) {
    return [mainTextView validateUserInterfaceItem:item];
  } else {
    return [super validateUserInterfaceItem:item];
  }
}

// --- Probe methods ---

- (id)lpTextWindowSize:(NSString *)link {
  NSFont *attrFont = [[self defaultOutputAttributes] objectForKey:NSFontAttributeName];
  NSFont *screenFont = [attrFont screenFont];
  if (!screenFont) screenFont = attrFont;
  {
    float fontWidth = [screenFont advancementForGlyph:[screenFont glyphWithName:@"e"]].width;
    float fontHeight = [screenFont defaultLineHeightForFont];
    NSSize textViewSize = [[mainScrollView contentView] bounds].size;
    float padding = [[mainTextView textContainer] lineFragmentPadding];
    //printf("textViewSize=%f,%f font=%f,%f padding=%f\n", textViewSize.width, textViewSize.height, fontWidth, fontHeight, padding);
    float indent = [[[self defaultOutputAttributes] objectForKey:NSParagraphStyleAttributeName] firstLineHeadIndent];
    return [NSValue valueWithSize:NSMakeSize(
      (textViewSize.width - padding * 2 - indent) / fontWidth,
      (textViewSize.height) / fontHeight
    )];
  }
}


// --- Status bars ---

- (void)addStatusBar {
  // fixme: this ought to use font and color from config, handle kbd focus better, ...
  int statusBarHeight = ceil([@"M" sizeWithAttributes:statusBarAttributes].height) + 2;
  NSTextField *newBar = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, [mainTextView frame].size.width, statusBarHeight)] autorelease];
  
  [newBar setEditable:NO];
  [newBar setSelectable:YES];
  [newBar setBordered:NO];
  [newBar setDrawsBackground:NO];
  [newBar setFont:statusBarFont];
  [newBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
  [[newBar cell] setScrollable:YES];
  
  { NSRect f = [mainScrollView frame];
    [mainScrollView setFrame:NSMakeRect(f.origin.x, f.origin.y + statusBarHeight, f.size.width, f.size.height - statusBarHeight)];
  }
  [[[mainScrollView window] contentView] addSubview:newBar];
  [statusBars addObject:newBar];
}

- (void)removeStatusBar {
  int statusBarHeight = [[statusBars lastObject] frame].size.height;
  
  [[statusBars lastObject] removeFromSuperview];
  [statusBars removeLastObject];
  
  { NSRect f = [mainScrollView frame];
    [mainScrollView setFrame:NSMakeRect(f.origin.x, f.origin.y - statusBarHeight, f.size.width, f.size.height + statusBarHeight)];
  }
}

- (void)setStatusBar:(unsigned int)index toString:(NSString *)str {
  while ([statusBars count] <= index) [self addStatusBar];
  [[statusBars objectAtIndex:index] setAttributedStringValue:[[[NSAttributedString alloc] initWithString:str attributes:statusBarAttributes] autorelease]];
}

// --- Accessors ---

- (NSString *)lastLineReceived {return lastLineReceived;}
- (void)setLastLineReceived:(NSString *)str {
  [lastLineReceived autorelease];
  lastLineReceived = [str retain];
  [delegate terminalPaneSummaryTitleDidChange:self];
}

- (void)setInputPrompt:(NSAttributedString *)prompt {
  // FIXME: shouldn't be poking at delegate's EIM, should have our own
  // fixme: could be more efficient, doing only one replace
  NSTextStorage *const storage = [mainTextView textStorage];
  if (promptExistsInOutput) {
    unsigned oldPromptLen = [self lengthOfInputSectionInTextStorage];
    [storage deleteCharactersInRange:NSMakeRange([storage length] - oldPromptLen, oldPromptLen)];
    promptExistsInOutput = NO;
  }
  
  if (prompt && [[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"InputPromptInOutput"]] intValue] && [prompt length]) {
    NSMutableAttributedString *oPrompt = [[prompt mutableCopy] autorelease];
    [oPrompt insertAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease] atIndex:0];
    [self adjustAttributedString:oPrompt];
    [storage appendAttributedString:oPrompt];
    promptExistsInOutput = YES;
  }
  
  [super setInputPrompt:prompt];
}

- (NSDictionary *)defaultOutputAttributes {return defaultOutputAttributes;}
- (NSParagraphStyle *)defaultParagraphStyle {return defaultParagraphStyle;}
- (void)setDefaultOutputAttributes:(NSDictionary *)dict {
  [defaultOutputAttributes autorelease];
  defaultOutputAttributes = [dict retain];
  
  [defaultParagraphStyle autorelease];
  defaultParagraphStyle = [[dict objectForKey:NSParagraphStyleAttributeName] retain];
}


@end
