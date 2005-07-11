/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This plugin embeds a Python interpreter in MudWalker.
\*/

#import <Foundation/Foundation.h>
#import <MudWalker/MudWalker.h>

@interface MWPythonInterpreter : NSObject <MWPlugin, MWInterpreter> {

}

+ (MWPythonInterpreter *)sharedInterpreter;

@end
