/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>
#import "MWMudLibrary.h"

@interface MWLibraryAddressItem : NSObject <MWLibraryItem> {
  NSURL *address;
  NSMutableArray *documentItems;
  NSUserDefaults *userDefaults;
}

- (id)initWithAddress:(NSURL *)nadr userDefaults:(NSUserDefaults *)ud;

- (NSURL *)serverURL;

- (void)reloadData;

@end

@interface MWLibraryDocumentItem : NSObject <MWLibraryItem> {
  NSURL *address;
  NSURL *docURL;
  NSImage *docImage;
}

- (NSURL *)documentURL;

- (id)initWithDocumentURL:(NSURL *)url forAddress:(NSURL *)nadr;

@end
