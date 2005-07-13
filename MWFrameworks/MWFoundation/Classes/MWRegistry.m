/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWRegistry.h"

#import "MWPlugin.h"
#import "MWConfigTree.h"
#import "MWConfigStacker.h"
#import "MWIdentityLanguage.h"

static MWRegistry *theDefaultRegistry = nil;
static BOOL automaticRegistry = NO;
static BOOL doneDefaultsRegistration = NO;

@implementation MWRegistry

+ (id)defaultRegistry {
  if (!theDefaultRegistry) {
    [self createDefaultRegistry];
    automaticRegistry = YES;
  }
  return theDefaultRegistry;
}

+ (void)setDefaultRegistry:(MWRegistry *)newVal {
  if (automaticRegistry) {
    if (newVal) {
      //NSLog(@"Warning: %@ was automatically created and is now being replaced with %@", theDefaultRegistry, newVal);
    } else {
      automaticRegistry = NO;
    }
  }
  [theDefaultRegistry autorelease];
  theDefaultRegistry = [newVal retain];
}

+ (void)createDefaultRegistry {
  [self setDefaultRegistry:[[self alloc] init]];
}

+ (void)registerUserDefaults {
  if (doneDefaultsRegistration)
    return;
  //NSLog(@"Registering MWFoundation defaults");
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    @"BaseIdentity", @"MWDefaultScriptLanguageIdentifier",
    nil
  ]];
  doneDefaultsRegistration = YES;
}

// --- Creation ---

- (MWRegistry *)init {
  if (!(self = [super init])) return nil;

  [[self class] registerUserDefaults];

  schemeHandlingClasses = [[NSMutableDictionary allocWithZone:[self zone]] init];
  exceptionReporters = [[NSMutableSet allocWithZone:[self zone]] init];
  capabilities = [[NSMutableDictionary allocWithZone:[self zone]] init];
  uiCommandsByContext = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  defaultConfig = [[MWConfigTree allocWithZone:[self zone]] init];
  userConfig = [[MWConfigTree allocWithZone:[self zone]] init];
  configStack = [[MWConfigStacker allocWithZone:[self zone]] initWithSuppliers:userConfig :defaultConfig];

  NSData *storedConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"MWUserConfigArchive"];
  if (storedConfig) {
    MWConfigTree *storedTree = [NSUnarchiver unarchiveObjectWithData:storedConfig];
    if (storedTree)
      [userConfig setConfig:storedTree];
    else
      NSLog(@"Could not load user config archive from defaults key MWUserConfigArchive!");
  }
  
  [self registerScriptLanguage:[[[MWIdentityLanguage alloc] init] autorelease]];
  
  return self;
}

- (void)dealloc {
  [schemeHandlingClasses autorelease]; schemeHandlingClasses = nil;
  [exceptionReporters autorelease]; exceptionReporters = nil;
  [capabilities autorelease]; capabilities = nil;
  [uiCommandsByContext autorelease]; uiCommandsByContext = nil;
  [defaultConfig autorelease]; defaultConfig = nil;
  [userConfig autorelease];userConfig  = nil;
  [configStack autorelease]; configStack = nil;
  [super dealloc];
}


// --- Config ---

- (MWConfigTree *)defaultConfig {
  return defaultConfig;
}
- (MWConfigTree *)userConfig {
  return userConfig;
}
- (id <MWConfigSupplier>)config {
  return configStack;
}

- (void)saveConfig {
  [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:userConfig] forKey:@"MWUserConfigArchive"];
}

// --- Search paths ---

- (NSArray *)searchPaths {
  static NSArray *paths = nil;
  
  if (!paths) {
    NSEnumerator *libraries = [NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory, NSAllDomainsMask, YES) objectEnumerator];
    NSMutableArray *temp = [NSMutableArray array];
    NSString *lp;
    while ((lp = [libraries nextObject])) {
      [temp addObject:[lp stringByAppendingPathComponent:[NSString pathWithComponents:[NSArray arrayWithObjects:@"Application Support", @"MudWalker", @"", nil]]]];
    }
    [temp addObject:[[NSBundle mainBundle] resourcePath]];
    paths = [temp copy]; // retained
  }
  return paths;
}

