/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWConfigViewAdapter.h"

#import <MudWalker/MWConstants.h>
#import <MudWalker/MWUtilities.h>
#import <MudWalker/MWConfigSupplier.h>
#import <MudWalker/MWConfigPath.h>
#import <MudWalker/MWConfigTree.h>
#import <MudWalker/MWScript.h>
#import "MWConfigPane.h"
#import "MWScriptPanelController.h"

enum {
  version1 = 1,
};
static const int currentVersion = version1;

@interface MWConfigViewAdapter (Private)

- (void)cvaUpdateToolTip;
- (void)cvaRecomputeControlEnabled;
- (void)blink:(NSColor *)color;

@end

@implementation MWConfigViewAdapter

+ (void)initialize {
  [self setVersion:currentVersion];
}

+ (BOOL)accessInstanceVariablesDirectly { return NO; }

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame])) return nil;

  return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super initWithCoder:decoder])) return nil;

  switch ([decoder versionForClassName:@"MWConfigViewAdapter"]) {
    case version1:
      basePath = [[decoder decodeObject] retain];
      relativePath = [[decoder decodeObject] retain];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigViewAdapter!", [decoder versionForClassName:@"MWConfigViewAdapter"]];
  }

  return self;
}

- (void)dealloc {
  if (configRead) [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:configRead];
 
  [basePath autorelease]; basePath = nil;
  [relativePath autorelease]; relativePath = nil;
  [configRead autorelease]; configRead = nil;
  [configWrite autorelease]; configWrite = nil;
  [blinking autorelease]; blinking = nil;
  [transformedInitialValue autorelease]; transformedInitialValue = nil;
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:basePath];
  [aCoder encodeObject:relativePath];
}

- (MWConfigPath *)cvaFullPath {
  return relativePath ? [basePath pathByAppendingPath:relativePath] : nil;
}

- (void)cvaRecomputeControlEnabled {
  [self setControlEnabled:configWrite && basePath && relativePath];
}

- (void)cvaConfigChangedNotify:(NSNotification *)notif {
  MWConfigPath *path = [[notif userInfo] objectForKey:@"path"];

  if (!path || [path hasPrefix:[self cvaFullPath]]) {
    if (![blinking isEqual:[NSColor greenColor]]) 
      [self blink:[NSColor redColor]];
    [self cvaUpdateFromConfig:nil];
  }
}

- (void)cvaWriteToConfig {
  MWConfigPath *path = [self cvaFullPath];
  id value = [self valueFromControl];
  id configValue = [configRead objectAtPath:path];
  if (!path) return;
  if (
    (!value && !configValue)
    || (transformedInitialValue && [value isEqual:transformedInitialValue])
    || (configValue && [value isEqual:configValue])
  ) return;
  if (value) {
    [self blink:[NSColor greenColor]];
    [configWrite addDirectoryAtPath:[path pathByDeletingLastComponent] recurse:YES insertIndex:-1];
    [configWrite setObject:value atPath:path];
  } else {
    [configWrite removeItemAtPath:path recurse:NO];
  }
}

- (void)cvaUpdateFromConfig:(id)sender {
  [self setValueInControl:[configRead objectAtPath:[self cvaFullPath]]];
  [transformedInitialValue autorelease];
  transformedInitialValue = [[self valueFromControl] retain];
  [self setNeedsDisplay:YES];
  [self cvaUpdateToolTip];
}

// --- Onscreen ---

+ (NSMenu *)defaultMenu {
  static NSMenu *menu = nil;
  if (!menu) {
    menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:MWLocalizedStringHere(@"MWConfigViewAdapter-Reset") action:@selector(cvaReset:) keyEquivalent:@""];
  }
  return menu;
}

- (void)cvaReset:(id)sender {
  [configWrite removeItemAtPath:[self cvaFullPath] recurse:NO];
  [[configWrite undoManager] setActionName:MWLocalizedStringHere(@"MWConfigViewAdapter-Reset")];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = [anItem action];
  if (action == @selector(cvaReset:))
    return !![configWrite objectAtPath:[self cvaFullPath]];
  else if (action == @selector(cvaUpdateFromConfig:) || action == @selector(controlWasChangedByUser:))
    return ![[self valueFromControl] isEqual: [configRead objectAtPath:[self cvaFullPath]]];
  else
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
  // we want context menus for left as well as right-mouse
  [NSMenu popUpContextMenu:[self menuForEvent:event] withEvent:event forView:self];
}

