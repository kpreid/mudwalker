/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import "MWMudLibrary.h"

@class MWLibraryCategory;

@interface MWLibraryEntry : NSObject <MWLibraryItem> {
  MWLibraryCategory *parent;
}

- (id)initWithCategory:(MWLibraryCategory *)category;

@end

@interface MWLibraryURLEntry : MWLibraryEntry {
  NSMutableDictionary *info;
}

- (id)initWithCategory:(MWLibraryCategory *)category info:(NSDictionary *)newInfo;
- (NSMutableDictionary *)infoDict;

- (NSURL *)serverURL;

@end

@interface MWLibraryDocumentEntry : MWLibraryEntry {
  NSURL *docURL;
  NSImage *docImage;
}

- (NSURL *)documentURL;

- (id)initWithCategory:(MWLibraryCategory *)category URL:(NSURL *)url;

@end
