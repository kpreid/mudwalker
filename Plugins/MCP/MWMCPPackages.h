/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import <Foundation/Foundation.h>
#import "MWMCPPackage.h"

@class MWMCPMappingWinController;

@interface MWMCP_mcp : MWMCPPackage @end
@interface MWMCP_mcp_negotiate : MWMCPPackage {
  BOOL gotNegotiateEnd;
}
@end
@interface MWMCP_mcp_cord : MWMCPPackage {
  NSMutableSet *openCords;
  NSMutableDictionary *cordTypeRegistry;
}
- (NSSet *)openCords;
- (void)cordLinkWasClosed:(NSString *)linkName;
- (void)registerCordType:(NSString *)type handlerClass:(Class)class;

@end
@interface MWMCP_dns_com_awns_displayurl : MWMCPPackage @end
@interface MWMCP_dns_com_awns_jtext : MWMCPPackage @end
@interface MWMCP_dns_com_awns_ping : MWMCPPackage @end
@interface MWMCP_dns_com_awns_rehash : MWMCPPackage { NSMutableSet *rehashSet; } @end
@interface MWMCP_dns_com_awns_serverinfo : MWMCPPackage @end
@interface MWMCP_dns_com_awns_status : MWMCPPackage @end
@interface MWMCP_dns_com_awns_timezone : MWMCPPackage @end
@interface MWMCP_dns_com_awns_visual : MWMCPPackage {
  NSMutableDictionary *topoCache;
  NSString *location, *selfID;
  MWMCPMappingWinController *wc;
  NSRect extentRect;
  
  BOOL hasSeededPosition;
  
  NSTimer *autolayoutTimer;
  float autolayoutLastChange;
} 
- (void)clearMap;
- (NSMutableDictionary *)topoCache;
- (NSRect)extentRect;
- (NSString *)playerLocation;

- (void)visualStartAutolayout;
- (void)visualLayoutAllNodes;
- (void)visualLayoutNodes:(NSSet *)nodes;

@end

@interface MWMCP_dns_org_cubik_prompt : MWMCPPackage @end
@interface MWMCP_dns_org_mud_moo_simpleedit : MWMCPPackage @end
@interface MWMCP_dns_com_att_research_twin_window : MWMCPPackage @end

