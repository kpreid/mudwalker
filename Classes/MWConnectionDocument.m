/*\  
 * MudWalker Source
 * Copyright 2001-2003 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConnectionDocument.h"

#import <MudWalker/MudWalker.h>
#import <CoreFoundation/CoreFoundation.h>

#import "MWOutputWinController.h"
#import "MWDocumentSettingsWinController.h"
#import "MWTextOutputWinController.h"
#import "MWAddressEntryWinController.h"
#import "MWAppDelegate.h"
#import "MWMudLibrary.h"
#import "MWColorConverter.h"

@implementation MWConnectionDocument

NSString *MWConnectionDocument_Type = @"org.cubik.mudwalker.document.connection"; // must be same as Info.plist entry
static NSString *myDocumentClassKey = @"Class";
static NSString *myDocumentVersionKey = @"Version";
static NSString *myDocumentConfigKey = @"Config";
static const int currentDocumentVersion = 1;

// --- Standard document stuff ------------------------------

- (MWConnectionDocument *)init {
  if (!(self = [super init])) return nil;

  config = [[MWConfigTree allocWithZone:[self zone]] init];
  [config setUndoManager:[self undoManager]];
  configStack = [[MWConfigStacker allocWithZone:[self zone]] initWithSuppliers:config :[[MWRegistry defaultRegistry] config]];

  windowFrameIdentifiersUsed = [[NSMutableSet allocWithZone:[self zone]] init];
  
  scriptContexts = [[MWScriptContexts allocWithZone:[self zone]] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openScriptDebugWindow:) name:MWScriptContextsWillSendDebugMessageNotification object:scriptContexts];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:configStack];
    
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:configStack];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWScriptContextsWillSendDebugMessageNotification object:scriptContexts];
  [config autorelease]; config = nil;
  [configStack autorelease]; configStack = nil;
  [windowFrameIdentifiersUsed autorelease]; windowFrameIdentifiersUsed = nil;
  [scriptContexts autorelease]; scriptContexts = nil;
  [super dealloc];
}

- (void)makeWindowControllers {
  // NOTE: makeWindowControllers is, annoyingly, called as a consequence of -[NSDocumentController openUntitledDocumentOfType:display:] even if display: is NO - and we want to allow documents to be created, configured, then displayed...so we delay makeWindowControllers.
  // FIXME: this does a few bad things - instead let's have a stub window controller that replaces itself later

  [self performSelector:@selector(mwRealMakeWindowControllers) withObject:nil afterDelay:0];
}

- (void)mwRealMakeWindowControllers {

  if ([self defaultOutputWindowClass]) {
  
    [self outputWindowOfClass:nil group:@"main" reuse:NO connect:[(NSNumber *)[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"AutoConnect"]] intValue] display:YES];
    
  } else if ([self fileName]) {
    [self mwOpenDocumentSettings:self];
  } else {
    NSWindowController *aec = [[MWAddressEntryWinController allocWithZone:[self zone]] init];
    [self addWindowController:aec];
    [aec showWindow:nil];
  }
}

// --- Config ---

- (void)configChanged:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];


  // FIXME: library ought to know itself what keys it cares about
  if ((!path
    || [path isEqual:[MWConfigPath pathWithComponents:@"Address", nil]]
    || [path isEqual:[MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil]]
  )) {
    [[(MWAppDelegate *)[NSApp delegate] mudLibrary] noticeDocument:self];
  }

  if ((!path || [path isEqual:[MWConfigPath pathWithComponent:@"Address"]]) && ![self fileName]) {
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
  }
}

// --- Saving/loading ---

- (void)setFileName:(NSString *)fileName {
  [super setFileName:fileName];
  [[(MWAppDelegate *)[NSApp delegate] mudLibrary] noticeDocument:self];
}

- (void)modernizeScript:(MWConfigPath *)oldPath to:(MWConfigPath *)newPath {
  if ([config objectAtPath:oldPath] && ![config objectAtPath:newPath]) {
    NSMutableString *const scriptText = [[[(NSAttributedString *)[config objectAtPath:oldPath] string] mutableCopy] autorelease];
    
    [scriptText replaceOccurrencesOfString:@"$(" withString:@"$('$(')$" options:0 range:NSMakeRange(0, [scriptText length])];
    [scriptText replaceOccurrencesOfString:@"$$" withString:@"$('$$')$" options:0 range:NSMakeRange(0, [scriptText length])];
    [scriptText replaceOccurrencesOfString:@"<username>" withString:@"$(username)$" options:0 range:NSMakeRange(0, [scriptText length])];
    [scriptText replaceOccurrencesOfString:@"<password>" withString:@"$(password)$" options:0 range:NSMakeRange(0, [scriptText length])];
    [scriptText replaceOccurrencesOfString:@"<gt>" withString:@">" options:0 range:NSMakeRange(0, [scriptText length])];
    [scriptText replaceOccurrencesOfString:@"<lt>" withString:@"<" options:0 range:NSMakeRange(0, [scriptText length])];
    
    [config removeItemAtPath:oldPath recurse:NO];
    [config setObject:[[[MWScript alloc] initWithSource:scriptText languageIdentifier:@"SubstitutedLua"] autorelease] atPath:newPath];
  }
}

- (void)modernizeScript:(MWConfigPath *)scriptPath {
  [self modernizeScript:scriptPath to:scriptPath];
}

- (void)modernizeConfig {
  [[self undoManager] disableUndoRegistration];
  // fixme: hooks for plugins to do their own modernization?

  if ([config objectAtPath:[MWConfigPath pathWithComponent:@"ColorBrightColor"]]) {
    // No longer implemented
    [config removeItemAtPath:[MWConfigPath pathWithComponent:@"ColorBrightColor"] recurse:NO];
  }
  
  if ([config objectAtPath:[MWConfigPath pathWithComponent:@"Colors"]] && ![config objectAtPath:[MWConfigPath pathWithComponent:@"ColorSets"]]) {

    // make a color set out of the old colors
    [config addDirectoryAtPath:[MWConfigPath pathWithComponents:@"ColorSets", @"custom", nil] recurse:YES insertIndex:-1];
    [config setObject:[[self displayName] stringByAppendingString:NSLocalizedString(@"ColorsModernizationColorSetNameSuffix", nil)] atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"custom", @"Name", nil]];
    
    [config setObject:MWColorDictionaryFromArray([config objectAtPath:[MWConfigPath pathWithComponent:@"Colors"]]) atPath:[MWConfigPath pathWithComponents:@"ColorSets", @"custom", @"ColorDictionary", nil]];

    // make that color set in use
    [config setObject:@"custom" atPath:[MWConfigPath pathWithComponents:@"SelectedColorSet", nil]];
    
    // remove old colors
    [config removeItemAtPath:[MWConfigPath pathWithComponent:@"Colors"] recurse:NO];
  }
  
  [self
    modernizeScript:[MWConfigPath pathWithComponent:@"MWConfigureLoginScript"]
    to:[MWConfigPath pathWithComponent:@"LoginScript"]];
  [self 
    modernizeScript:[MWConfigPath pathWithComponent:@"MWConfigureLogoutScript"]
    to:[MWConfigPath pathWithComponent:@"LogoutScript"]];
  
  MWenumerate([[config allKeysAtPath:[MWConfigPath pathWithComponent:@"Triggers"]] objectEnumerator], NSString *, dirKey) {
    [self modernizeScript:[MWConfigPath pathWithComponents:@"Triggers", dirKey, @"doCommandLink_command", nil]];
    [self modernizeScript:[MWConfigPath pathWithComponents:@"Triggers", dirKey, @"doChannel_name", nil]];
    [self modernizeScript:[MWConfigPath pathWithComponents:@"Triggers", dirKey, @"doSubstitute_replacement", nil]];
  }
  
  [[self undoManager] enableUndoRegistration];
}

- (NSDictionary *)documentIntoDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObject:NSStringFromClass([self class]) forKey:myDocumentClassKey];
  [dict setObject:[NSString stringWithFormat:@"%d", currentDocumentVersion] forKey:myDocumentVersionKey];
  [dict setObject:[[config copy] autorelease] forKey:myDocumentConfigKey];
  return dict;
}

- (void)documentFromDictionary:(NSDictionary *)dict {
  if ([dict objectForKey:myDocumentConfigKey]) {
    [[self undoManager] disableUndoRegistration];
    [[self configLocalStore] setConfig:[dict objectForKey:myDocumentConfigKey]];
    [self modernizeConfig];
    [[self undoManager] enableUndoRegistration];
  }
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
  if ([type isEqualToString:MWConnectionDocument_Type]) {
    return [NSArchiver archivedDataWithRootObject:[self documentIntoDictionary]];
  } else {
    return nil;
  }
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
  if ([type isEqualToString:MWConnectionDocument_Type]) {
    NSDictionary *dict = nil;    
    if ((dict = [NSUnarchiver unarchiveObjectWithData:data])) {
      [self documentFromDictionary:dict];
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

// --- Scripting & key-value coding ---

- (id)valueForKey:(NSString *)key {
  NSLog(@"%@ valueForKey:%@", self, key);
  if ([key isEqual:@"terminals"]) {
    NSMutableArray *terms = [NSMutableArray array];
    NSEnumerator *wcE = [[self windowControllers] objectEnumerator];
    NSWindowController  *wc;
    while ((wc = [wcE nextObject])) {
      if ([wc conformsToProtocol:@protocol(MWOutputWinController)])
        [terms addObject:wc];
    }
    NSLog(@"Returning %@ for terminals\n", terms);
    return [[terms copy] autorelease];

  } else
    return [super valueForKey:key];
}

//- (void)takeValue:(id)newVal forKey:(NSString *)key {
//}

// --- Misc stuff ---

- (void)openScriptDebugWindow:(NSNotification *)notif {
  if (![[scriptContexts links] objectForKey:@"debug"]) {
    id const tw = [self outputWindowOfClass:[MWTextOutputWinController class] group:@"Script Debug" reuse:NO connect:NO display:NO];
    
    [tw link:@"outward" to:@"debug" of:scriptContexts];
    [tw showWindow:nil];
  }
}

- (NSString *)displayName {
  NSString *adr;
  if (![self fileName] && [(adr = [(NSURL *)[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]] absoluteString]) length])
    return adr;
  else
    return [[super displayName] stringByDeletingPathExtension];
}

- (IBAction)mwNewTerminal:(id)sender {
  [self outputWindowOfClass:nil group:@"main" reuse:NO connect:NO display:YES];
}

- (IBAction)mwOpenDocumentSettings:(id)sender {
  if (!settingsWindow) {
    settingsWindow = [[MWDocumentSettingsWinController allocWithZone:[self zone]] init];
  }
  [self addWindowController:settingsWindow];
  [settingsWindow setDocument:self]; // long story
  [settingsWindow showWindow:sender];
}

- (IBAction)mwOpenConnection:(id)sender {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(mwRealMakeWindowControllers) object:nil];
  [self outputWindowOfClass:nil group:@"main" reuse:YES connect:YES display:YES];
}

- (IBAction)mwOpenServerInfo:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil]]];
}
- (IBAction)mwOpenServerHelp:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"HelpWebSite", nil]]];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
  SEL action = [item action];
  
  if (action == @selector(mwOpenServerInfo:)) {
    return !![[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"WebSite", nil]];

  } else if (action == @selector(mwOpenServerHelp:)) {
    return !![[self config] objectAtPath:[MWConfigPath pathWithComponents:@"ServerInfo", @"HelpWebSite", nil]];

  } else {
    return [super validateUserInterfaceItem:item];
  }
}

// --- Output window selection/creation and positioning ---

- (Class)defaultOutputWindowClass {
  NSString *scheme = [(NSURL *)[[self config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]] scheme];
  return [[[MWRegistry defaultRegistry] classForURLScheme:scheme] schemeDefaultOutputWindowClass:scheme];
}

- (NSWindowController <MWOutputWinController> *)outputWindowOfClass:(Class)theClass group:(NSString *)group reuse:(BOOL)reuse connect:(BOOL)connect display:(BOOL)display {
  NSWindowController <MWOutputWinController> *theWC = nil;
  NSString *scheme = [[self config] objectAtPath:[MWConfigPath pathWithComponent:@"Address"]];
  
  NSParameterAssert(theClass == nil || [theClass conformsToProtocol:@protocol(MWOutputWinController)]);
  
  if (!theClass) theClass = [[[MWRegistry defaultRegistry] classForURLScheme:scheme] schemeDefaultOutputWindowClass:(NSString *)scheme];
  if (!theClass) theClass = [MWTextOutputWinController class];
  
  if (reuse) {
    NSEnumerator *wcE = [[self windowControllers] objectEnumerator];
    NSWindowController <MWOutputWinController> *wc;
    while ((wc = [wcE nextObject])) {
      if ([wc isKindOfClass:theClass] && ![[wc links] count] && ((!group && ![wc outputWindowGroup]) || [[wc outputWindowGroup] isEqualToString:group])) {
        theWC = wc;
        break;
      }
    }
  }
  
  if (!theWC) {
    theWC = [[[theClass alloc] init] autorelease];
    [theWC setOutputWindowGroup:group];
    [self addWindowController:theWC];
  }

  if (display) [theWC showWindow:nil];
  if (connect) [theWC mwOpenConnection:nil];
  return theWC;
}

- (NSString *)acquireWindowFrameAutosaveNameWithPrefix:(NSString *)prefix {
  int i = 0;
  NSString *name;
  if (![self fileName]) return nil;
  // We do alloc/init instead of stringWith to avoid allocating lots of autoreleased objects
  while (
    [windowFrameIdentifiersUsed containsObject:
      name = [[NSString alloc] initWithFormat:@"%@ %@ Instance %i", [self fileName], prefix, i]
    ]
  ) {
    [name release];
    i++;
  }
  [windowFrameIdentifiersUsed addObject:name];
  return [name autorelease];
}

- (void)releaseWindowFrameAutosaveName:(NSString *)name {
  if (name) [windowFrameIdentifiersUsed removeObject:name];
}

// --- Accessors ---

- (id <MWConfigSupplier>)config { return configStack; }
- (MWConfigTree *)configLocalStore { return config; }

- (MWScriptContexts *)mwScriptContexts { return scriptContexts; }

@end
