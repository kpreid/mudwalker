/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This NSApplication subclass simply adds a hook necessary for proper quit behavior. It should not be extended in any other way unless absolutely necessary.
\*/

#import <AppKit/AppKit.h>

@interface MWApplication : NSApplication

- (void)replyToApplicationMWPresaveHook:(BOOL)should;

@end

@interface NSObject (MWApplicationDelegate)
- (NSApplicationTerminateReply)applicationMWPresaveHook:(MWApplication *)sender;
@end
