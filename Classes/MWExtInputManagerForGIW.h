/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#import <Foundation/Foundation.h>

#import <MWAppKit/MWAppKit.h>

@interface MWExtInputManagerForGIW : NSObject <MWExtInputManager> {
  id <MWExtInputClient> target;
  NSAttributedString *inputPrompt;
  BOOL active;
  
  NSMutableArray *history;
  unsigned historyIndex;
}

- (NSMutableArray *)mutableHistory;

- (unsigned)historyIndex;
- (void)setHistoryIndex:(unsigned)newVal;

@end
