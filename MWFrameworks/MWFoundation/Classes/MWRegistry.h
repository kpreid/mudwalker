/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWRegistry records the services provided by all bundles (e.g. plugins) loaded into the application.
 * It also handles searching for external resources in the standard search paths.
\*/

#import <Foundation/Foundation.h>

@class MWConfigTree, MWConfigStacker;
@protocol MWConfigSupplier;

@interface MWRegistry : NSObject {
 @private
  NSMutableDictionary *schemeHandlingClasses;
  NSMutableSet *exceptionReporters;
  NSMutableDictionary *capabilities;
  NSMutableDictionary *uiCommandsByContext;
  MWConfigTree *defaultConfig;
  MWConfigTree *userConfig;
  MWConfigStacker *configStack;
  void *MWRegistry_future1;
  void *MWRegistry_future2;
  void *MWRegistry_future3;
  void *MWRegistry_future4;
  void *MWRegistry_future5;
  void *MWRegistry_future6;
  void *MWRegistry_future7;
}

/* Add relevant entries to the registration domain in [NSUserDefaults standardUserDefaults]. */
+ (void)registerUserDefaults;

/* Get the default registry. Creates it if necessary. */
+ (id)defaultRegistry;

/* Set the default registry. */
+ (void)setDefaultRegistry:(MWRegistry *)newVal;

/* Create an object of this class and set it as the default registry. */
+ (void)createDefaultRegistry;

// --- Plugins ---

/* Load plugins found in the standard locations. */
- (void)loadPlugins;
/* Register a plugin and ask it to register its capabilities. */
- (void)registerPluginBundle:(NSBundle *)theBundle;
/* Load a plugin bundle and call -registerPluginBundle: */
- (void)loadPlugin:(NSString *)path;

// --- Config ---

- (MWConfigTree *)defaultConfig;
- (MWConfigTree *)userConfig;
- (id <MWConfigSupplier>)config;

/* Save current config to NSUserDefaults. */
- (void)saveConfig;

// --- Search path ---

- (NSArray *)searchPaths;
- (NSString *)pathForResourceFromSearchPath:(NSString *)name;

// --- Registration of capablities and such ---

- (void)registerClass:(Class)class forURLScheme:(NSString *)scheme;
- (NSSet *)classesForURLScheme:(NSString *)scheme;
- (Class)classForURLScheme:(NSString *)scheme;

/* Generic capabilities. API totally unspecified. capName may be any object usable as a dictionary key. */
- (void)registerCapability:(id <NSObject,NSCopying>)capName qualifiers:(NSDictionary *)qualifiers handler:(id)handler;
- (id)handlerForCapability:(id <NSObject,NSCopying>)capName;
- (NSSet *)allHandlersForCapability:(id <NSObject,NSCopying>)capName;
/* returns a dictionary with @"handler" and @"qualifiers" keys */
- (NSSet *)allHandlersAndQualifiersForCapability:(id <NSObject,NSCopying>)capName;

- (void)registerUserInterfaceCommand:(NSString *)name context:(NSString *)context handler:(id)handler performSelector:(SEL)pSel;
- (NSSet *)userInterfaceCommandsForContext:(NSString *)context;

// --- Exceptions ---

- (void)reportCaughtException:(NSException *)exception caughtBy:(id)by caughtFrom:(id)from caughtBecause:(NSString *)because;

- (NSSet *)exceptionReporters;
- (void)registerExceptionReporter:(id)reporter;

@end
