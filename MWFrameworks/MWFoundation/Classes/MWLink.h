/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

/*
MWLinkable

Protocol for objects that participate in the IO chain. A typical chain might be:
  socket connection
        \/\
   telnet filter
        \/\
  encoding filter
        \/\
 ANSI color filter
        \/\
  display window
   
Each object in the chain implements MWLinkable, or isa MWLinkable, the filters having two links and the windows having one.

The reason for having a protocol is so that objects such as window controllers can have links.

MWLink

Object that implements a link. A link is like a TCP connection, in that it is identified by its endpoint objects and link names - for example:
  <MWConnection: 0xDCAB>:inward <-> <MWTelnetFilter: 0xF0E1>:outward
*/

@class MWLink; // forward declaration
@protocol MWConfigSupplier;

extern void MWLinkLog(NSString *format, ...);

@protocol MWLinkable <NSObject>
  
  // See also MWLinkableConvenience category, below
  
  - (NSSet *)linkNames;
  /* Return the NSString names of each link this object could have. Standard link names for filters, connections, and windows are @"outward" (to server) and @"inward" (to window). An object may allow or even itself create links with names not returned by this function. An object may change the set returned by this method at any time. */

  - (NSDictionary *)links;
  /* Return a dictionary of link objects. Should be O(1). */
  
  - (void)registerLink:(MWLink *)link forName:(NSString *)linkName;
  /* Attempt to add a link to the object. Will never be called if a link already exists for a name. Can throw exceptions safely. Should only be called by MWLink. */
  
  - (void)unregisterLinkFor:(NSString *)linkName;
  /* Opposite of registerLink:for:. Must handle being called with a non-linked link name. Should only be called by MWLink. */
  
  - (BOOL)receive:(id)obj fromLinkFor:(NSString *)linkName;
  /* Receive an object from a link. Usually, but not necessarily, called from a MWLink. Return value indicates whether the object+linkname was understood and handled - this is so that subclasses can call super's implementation and know whether it did something with it */
  
  //- (id)probe:(SEL)sel fromLinkFor:(NSString *)linkName;
  /* Used to retrieve information about the 'other end' of a link chain. Default behavior should be to pass the probe along the chain. */
  
  - (void)linkPrune;
  /* Since links are bidirectional, objects will not be deallocated by refcounting. This method is called at autorelease time by MWLinkPruner. It should call -unlinkAll if the object is not 'useful'  (e.g. a filter with only one side connected). */
    
  - (void)setConfig:(id <MWConfigSupplier>)newConfig;
  /* Set the configuration supplier for this linkable. */
  
  - (id <MWConfigSupplier>)config;
  /* Get configuration supplier */
  
  - (NSString *)linkableUserDescription;
  /* Return a localized string uniquely describing the object as it is known to the user */
  
@end

@interface NSObject (MWLinkableConvenience)

  - (MWLink *)link:(NSString *)linkName to:(NSString *)otherLinkName of:(id <MWLinkable>)target;
  /* Convenience method to make a MWLink. Returns same as MWLink -init. */

  - (void)unlink:(NSString *)linkName;
  /* Remove a link. Convenience method to call MWLink */

  - (void)unlinkAll;
  
  - (void)send:(id)obj toLinkFor:(NSString *)linkName;
  /* Send an object out this object's link. Usually not called except by self. */
  
  - (id)probe:(SEL)sel ofLinkFor:(NSString *)link;

  - (id)probe:(SEL)sel fromLinkFor:(NSString *)link;

  - (void)linkableTraceMessage:(NSString *)str;
  
  - (void)linkableErrorMessage:(NSString *)str;
  
@end

@interface MWLink : NSObject {
  @private id objA, objB;
  @private NSString *nameA, *nameB;
}

- (MWLink *)initWithObject:
         (id <MWLinkable>)objAp linkName:(NSString *)nameAp
  object:(id <MWLinkable>)objBp linkName:(NSString *)nameBp;
/* Create a link for a pair of objects and tell the objects about it. Returns nil if either object refused the link. */

+ (void)buildFilterChain:(NSArray *)filters config:(id <MWConfigSupplier>)config;
/* Create a chain of linked linkables using the standard link names 'inward' and 'outward'. The array should be ordered from the outermost to the innermost. setConfig:config will be called on all filters unless config is nil. */

- (void)unlink;
/* Disconnect the link. */

- (void)send:(id <NSObject>)obj from:(id <MWLinkable>)sender;
/* Call the object-which-isn't-sender's -receive:fromLinkFor: with  obj. */

- (id)probe:(SEL)sel from:(id <MWLinkable>)sender;
/* Call the object-which-isn't-sender's -probe:fromLinkFor: with sel. */

- (id <MWLinkable>)otherObject:(id <MWLinkable>)sender;
/* Return the other object of the link. */

@end

