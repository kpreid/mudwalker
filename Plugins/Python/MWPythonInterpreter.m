/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
\*/

#import "MWPythonInterpreter.h"

#import "MWInterpreterConsole.h"
#import "MWPythonProxy.h"

#include <Python.h>
#include <compile.h>
#include <eval.h>

static MWPythonInterpreter *shared;

@implementation MWPythonInterpreter

+ (void)registerAsMWPlugin:(MWRegistry *)registry {
  // [registry registerInterpreter:self];
  [registry registerUserInterfaceCommand:MWLocalizedStringHere(@"Open Python Console") context:@"global" handler:self performSelector:@selector(openConsoleAction:)];
}

+ (void)openConsoleAction:(id)sender {
  [[[[MWInterpreterConsole alloc] initWithInterpreter:[self sharedInterpreter]] autorelease] openWindow];
}

+ (NSString *)localizedLanguageName { return @"Python"; }

+ (MWPythonInterpreter *)sharedInterpreter {
  if (!shared) shared = [[self alloc] init];
  return shared;
}

// ---

- (id)init {
  if (shared) {
    [self dealloc];
    return shared;
  }
  
  if (!(self = [super init])) return nil;
  
  Py_Initialize();
  
  return self;
}

- (void)dealloc {
  Py_Finalize();
  [super dealloc];
}

// ---

- (NSAttributedString *)evaluateLines:(NSString *)lines {
  PyObject *mname = PyString_FromString("__main__");
  PyObject *mainmod = PyImport_Import(mname);
  PyObject *globals = PyDict_New(), *locals = PyDict_New();
  PyObject *code, *res;
  MWPythonProxy *pxCode, *pxRes;
  [MWPythonProxy proxyFor:globals steal:YES];
  [MWPythonProxy proxyFor:locals steal:YES];
  
  [MWPythonProxy proxyFor:mname steal:YES];
  
  if (!(code = Py_CompileString((char *)[lines cString], (char *)"<console>", Py_single_input))) {
    PyErr_Print();
    return [[[NSAttributedString alloc] initWithString:@"Py_CompileString returned NULL" attributes:[NSDictionary dictionaryWithObject:MWLocalRole forKey:MWRoleAttribute]] autorelease];
  }
  pxCode = [MWPythonProxy proxyFor:code steal:YES];

  if (!(res = PyEval_EvalCode((PyCodeObject *)code, PyModule_GetDict(mainmod), PyModule_GetDict(mainmod)))) {
    PyErr_Print();
    return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"PyEval_EvalCode(%@) returned NULL", [pxCode description]] attributes:[NSDictionary dictionaryWithObject:MWLocalRole forKey:MWRoleAttribute]] autorelease];
  }
  pxRes = [MWPythonProxy proxyFor:res steal:YES];
  
  return [[[NSAttributedString alloc] initWithString:[pxRes description] attributes:[NSDictionary dictionary]] autorelease];
}

@end
