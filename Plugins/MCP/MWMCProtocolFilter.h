/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <MudWalker/MudWalker.h>

@class MWMCPPackage, MWMCPMessage;

@interface MWMCProtocolFilter : MWConcreteLinkable <MWPlugin> {
  // If this is nil, then the server has not declared MCP support
  NSString *trueAuthKey;
  
  // Keys are data tags
  NSMutableDictionary *multilineMessageState;
  
  // Contains instantiations of all packages which the client and server support.
  NSMutableDictionary *packages;
  
  // message->package incoming lookup
  NSMutableDictionary *messages;
}

+ (void)registerPackage:(Class)package;

+ (NSMutableDictionary *)packageRegistry;

- (BOOL)mcpIsActive;
- (void)sendMCPMessage:(NSString *)name args:(NSDictionary *)args;
- (void)sendMCPMessage:(MWMCPMessage *)msg;

- (MWMCPPackage *)addPackage:(Class)packageClass;
- (NSDictionary *)mcpPackages;

- (NSString *)trueAuthKey;
- (void)setTrueAuthKey:(NSString *)key;

@end

