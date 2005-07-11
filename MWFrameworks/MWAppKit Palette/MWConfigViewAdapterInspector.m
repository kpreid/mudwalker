/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigViewAdapterInspector.h"

#import <MudWalker/MudWalker.h>
#import <MWAppKit/MWConfigViewAdapter.h>

@implementation MWConfigViewAdapterInspector

- init {
  if (!(self = [super init])) return nil;
  
  [NSBundle loadNibNamed:@"MWConfigViewAdapterInspectorNib" owner:self];
  
  return self;
}

- (void)ok:(id)sender {
  MWConfigViewAdapter *editedObject = [self object];

  [self beginUndoGrouping];
  [self noteAttributesWillChangeForObject:editedObject];
  
  [editedObject setBasePath:[baseNilSwitch state] ? nil : [MWConfigPath pathWithStringRepresentation:[basePathField stringValue]] discard:YES];
  [editedObject setRelativePath:[relativeNilSwitch state] ? nil : [MWConfigPath pathWithStringRepresentation:[relativePathField stringValue]] discard:YES];

  if ([[self object] respondsToSelector:@selector(setWritesAttributed:)])
    [[self object] setWritesAttributed:[writesAttributedSwitch state]];
  if ([[self object] respondsToSelector:@selector(setUsesUnsignedNumbers:)])
    [[self object] setUsesUnsignedNumbers:[unsignedSwitch state]];

  [super ok:sender];
}

- (void)revert:(id)sender {
  BOOL responds;

  [basePathField setStringValue:MWForceToString([[(MWConfigViewAdapter *)[self object] basePath] stringRepresentation])];
  [relativePathField setStringValue:MWForceToString([[(MWConfigViewAdapter *)[self object] relativePath] stringRepresentation])];
  [baseNilSwitch setState:![(MWConfigViewAdapter *)[self object] basePath]];
  [relativeNilSwitch setState:![(MWConfigViewAdapter *)[self object] relativePath]];
  [basePathField setEnabled:![baseNilSwitch state]];
  [relativePathField setEnabled:![relativeNilSwitch state]];

  [writesAttributedSwitch setEnabled:responds = [[self object] respondsToSelector:@selector(setWritesAttributed:)]];
  [writesAttributedSwitch setState:responds ? [[self object] writesAttributed] : 0];

  [unsignedSwitch setEnabled:responds = [[self object] respondsToSelector:@selector(setUsesUnsignedNumbers:)]];
  [unsignedSwitch setState:responds ? [[self object] usesUnsignedNumbers] : 0];

  [super revert:sender];
}

@end

@implementation MWConfigViewAdapter (IBProtocol)

- (NSString *)inspectorClassName {
  return @"MWConfigViewAdapterInspector";
}

- (NSString *)nibLabel:(NSString *)objectName {
  return [
    NSString
    stringWithFormat:@"%@ (%@, %@)",
    [[self class] description],
    [[self basePath] stringRepresentation],
    [[self relativePath] stringRepresentation]
  ];
}

- (NSSize)minimumFrameSizeFromKnobPosition:(IBKnobPosition)position {
  return NSMakeSize(10, 10);
}
- (NSSize)maximumFrameSizeFromKnobPosition:(IBKnobPosition)position {
  return NSMakeSize(10, 10);
}

@end
