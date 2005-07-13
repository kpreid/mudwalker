/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * Represents a CGMud message, and converts it between serialized form and individual components. 
 * Can be used to parse a stream, as excess data at the end will be ignored, and you can find the length of the message after parsing.
\*/

#import <Foundation/Foundation.h>

@interface MWCGMudMessage : NSObject {
  NSData *dataForm;
  
  BOOL parsed;
  
  uint8_t parType;
  uint32_t parKey;
  BOOL parFlag;
  uint16_t parUint;
  NSData *parTail;
}

+ (id)messageWithType:(uint8_t)Ptype key:(uint32_t)Pkey flag:(BOOL)Pflag uint:(uint16_t)Puint tail:(NSData *)Ptail;
+ (id)messageWithData:(NSData *)data;
- (id)initWithType:(uint8_t)Ptype key:(uint32_t)Pkey flag:(BOOL)Pflag uint:(uint16_t)Puint tail:(NSData *)Ptail;
- (id)initWithData:(NSData *)data;

// Returns the message's length in bytes. If the message was created from data, this is guaranteed to be the offset between this message and the next in a stream.
- (size_t)messageLength;

- (NSData *)data;
- (uint8_t )type;
- (uint32_t)key ;
- (BOOL    )flag;
- (uint16_t)uint;
- (NSData *)tail;

@end
