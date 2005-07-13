/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWLink.h"

@protocol MWHasConfig;

@interface MWConcreteLinkable : NSObject <MWLinkable, MWHasConfig> {
 @private
  unsigned int smallID;
  NSMutableDictionary *links;
  id <MWConfigSupplier> config;
}

- (NSSet *)linksRequired;
  /* Return the NSString names of each link this object SHOULD have. If, at autorelease time, any of these links do not exist, -unlinkAll will be invoked by -linkPrune. */
  /* By default, returns @"outward", @"inward". This is suitable for a filter. */

- (void)configChanged:(NSNotification *)notif;
  /* Called when the linkable's configuration object posts a MWConfigSupplierChangedNotification, and when the configuration is set. */

- (void)localMessage:(NSString *)str;
- (void)localIzedMessage:(NSString *)str;

- (unsigned int)smallID;

/* The -linkableUserDescription of this class looks for a localized string for the class name in the bundle in which the subclass is defined. */

@end
