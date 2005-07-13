/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

@class MWMCProtocolFilter, MWMCPMessage;

@interface MWMCPVersion : NSObject {
 @private
  int major, minor;
}

+ (MWMCPVersion *)bestVersionInRangeAMin:(MWMCPVersion *)aMin aMax:(MWMCPVersion *)aMax bMin:(MWMCPVersion *)bMin bMax:(MWMCPVersion *)bMax;

+ (id)versionWithString:(NSString *)strVers;
- (id)initWithString:(NSString *)strVers;

- (NSString *)description; // returns string form

- (NSComparisonResult)compare:(MWMCPVersion *)other;

- (int)majorVersion;
- (int)minorVersion;

@end

@interface MWMCPPackage : NSObject {
 @private
  MWMCProtocolFilter *owningFilter;
  void *MWMCPPackage_future1;
  void *MWMCPPackage_future2;
}

+ (Class)classForPackageVersion:(MWMCPVersion *)vers; // default just returns self - we'll have a version-class-naming scheme later

// subclass can override either init or initWithFilter:, both are always called.

- (id)initWithFilter:(MWMCProtocolFilter *)owner;

+ (NSArray *)packageNameComponents; // subclass override if your class isn't named normally
+ (NSString *)packageName;
- (NSString *)packageName;

- (BOOL)participatesInVersionNegotiation; // return NO if this is a special package like mcp or mcp-negotiate

- (void)handleIncomingMessage:(MWMCPMessage *)msg; // subclass override if you don't want to use the standard message dispatching scheme

- (BOOL)handleOutgoing:(id)obj alreadyHandled:(BOOL)already; // intercept outgoing objects (currently only tokens). return true to prevent obj from being passed outward. 'already' is true if another package's handleOutgoing:alreadyHandled: returned true. The default implementation just returns NO.

- (void)sendMCPMessage:(NSString *)msg args:(NSDictionary *)args; // forwards to filter

- (void)startPackage; // optional override - called when support is negotiated

- (MWMCProtocolFilter *)owningFilter;
- (void)owningFilterDroppedPackage;

@end

@interface MWMCPPackage (SubclassRequired)

+ (MWMCPVersion *)minVersion;
+ (MWMCPVersion *)maxVersion;
- (NSSet *)incomingMessages;

@end
