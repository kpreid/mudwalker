/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * 
\*/

#import "MWConfigPane.h"

#import "MWConfigPath.h"
#import "MWConfigTree.h"
#import "MWConfigStacker.h"
#import "MWConstants.h"
#import "MWUtilities.h"

@implementation MWConfigPane

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent {
  if (!(self = [super initWithBundle:bundle])) return nil;
  
  cpConfigTarget = [target retain];
  cpConfigParent = [parent retain];
  cpStack = [[MWConfigStacker alloc] initWithSuppliers:cpConfigTarget :cpConfigParent];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:cpStack];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [cpConfigTarget release];
  [cpConfigParent release];
  [cpStack release];
  [super dealloc];
}

- (void)mainViewDidLoad {
  [super mainViewDidLoad];
  [self configChanged:[NSNotification notificationWithName:MWConfigSupplierChangedNotification object:cpStack]];
}

+ (NSString *)displayName {
  NSString *key = [[self description] stringByAppendingString:@"-paneTitle"];
  //NSLog(@"self %@, bundle %@, key %@, loc %@", self, [NSBundle bundleForClass:[self class]], key, MWLocalizedStringHere(key));
  return MWLocalizedStringHere(key);
}

- (NSString *)mainNibName { return [[self class] description]; }

- (void)configChanged:(NSNotification *)notif { }

- (MWConfigTree *)configTarget { return cpConfigTarget; }
- (id <MWConfigSupplier>)configParent { return cpConfigParent; }
- (id <MWConfigSupplier>)displaySupplier { return cpStack; }

@end

@implementation NSPreferencePane (MWConfigPaneCompatibility)

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)configParent {
  return [self initWithBundle:bundle];
}

+ (NSString *)displayName {
  NSBundle *myBundle = [NSBundle bundleForClass:self];
#ifdef NSFoundationVersionNumber10_2
  if ([myBundle respondsToSelector:@selector(localizedInfoDictionary)])
    return [[myBundle localizedInfoDictionary] objectForKey:@"CFBundleName"];
  else
#endif
    return [[[myBundle bundlePath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)displayName {
  return [[self class] displayName];
}

@end

@implementation MWRegistry (MWConfigPane)

static int paneSort(id a, id b, void *context) {
  return [[a displayName] compare: [b displayName]];
}

- (NSArray *)preferencePanesForScope:(MWConfigScope)scope {
  NSMutableArray *result = [NSMutableArray array];
  
  MWenumerate([[self allHandlersAndQualifiersForCapability:@"MWPreferencePaneClassForConfig"] objectEnumerator], NSDictionary *, info) {
    if (scope & [[[info objectForKey:@"qualifiers"] objectForKey:@"scope"] unsignedIntValue]) {
      [result addObject:[info objectForKey:@"handler"]];
    }
  }
  
  [result sortUsingFunction:paneSort context:nil];
  return result;
}

- (void)registerPreferencePane:(Class)ppclass forScope:(MWConfigScope)scope {
  [self registerCapability:@"MWPreferencePaneClassForConfig" qualifiers:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:scope] forKey:@"scope"] handler:ppclass];
}


@end