- (NSString *)pathForResourceFromSearchPath:(NSString *)name {
  NSEnumerator *spE = [[self searchPaths] objectEnumerator];
  NSString *sp;
  
  NSLog(@"Searching for '%@'", name);
  { // Security check
    // FIXME!! A more OS-independent and secure check would be to resolve it to an absolute path, then make sure it starts in the right directory.
    NSEnumerator *pcE = [[name pathComponents] objectEnumerator];
    NSString *pc;
    while ((pc = [pcE nextObject])) {
      if ([pc hasPrefix:@"."]) {
        // FIXME: tell the user about this if this is a GUI app.
        NSLog(@"Path '%@' failed security check", name);
        return nil;
      }
    }
  }
  
  while ((sp = [spE nextObject])) {
    NSString *fp = [sp stringByAppendingPathComponent:name];
    //NSLog(@"Trying %@", fp);
    if ([[NSFileManager defaultManager] fileExistsAtPath:fp]) {
      NSLog(@"Returning %@", fp);
      return fp;
    }
  }
  NSLog(@"Returning failure");
  return nil;
}

// --- Plugin loding and registration ---

- (void)loadPlugins {
  NSEnumerator *pathE = [[NSArray arrayWithObjects:
    // FIXME: use standard search path
    @"~/Library/Application Support/MudWalker/PlugIns",
    @"/Library/Application Support/MudWalker/PlugIns",
    [[NSBundle mainBundle] builtInPlugInsPath],
    nil
  ] objectEnumerator];
  NSString *dirPath;
  
  while ((dirPath = [pathE nextObject])) {
    NSEnumerator *pE = [[NSFileManager defaultManager] enumeratorAtPath:[dirPath stringByExpandingTildeInPath]];
    NSString *pluginFilename = nil;
    while ((pluginFilename = [pE nextObject])) {
      NSString *pluginFullPath = [dirPath stringByAppendingPathComponent:pluginFilename];
      if ([[pluginFullPath pathExtension] isEqualToString:@"mwplug"]) {
        NS_DURING
          [[MWRegistry defaultRegistry] loadPlugin:pluginFullPath];
        NS_HANDLER
          if ([[localException name] isEqualToString:NSInvalidArgumentException]) {
            NSLog(@"Failed to load plugin %@: %@", pluginFullPath, [localException reason]);
          } else {
            [localException raise];
          }
        NS_ENDHANDLER
      }
    }
  }  
}

- (void)registerPluginBundle:(NSBundle *)theBundle {
  [[theBundle principalClass] registerAsMWPlugin:self];
}

- (void)loadPlugin:(NSString *)path {
  NSBundle *pluginBundle = [NSBundle bundleWithPath:path];

  if (!pluginBundle)
    [NSException raise:NSInvalidArgumentException format:@"Could not open plugin bundle at path %@", path];

  if (![pluginBundle load])
    [NSException raise:NSInvalidArgumentException format:@"Could not load  code from plugin bundle at path %@", path];

  if (![[pluginBundle principalClass] conformsToProtocol:@protocol(MWPlugin)])
    [NSException raise:NSInvalidArgumentException format:@"Plugin bundle's principal class does not conform to MWPlugin: %@", path];
  
  [self registerPluginBundle:pluginBundle];
}

// --- Capability registration ---

- (void)registerClass:(Class)class forURLScheme:(NSString *)scheme {
  NSMutableSet *classSet = nil;
  if (!(classSet = [schemeHandlingClasses objectForKey:scheme])) {
    classSet = [NSMutableSet setWithCapacity:1];
    [schemeHandlingClasses setObject:classSet forKey:scheme];
  }
  [classSet addObject:class];
}

