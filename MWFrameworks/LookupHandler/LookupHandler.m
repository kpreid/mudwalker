/*\  
 * MudWalker Source
 * Copyright 2001-2004 Kevin Reid.
 * This source code and related files are distributed under the MIT License, as described in the document named "License.txt" which should be provided with this source distribution.
 * 
 * 
\*/

#include <stdio.h>
#include <netdb.h>
#include <unistd.h>
#import "LookupHandler.h"

int main(int argc, const char *argv[]) {
  struct hostent *he = NULL;
  
  if (argc < 2) {
    fprintf(stderr, "No host specified.");
    return LHCallError;
  }
  
  while (!he) {
    he = gethostbyname(argv[1]);
    
    if (!he) {
      switch (h_errno) {
        case HOST_NOT_FOUND: return LHNotFound;
        case NO_DATA:        return LHNotFound;
        case NO_RECOVERY:    return LHRemoteError;
        case TRY_AGAIN:      sleep(5); break;
        default:             return LHLocalError;
      }
    }
  }
  
  if (fwrite(he->h_addr_list[0], he->h_length, 1, stdout) == 1) {
    fflush(stdout);
    return LHOkay;
  } else {
    return LHLocalError;
  }
}
