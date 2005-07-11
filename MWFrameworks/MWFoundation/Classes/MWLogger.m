/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWLogger.h"

#import "MWLineString.h"
#import "MWConfigPath.h"
#import "MWConfigTree.h"

@interface MWLogger (Private)

- (void)closeLog;

@end

@implementation MWLogger

- (void)dealloc {
  [fileName release]; fileName = nil;
  [self closeLog];
  [super dealloc];
}

- (void)writeString:(NSString *)line {
  [fileHandle writeData:[line dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
}

// We have no required links, therefore we will never be pruned.
- (NSSet *)linkNames { return [NSSet setWithArray:[[self links] allKeys]]; }
- (NSSet *)linksRequired { return [NSSet set]; }

- (BOOL)receive:(id)obj fromLinkFor:(NSString *)link {
  NSString *type;
  if ([obj isKindOfClass:[NSString class]]) {
    type = @"s";
  } else if ([obj isKindOfClass:[MWLineString class]]) {
    obj = [obj string];
    type = @":";
  } else {
    type = @" ";
  }

  {
    NSString *line = [NSString stringWithFormat:@"%@ :%@: %@\n", link, type, [obj description]];
    [self writeString:line];
  }
  return YES;
}



- (void)closeLog {
  [self writeString:[NSString stringWithFormat:@"--- Ending log file (%@) (pid %u)\n", [self linkableUserDescription], [[NSProcessInfo processInfo] processIdentifier]]];
  [fileHandle closeFile];
  [fileHandle release]; fileHandle = nil;
}

- (void)setDestinationFile:(NSString *)name {
  if (fileName && name && [fileName isEqualToString:name]) return;
  
  if (fileHandle) [self closeLog];
    
  [fileName autorelease];
  fileName = [name retain];
  
  if (fileName) {
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir]) {
      // FIXME: better error checking all over here
      [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    } else if (isDir) {
      [NSException raise:NSInvalidArgumentException format:@"Log file path is occupied by a directory!"];
    }
    fileHandle = [[NSFileHandle fileHandleForWritingAtPath:fileName] retain];
    [fileHandle seekToEndOfFile];
    [self writeString:[NSString stringWithFormat:@"--- Starting log file (%@) (pid %u)\n", [self linkableUserDescription], [[NSProcessInfo processInfo] processIdentifier]]];
  }
}

// --- Configuration ---

- (void)configChanged:(NSNotification *)notif {
  [super configChanged:notif];
  
  [self setDestinationFile:[[notif object] objectAtPath:[MWConfigPath pathWithComponent:@"LogFileName"]]];
}
@end