- (NSSet *)classesForURLScheme:(NSString *)scheme {
  return [[[schemeHandlingClasses objectForKey:scheme] copy] autorelease];
}
- (Class)classForURLScheme:(NSString *)scheme {
  return [[schemeHandlingClasses objectForKey:scheme] anyObject];
}

- (void)registerCapability:(id <NSObject,NSCopying>)capName qualifiers:(NSDictionary *)qualifiers handler:(id)handler {
  NSParameterAssert(capName != nil);
  NSParameterAssert(handler != nil);
  if (!qualifiers) qualifiers = [NSDictionary dictionary];
  {
    NSMutableSet *providers = [capabilities objectForKey:capName];
    if (!providers) {
      providers = [NSMutableSet set];
      [capabilities setObject:providers forKey:capName];
    }
    
    [providers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
      handler, @"handler",
      qualifiers, @"qualifiers",
      nil
    ]];
  }
}
- (id)handlerForCapability:(id <NSObject,NSCopying>)capName {
  return [[[capabilities objectForKey:capName] anyObject] objectForKey:@"handler"];
}
- (NSSet *)allHandlersForCapability:(id <NSObject,NSCopying>)capName {
  NSSet *capInfos = [capabilities objectForKey:capName];
  NSMutableSet *set = [NSMutableSet setWithCapacity:[capInfos count]];
  NSEnumerator *infoE = [capInfos objectEnumerator];
  NSDictionary *info;
  while ((info = [infoE nextObject]))
    [set addObject:[info objectForKey:@"handler"]];
  return [[set copy] autorelease];
}
- (NSSet *)allHandlersAndQualifiersForCapability:(id <NSObject,NSCopying>)capName {
  return [[[capabilities objectForKey:capName] copy] autorelease];
}

- (void)registerUserInterfaceCommand:(NSString *)name context:(NSString *)context handler:(id)handler performSelector:(SEL)pSel {
  NSMutableDictionary *info;
  NSDictionary *immutableInfo;
  NSParameterAssert(name != nil);
  NSParameterAssert(context != nil);
  NSParameterAssert(handler != nil);
  NSParameterAssert(pSel != 0);
    
  info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    name, @"name",
    handler, @"handler",
    context, @"context",
    NSStringFromSelector(pSel), @"performSelector",
    nil
  ];
  immutableInfo = [[info copy] autorelease];
    
  //[uiCommands setObject:immutableInfo forKey:name];
  
  {
    NSMutableSet *contextCmds = [uiCommandsByContext objectForKey:context];
    if (!contextCmds) {
      contextCmds = [NSMutableSet set];
      [uiCommandsByContext setObject:contextCmds forKey:context];
    }
    [contextCmds addObject:immutableInfo];
  }
}
- (NSSet *)userInterfaceCommandsForContext:(NSString *)context {
  return [uiCommandsByContext objectForKey:context];
}

// --- Exceptions ---

- (void)reportCaughtException:(NSException *)exception caughtBy:(id)by caughtFrom:(id)from caughtBecause:(NSString *)because {
  if ([exceptionReporters count]) {
    NS_DURING
      NSEnumerator *repE = [exceptionReporters objectEnumerator];
      id rep;
      while ((rep = [repE nextObject])) {
        [rep reportCaughtException:exception caughtBy:by caughtFrom:from caughtBecause:because];
      }
    NS_HANDLER
      NSLog(@"Exception in exception reporter: %@", [localException description]);
    NS_ENDHANDLER
  } else {
    NSLog(@"Exception caught: %@\n  Caught by: %@\n  Caught from: %@\n  Caught because: %@", [exception description], [by description], [from description], because);
  }
}

- (NSSet *)exceptionReporters { return exceptionReporters; }
- (void)registerExceptionReporter:(id)reporter {
  [exceptionReporters addObject:reporter];
}

@end
