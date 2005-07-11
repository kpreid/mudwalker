/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface MWConfigViewAdapterInspector : IBInspector {
  IBOutlet NSTextField *basePathField;
  IBOutlet NSTextField *relativePathField;
  IBOutlet NSButton *baseNilSwitch;
  IBOutlet NSButton *relativeNilSwitch;
  IBOutlet NSButton *writesAttributedSwitch;
  IBOutlet NSButton *unsignedSwitch;
}
@end
