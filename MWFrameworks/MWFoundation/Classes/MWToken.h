/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * MWToken serves two purposes:
 *   Passed thru links, it is a message which has no general significance, only "this happened" regarding its particular value.
 *   It also serves as a 'symbol' data type for interactions with systems that have such a concept, e.g. TWin.
\*/

#import <Foundation/Foundation.h>

#define MWTokenPingSend [MWToken token:@"MWTokenPingSend"]
#define MWTokenPingBack [MWToken token:@"MWTokenPingBack"]
#define MWTokenPingCant [MWToken token:@"MWTokenPingCant"]
#define MWTokenConnectionOpened [MWToken token:@"MWTokenConnectionOpened"]
#define MWTokenConnectionClosed [MWToken token:@"MWTokenConnectionClosed"]
#define MWTokenOpenConnection [MWToken token:@"MWTokenOpenConnection"]
#define MWTokenCloseConnection [MWToken token:@"MWTokenCloseConnection"]
#define MWTokenLogoutConnection [MWToken token:@"MWTokenLogoutConnection"]
#define MWTokenWindowSizeChanged [MWToken token:@"MWTokenWindowSizeChanged"]
#define MWTokenGUIShrinkwrap [MWToken token:@"MWTokenGUIShrinkwrap"]

@interface MWToken : NSObject {
  NSString *tokenName;
}

+ (MWToken *)token:(NSString *)n;
- (MWToken *)initWithName:(NSString *)n;
- (NSString *)name;

@end
