/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>


@interface MWMCPMessage : NSDictionary {
  NSString *messageName;
  NSDictionary *arguments;
}

+ (MWMCPMessage *)messageWithName:(NSString *)name;
+ (MWMCPMessage *)messageWithName:(NSString *)name arguments:(NSDictionary *)args;
- (MWMCPMessage *)initWithMessageName:(NSString *)name arguments:(NSDictionary *)args;

- (NSString *)messageName;

- (NSString *)descriptionWithLocale:(NSDictionary *)locale;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level;

/* Returns the message name without its package name - for example, if the message is "dns-com-awns-serverinfo-get" and the package is "dns-com-awns-serverinfo", then "get" is returned. Returns nil if the message name does not begin with the package name. */
- (NSString *)messageNameWithoutPackageName:(NSString *)packageName;

- (NSArray *)linesForSendingWithAuthenticationKey:(NSString *)authKey;

@end
