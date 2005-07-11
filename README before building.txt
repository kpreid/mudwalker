Important note #1:
  Building the MWFrameworks project will place copies of the frameworks in ~/Library/Frameworks/.
  
Important note #2:
  For the MudWalker application unit tests to execute properly:
    * you must have a symlink from ~/Library/Application Support/MudWalker/PlugIns/TestRun.mwplug to $BUILD_PRODUCTS_DIR/TestRun.mwplug.
    * the path in the "Test MudWalker" executable must be changed to begin with your build products directory
    
You will need:
  * static libraries for PCRE (with UTF-8 support) and Lua in /usr/local/lib
  * the ObjcUnit framework <http://oops.se/objcunit/>
