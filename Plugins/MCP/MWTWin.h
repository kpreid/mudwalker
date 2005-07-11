/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import <MudWalker/MWToken.h>

#define MWTWinInfinity 100000

#define TWIN_BOOLEAN_ATTR(s, default) ([attributes objectForKey:s] ? [[[attributes objectForKey:s] objectAtIndex:0] compare:@"TRUE" options:NSCaseInsensitiveSearch] == NSOrderedSame : default)

extern NSCharacterSet * MWTWinGetEscapeNeedingCharacters(void);
#define MWTWinEscapeNeedingCharacters (MWTWinGetEscapeNeedingCharacters())

extern NSDictionary * MWTWinGetWidgetData(void);
#define MWTWinWidgetData (MWTWinGetWidgetData())

@interface NSScanner (MWTWinAdditions)

- (BOOL)scanTWinSExprLeaf:(id *)into;
- (BOOL)scanTWinSExpressionIncludingType:(BOOL)includingType into:(id *)into;

@end

@interface NSArray (MWTWinAdditions)
- (NSString *)asTWinSExpression;
@end
@interface NSNumber (MWTWinAdditions)
- (NSString *)asTWinSExpression;
@end
@interface MWToken (MWTWinAdditions)
- (NSString *)asTWinSExpression;
@end

#define MWTWinSizeBit (1 << 0)
#define MWTWinStretchBit (1 << 1)
#define MWTWinShrinkBit (1 << 2)
#define MWTWinSizeErrorBit (1 << 3)
@interface NSString (MWTWinAdditions)

- (NSString *)asTWinSExpression;

- (int)getTWinSize:(float *)size stretch:(float *)stretch shrink:(float *)shrink;
 
@end