- (void)blink:(NSColor *)color {
  [blinking autorelease]; blinking = [color retain];
  [self setNeedsDisplay:YES];
  if (color) [self performSelector:@selector(blink:) withObject:nil afterDelay:0.6];
}

- (void)drawRect:(NSRect)rect {
  [
    blinking ? blinking :
    [configWrite objectAtPath:[self cvaFullPath]] ? [NSColor blackColor] :
    ![self cvaFullPath] ? [NSColor colorWithCalibratedWhite:0.5 alpha:0.5] :
    [NSColor grayColor]
  set];
  [[NSBezierPath bezierPathWithOvalInRect:[self bounds]] fill];
}

- (void)cvaUpdateToolTip {
  [self setToolTip:[NSString stringWithFormat:MWLocalizedStringHere(@"MWConfigViewAdapter-TipFormat%@%@%@"),
    [[self basePath] stringRepresentation],
    [[self relativePath] stringRepresentation],
    ![self cvaFullPath]
      ? MWLocalizedStringHere(@"MWConfigViewAdapter-NoPathTip")
      : [configWrite objectAtPath:[self cvaFullPath]]
        ? MWLocalizedStringHere(@"MWConfigViewAdapter-OverrideTip")
        : MWLocalizedStringHere(@"MWConfigViewAdapter-InheritTip")
  ]];
}

// --- Subclass interaction ---

- (void)controlWasChangedByUser:(id)sender {
  [self cvaWriteToConfig];
}
- (IBAction)controlChangeAction:(id)sender {
  [self controlWasChangedByUser:sender];
}

- (id)valueFromControl { return nil; }
- (void)setValueInControl:(id)newVal {}
- (void)setControlEnabled:(BOOL)newVal {}

// --- Accessors ---

- (MWConfigPath *)basePath { return basePath; }
- (MWConfigPath *)relativePath { return relativePath; }

- (void)setBasePath:(MWConfigPath *)newVal discard:(BOOL)discard {
  if (!discard)
    [self cvaWriteToConfig];

  [basePath autorelease];
  basePath = [newVal retain];

  [self cvaRecomputeControlEnabled];
  [self cvaUpdateFromConfig:nil];
}
- (void)setRelativePath:(MWConfigPath *)newVal discard:(BOOL)discard {
  if (!discard)
    [self cvaWriteToConfig];

  [relativePath autorelease];
  relativePath = [newVal retain];

  [self cvaRecomputeControlEnabled];
  [self cvaUpdateFromConfig:nil];
}

- (void)setReadConfig:(id <MWConfigSupplier>)newVal {
  if (configRead) [[NSNotificationCenter defaultCenter] removeObserver:self name:MWConfigSupplierChangedNotification object:configRead];
  
  [configRead autorelease];
  configRead = [newVal retain];

  if (configRead) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cvaConfigChangedNotify:) name:MWConfigSupplierChangedNotification object:configRead];
  
  [self cvaConfigChangedNotify:nil];
}
- (void)setWriteConfig:(MWConfigTree *)newVal {
  [configWrite autorelease];
  configWrite = [newVal retain];
  [self cvaRecomputeControlEnabled];
  [self cvaUpdateToolTip];
  [self setNeedsDisplay:YES];
}

// --- Nib convenience ---

- (void)setConfigPane:(MWConfigPane *)pane {
  // Tests so that control can be tested in IB where the File's Owner (which is usually the config pane) is IBSimulator
  if ([pane respondsToSelector:@selector(displaySupplier)])
    [self setReadConfig:[pane displaySupplier]];
  if ([pane respondsToSelector:@selector(configTarget)])
    [self setWriteConfig:[pane configTarget]];
}

@end


@implementation MWConfigControlAdapter

- (id)valueFromControl { return [control objectValue]; }
- (void)setValueInControl:(id)newVal {
  [control setObjectValue:newVal];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setEnabled:newVal];
}

- (void)setControl:(id)nc {
  [control setTarget:nil];
  [control setAction:NULL];
  control = nc;
  [control setTarget:self];
  [control setAction:@selector(controlChangeAction:)];
  [self cvaUpdateFromConfig:nil];
}

@end

@implementation MWConfigTextViewAdapter 

enum {
  versionTV1 = 1,
  versionTV2
};
static const int currentVersionTV = versionTV2;

