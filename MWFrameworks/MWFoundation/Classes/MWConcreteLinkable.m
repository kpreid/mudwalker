/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWConcreteLinkable.h"

#import "MWConfigSupplier.h"
#import "MWUtilities.h"
#import "MWConstants.h"
#import "MWLineString.h"

static unsigned int nextSmallID = 1;

@implementation MWConcreteLinkable

- (MWConcreteLinkable *)init {
  if (!(self = (MWConcreteLinkable *)[super init])) return nil;
  
  smallID = nextSmallID++;
  links = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:config];
  [self unlinkAll];
  [links autorelease]; links = nil;
  [config autorelease]; config = nil;
  [super dealloc];
}

- (NSSet*)linkNames { return [NSSet setWithObjects:@"outward", @"inward", nil]; }

// If any of the links specified here are not present, then the object will be pruned
- (NSSet*)linksRequired { return [NSSet setWithObjects:@"outward", @"inward", nil]; }

- (NSDictionary *)links { return links; }

- (void)registerLink:(MWLink *)link forName:(NSString *)linkName {
  [links setObject:link forKey:linkName];
}

- (void)unregisterLinkFor:(NSString *)linkName {
  [links removeObjectForKey:linkName];
}

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  return NO;
}

- (void)linkPrune {
  NSDictionary *existantLinks = [self links];
  NSEnumerator *e = [[self linksRequired] objectEnumerator];
  NSString *linkName;
  BOOL missing = NO;
  while ((linkName = [e nextObject])) {
    if (![existantLinks objectForKey:linkName]) {
      MWLinkLog(@"%@: %@ missing", self, linkName);
      missing = YES;
      break;
    }
    MWLinkLog(@"%@: %@ present", self, linkName);
  }
  if (missing) {
    [self unlinkAll];
    MWLinkLog(@"%@: pruned", self);
  }
}

- (void)setConfig:(id <MWConfigSupplier>)newConfig {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:config];
  [config autorelease];
  
  config = [newConfig retain];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:MWConfigSupplierChangedNotification object:config];
  [self configChanged:[NSNotification notificationWithName:MWConfigSupplierChangedNotification object:config userInfo:nil]];
}  

- (id <MWConfigSupplier>)config { return config; };

- (void)configChanged:(NSNotification *)notif {}


// Convenience method
- (void)localMessage:(NSString *)str {
  [self send:[MWLineString lineStringWithString:str role:MWLocalRole] toLinkFor:@"inward"];
}
- (void)localIzedMessage:(NSString *)str {
  [self localMessage:MWLocalizedStringHere(str)];
}


- (unsigned int)smallID { return smallID; }

- (NSString *)linkableUserDescription { return [NSString stringWithFormat:@"%@ #%u", MWLocalizedStringHere([[self class] description]), [self smallID]]; }

@end
