/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import "MWCGMudMessage.h"

@interface MWCGMudMessage (Private)

- (void)prepareDataForm;
- (void)prepareParsedForm;

@end

@implementation MWCGMudMessage

+ (id)messageWithType:(uint8_t)Ptype key:(uint32_t)Pkey flag:(BOOL)Pflag uint:(uint16_t)Puint tail:(NSData *)Ptail {
  return [[self alloc] initWithType:Ptype key:Pkey flag:Pflag uint:Puint tail:Ptail];
}

+ (id)messageWithData:(NSData *)bytes {
  return [[self alloc] initWithData:bytes];
}

- (id)initWithType:(uint8_t)Ptype key:(uint32_t)Pkey flag:(BOOL)Pflag uint:(uint16_t)Puint tail:(NSData *)Ptail {
  if (!(self = [super init])) return nil;
  
  parsed = YES;
  parType = Ptype;
  parKey  = Pkey;
  parFlag = Pflag;
  parUint = Puint;
  parTail = [(Ptail ? Ptail : [NSData data]) retain];
  
  return self; 
}

- (id)initWithData:(NSData *)data {
  NSParameterAssert(data != nil);
  NSParameterAssert([data length] >= 10 + ntohs(*( (uint16_t *)[data bytes] )));
  if (!(self = [super init])) return nil;
  
  parsed = NO;
  dataForm = [data copyWithZone:[self zone]];
  
  return self; 
}

- (void)dealloc {
  [dataForm autorelease]; dataForm = nil;
  [parTail autorelease]; parTail = nil;
  [super dealloc];
}

- (void)prepareDataForm {
  if (dataForm) return;
  NSAssert(parsed, @"MWCGMudMessage with neither data nor parsed forms");

  {
    uint16_t netUsedLen = htons([parTail length]);
    uint32_t netKey     = htonl(parKey);
    uint8_t  netType    = parType;
    uint8_t  netFlag    = !!parFlag;
    uint16_t netUint    = htons(parUint);
    NSMutableData *buf = [NSMutableData dataWithCapacity:10 + [parTail length]];
   
    [buf appendBytes:&netUsedLen length:2];
    [buf appendBytes:&netKey     length:4];
    [buf appendBytes:&netType    length:1];
    [buf appendBytes:&netFlag    length:1];
    [buf appendBytes:&netUint    length:2];
    if (parTail) [buf appendData:parTail];
    dataForm = [buf copyWithZone:[self zone]];
  }
}

- (void)prepareParsedForm {
  if (parsed) return;
  NSAssert(dataForm, @"MWCGMudMessage with neither data nor parsed forms");
  {
    const char *bufBytes = [dataForm bytes];
    uint16_t usedLen   = ntohs(*( (uint16_t *)(bufBytes + 0) ));
    
    parsed = YES;
    parKey  = ntohl(*( (uint32_t *)(bufBytes + 2) ));
    parType =       *( (uint8_t  *)(bufBytes + 6) );
    parFlag =       *( (uint8_t  *)(bufBytes + 7) );
    parUint = ntohs(*( (uint16_t *)(bufBytes + 8) ));
    parTail = [[dataForm subdataWithRange:NSMakeRange(10, usedLen)] retain];
  }
}

- (size_t)messageLength { [self prepareParsedForm]; return 10 + [parTail length]; }

- (NSData *)data { [self prepareDataForm]; return dataForm; }
- (uint8_t )type { [self prepareParsedForm]; return parType; }
- (uint32_t)key  { [self prepareParsedForm]; return parKey ; }
- (BOOL    )flag { [self prepareParsedForm]; return parFlag; }
- (uint16_t)uint { [self prepareParsedForm]; return parUint; }
- (NSData *)tail { [self prepareParsedForm]; return parTail; }

@end
