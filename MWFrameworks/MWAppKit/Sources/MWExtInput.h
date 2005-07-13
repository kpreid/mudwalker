/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 *
\*/

@protocol MWExtInputClient;

@protocol MWExtInputManager <NSObject>

/* NONRETAINED */
- (id <MWExtInputClient>)target;
- (void)setTarget:(id <MWExtInputClient>)newVal;

/* Prompt to display to the user */
- (NSAttributedString *)inputPrompt;
- (void)setInputPrompt:(NSAttributedString *)newVal;

/* Move the keyboard focus to whatever UI the input manager provides. */
- (void)makeKey;

/* When inactive, the input manager should hide/disable its UI. Input managers should default to being active. */
- (BOOL)isActive;
- (void)setActive:(BOOL)newVal;

@end

@protocol MWExtInputClient <NSObject>

// FIXME: rename inputClient* to extInputClient* sometime

/* The client must remember this value. The client should not set the input manager's target. */
- (id <MWExtInputManager>)extInputManager;
- (void)setExtInputManager:(id <MWExtInputManager>)newVal;

/* User entered some input, here's the object. */
- (void)inputClientReceive:(id)obj;

/* If possible, complete the abbreviation in 'str'. */
- (NSString *)inputClientCompleteString:(NSString *)str;

@end
