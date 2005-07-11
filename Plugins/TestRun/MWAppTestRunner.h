/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import <ObjcUnit/ObjcUnit.h>

#import <MudWalker/MWPlugin.h>

@interface MWAppTestRunner : NSObject <MWPlugin>

+ (TestSuite *)suite;

@end
