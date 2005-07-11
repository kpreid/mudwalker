/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWPythonProxy.h"


@implementation MWPythonProxy

+ (id)proxyFor:(PyObject *)obj {
  return [self proxyFor:obj steal:NO];
}
+ (id)proxyFor:(PyObject *)obj steal:(BOOL)steal {
  return [[[self alloc] initWithPythonObject:obj steal:steal] autorelease];
}

- (id)initWithPythonObject:(PyObject *)obj steal:(BOOL)steal {
   if (!obj) {
    [self dealloc];
    return nil;
  }
  if (!steal) Py_INCREF(obj);
  pyObj = obj;
  return self;
}

- (void)dealloc {
  Py_XDECREF(pyObj);
  pyObj = NULL;
  [super dealloc];
}

- (NSString *)description {
  PyObject *repr;
  char *cstr;
  
  if (!pyObj) {
    return @"<Invalid Python Proxy>";
  }
  
  repr = PyObject_Repr(pyObj);
  if (!repr) {
    // fixme: do something with the exception
    return @"<Exception while getting representation>";
  }
  
  cstr = PyString_AsString(repr);
  if (!cstr) {
    return @"<Exception while getting representation>";
  }
  
  {
    NSString *result = [NSString stringWithCString:cstr];
    Py_DECREF(repr);
    return result;
  }
}

@end
