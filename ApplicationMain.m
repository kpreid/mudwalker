#import <AppKit/NSApplication.h>
#import "MWBGMain.h"
#include <string.h>

int main(int argc, const char *argv[]) {
  if (argc > 0 && !strcmp(argv[0], "-MWBackground"))
    return MWBGMain(argc, argv);
  else
    return NSApplicationMain(argc, argv);
}