+ (void)initialize {
  [self setVersion:currentVersionTV];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super initWithCoder:decoder])) return nil;

  switch ([decoder versionForClassName:@"MWConfigTextViewAdapter"]) {
    case versionTV1:
      break;
    case versionTV2:
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&writesAttributed];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigTextViewAdapter!", [decoder versionForClassName:@"MWConfigTextViewAdapter"]];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at:&writesAttributed];
}

- (id)valueFromControl { return writesAttributed ? [[NSAttributedString alloc] initWithAttributedString:[control textStorage]] : [[[control string] copy] autorelease]; }
- (void)setValueInControl:(id)newVal {
  if ([newVal isKindOfClass:[NSAttributedString class]])
    [[control textStorage] setAttributedString:newVal];
  else if ([newVal isKindOfClass:[NSString class]])
    [control setString:newVal];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setSelectable:newVal];
  [control setEditable:newVal];
}

- (BOOL)writesAttributed { return writesAttributed; }
- (void)setWritesAttributed:(BOOL)newVal { writesAttributed = newVal; }

- (void)setControl:(id)nc {
  [control setDelegate:nil];
  control = nc;
  [control setDelegate:self];
  [self cvaUpdateFromConfig:nil];
}

- (void)textDidEndEditing:(NSNotification *)notif {
  [self controlWasChangedByUser:nil];
}

@end

@implementation MWConfigScriptViewAdapter

- (void)dealloc {
  [languageWhileEditing release]; languageWhileEditing = nil;
  [panelWC release]; panelWC = nil;
  [super dealloc];
}

- (NSString *)defaultLanguage { return [[NSUserDefaults standardUserDefaults] stringForKey:@"MWDefaultScriptLanguageIdentifier"]; }

- (void)setValueInControl:(id)newVal {
  [languageWhileEditing release];
  NS_DURING
    languageWhileEditing = [[newVal languageIdentifier] copy];
  NS_HANDLER
    languageWhileEditing = nil;
  NS_ENDHANDLER
  [panelWC updateErrors];
  [panelWC updateLanguage];
}

- (void)openScriptPanel {
  if (!panelWC)
    panelWC = [[MWScriptPanelController alloc] initWithWindowNibName:@"MWScriptPanel"];
  [panelWC setTarget:self];
  [[panelWC window] orderFront:nil];
}

- (void)closeScriptPanel {
  [[panelWC window] close];
  [panelWC release]; panelWC = nil;
}

- (NSString *)languageWhileEditing {
  return languageWhileEditing ? languageWhileEditing : [self defaultLanguage];
}
- (void)setLanguageWhileEditing:(NSString *)languageIdentifier {
  [languageWhileEditing autorelease];
  languageWhileEditing = [languageIdentifier copy];
}

- (id)control { return nil; }

@end

@implementation MWConfigScriptTextViewAdapter 

- (id)valueFromControl {
  return [[[MWScript alloc] initWithSource:[[[control string] copy] autorelease] languageIdentifier:[[control string] length] ? [self languageWhileEditing] : nil] autorelease];
}
- (void)setValueInControl:(id)newVal {
  NS_DURING
    [control setString:newVal ? [newVal source] : @""];
  NS_HANDLER
    [control setString:@"<invalid>"];
  NS_ENDHANDLER
  [super setValueInControl:newVal];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setSelectable:newVal];
  [control setEditable:newVal];
}
- (id)control { return control; }
- (void)setControl:(NSTextView *)nc {
  [control setDelegate:nil];
  control = nc;
  [control setDelegate:self];
  [self cvaUpdateFromConfig:nil];
}

- (void)textDidBeginEditing:(NSNotification *)notif {
  [self openScriptPanel];
}
- (void)textViewDidChangeSelection:(NSNotification *)notif {
  if ([notif object] == [[self window] firstResponder])
    [self openScriptPanel];
}

- (void)textDidChange:(NSNotification *)notif {
  [panelWC updateErrors];
}

- (void)textDidEndEditing:(NSNotification *)notif {
  [self controlWasChangedByUser:nil];
  [self closeScriptPanel];
}

@end

@implementation MWConfigScriptTextFieldAdapter

- (id)valueFromControl {
  return [[[MWScript alloc] initWithSource:[[[control stringValue] copy] autorelease] languageIdentifier:[[control stringValue] length] ? [self languageWhileEditing] : nil] autorelease];
}
- (void)setValueInControl:(id)newVal {
  NS_DURING
    [control setStringValue:newVal ? [newVal source] : @""];
  NS_HANDLER
    [control setStringValue:@"<invalid>"];
  NS_ENDHANDLER
  [super setValueInControl:newVal];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setEnabled:newVal];
}
- (id)control { return control; }
- (void)setControl:(NSTextField *)nc {
  [control setTarget:nil];
  [control setAction:NULL];
  [control setDelegate:nil];
  control = nc;
  [control setTarget:self];
  [control setAction:@selector(controlChangeAction:)];
  [control setDelegate:self];
  [self cvaUpdateFromConfig:nil];
}

