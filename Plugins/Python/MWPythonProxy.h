/*\  
 * MudWalker Source
 * Copyright 2001-2005 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * This class serves as a proxy for communicating with objects in the embedded Python interpreter.
\*/

#import <Foundation/Foundation.h>

#import <Python.h>

@interface MWPythonProxy : NSProxy {
  PyObject *pyObj;
}

+ (id)proxyFor:(PyObject *)obj;
+ (id)proxyFor:(PyObject *)obj steal:(BOOL)steal;
- (id)initWithPythonObject:(PyObject *)obj steal:(BOOL)steal;

@end
