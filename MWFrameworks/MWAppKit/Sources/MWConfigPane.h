/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 *
 * 
\*/

#import <PreferencePanes/PreferencePanes.h>
#import <MudWalker/MWConstants.h>
#import <MudWalker/MWRegistry.h>

@class MWConfigTree, MWConfigStacker;
@protocol MWConfigSupplier;

@interface NSPreferencePane (MWConfigPaneCompatibility)

- (id)initWithBundle:(NSBundle *)bundle mwConfigTarget:(MWConfigTree *)target configParent:(id <MWConfigSupplier>)parent;

+ (NSString *)displayName;

// Calls the class's displayName
- (NSString *)displayName;

@end

@interface MWConfigPane : NSPreferencePane {
 @private
  MWConfigTree *cpConfigTarget;
  id <MWConfigSupplier> cpConfigParent;
  MWConfigStacker *cpStack;
  void *cpFuture1;
  void *cpFuture2;
}

// Default is the name of the class plus "-paneTitle" fed through its bundle's Localizable.strings
// + (NSString *)displayName;
// - (NSString *)displayName;

// Instead of the default being "Main" as in NSPreferencePane, it is the name of the class.
- (NSString *)mainNibName;

// MWConfigPane automatically becomes a notification observer for its config tree with this selector. This will also be called on nib load with a nil argument.
- (void)configChanged:(NSNotification *)notif;

- (MWConfigTree *)configTarget;
- (id <MWConfigSupplier>)configParent;
- (id <MWConfigSupplier>)displaySupplier; // computed from other two

@end


@interface MWRegistry (MWConfigPane)

- (NSArray *)preferencePanesForScope:(MWConfigScope)scope;

- (void)registerPreferencePane:(Class)ppclass forScope:(MWConfigScope)scope;

@end