- (void)controlTextDidBeginEditing:(NSNotification *)notif {
  [self openScriptPanel];
}

- (void)controlTextDidChange:(NSNotification *)notif {
  [panelWC updateErrors];
}

- (void)controlTextDidEndEditing:(NSNotification *)notif {
  [self closeScriptPanel];
}

@end

@implementation MWConfigPopupTagAdapter

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super initWithCoder:decoder])) return nil;

  switch ([decoder versionForClassName:@"MWConfigPopupTagAdapter"]) {
    case version1:
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&usesUnsignedNumbers];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigPopupTagAdapter!", [decoder versionForClassName:@"MWConfigPopupTagAdapter"]];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at:&usesUnsignedNumbers];
}

- (id)valueFromControl {
  return usesUnsignedNumbers
    ? [NSNumber numberWithUnsignedInt:[[control selectedItem] tag]]
    : [NSNumber numberWithInt:[[control selectedItem] tag]];
}
- (void)setValueInControl:(id)newVal {
  [control selectItemAtIndex:[control indexOfItemWithTag:usesUnsignedNumbers ? [newVal unsignedIntValue] : [newVal intValue]]];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setEnabled:newVal];
}

- (void)setControl:(id)nc {
  [control setTarget:nil];
  [control setAction:NULL];
  control = nc;
  [control setTarget:self];
  [control setAction:@selector(controlChangeAction:)];
  [self cvaUpdateFromConfig:nil];
}

- (BOOL)usesUnsignedNumbers { return usesUnsignedNumbers; }
- (void)setUsesUnsignedNumbers:(BOOL)newVal { usesUnsignedNumbers = newVal; }

@end

@implementation MWConfigPopupTagLookupAdapter

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if (!(self = [super initWithCoder:decoder])) return nil;

  switch ([decoder versionForClassName:@"MWConfigPopupTagLookupAdapter"]) {
    case version1:
      [self setTagToObjectLookups:[decoder decodeObject]];
      break;
    default:
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"Unknown version %u in decoding MWConfigPopupTagLookupAdapter!", [decoder versionForClassName:@"MWConfigPopupTagLookupAdapter"]];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:tagToObject];
}

- (id)valueFromControl {
  return [tagToObject objectForKey:[NSNumber numberWithInt:[[control selectedItem] tag]]];
}
- (void)setValueInControl:(id)newVal {
  [control selectItemAtIndex:[control indexOfItemWithTag:[[objectToTag objectForKey:newVal] intValue]]];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setEnabled:newVal];
}

- (void)setControl:(id)nc {
  [control setTarget:nil];
  [control setAction:NULL];
  control = nc;
  [control setTarget:self];
  [control setAction:@selector(controlChangeAction:)];
  [self cvaUpdateFromConfig:nil];
}

- (void)setTagToObjectLookups:(NSDictionary *)newVal {
  NSArray *tags = [newVal allKeys];
  [tagToObject autorelease];
  tagToObject = [newVal retain];
  objectToTag = [[NSDictionary alloc] initWithObjects:tags forKeys:[newVal objectsForKeys:tags notFoundMarker:[NSNumber numberWithInt:0]]];
  [self cvaUpdateFromConfig:nil];
}

@end


@implementation MWConfigPopupRepresentedObjectAdapter

+ (void)initialize {
  [self setVersion:currentVersion];
}

- (id)valueFromControl {
  return [[control selectedItem] representedObject];
}
- (void)setValueInControl:(id)newVal {
  NSEnumerator *const itemE = [[[control menu] itemArray] objectEnumerator];
  NSMenuItem *item;
  while ((item = [itemE nextObject])) {
    if ([[item representedObject] isEqual:newVal]) {
      [control selectItem:item];
      return;
    }
  }
  [control selectItem:nil];
}
- (void)setControlEnabled:(BOOL)newVal {
  [control setEnabled:newVal];
}

- (void)setControl:(id)nc {
  [control setTarget:nil];
  [control setAction:NULL];
  control = nc;
  [control setTarget:self];
  [control setAction:@selector(controlChangeAction:)];
  [self cvaUpdateFromConfig:nil];
}

@end
