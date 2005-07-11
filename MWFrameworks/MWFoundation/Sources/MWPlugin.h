/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

@class MWRegistry;
@protocol MWLinkable, MWConfigSupplier;

@protocol MWPlugin

  + (void)registerAsMWPlugin:(MWRegistry *)registry;

@end

// <grumble>
@interface NSObject (MWURLHandling)

  + (Class)schemeDefaultOutputWindowClass:(NSString *)scheme;
  - (Class)schemeDefaultOutputWindowClass:(NSString *)scheme;
  + (BOOL)schemeUsesStandardTextFilters:(NSString *)scheme;
  - (BOOL)schemeUsesStandardTextFilters:(NSString *)scheme;
  + (void)scheme:(NSString *)scheme buildFiltersForInnermost:(id <MWLinkable>)inner  config:(id <MWConfigSupplier>)config;
  - (void)scheme:(NSString *)scheme buildFiltersForInnermost:(id <MWLinkable>)inner  config:(id <MWConfigSupplier>)config;

@end
