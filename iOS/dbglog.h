//
//  dbglog.h
//
//  Created by Adam Solesby
//  http://github.com/solesby
//  Copyright (c) 2013 Adam Solesby. All rights reserved.
//  
//  The MIT License (MIT)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//  
//
//  Usage:
//
//     Include the following lines in your precompiled headers file (.pch).
//
//        #if DEBUG
//        #  define DBGLOG_LEVEL 1
//        #else
//        #  define DBGLOG_LEVEL 0
//        #endif
//        #import "dbglog.h"
//
//     Then set the DBGLOG_LEVEL (for DEBUG and RELEASE):
//        0  = off (only output DBG0 lines in DEBUG)
//        1  = least granular (only output DBG1 lines)
//        3+ = most granular (output all DBG1, DBG2, DBG3 lines)
//
//     NSLog() will always output (debug or release build)
//     DBG()   will only output in debug build
//
//     You might also want this to remind you what level you're at when debugging:
//
//        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
//        {
//            DBG0(@"## Debug log level 0: no output -- only DBG()");
//            DBG1(@"## Debug log level 1: DBG1");
//            DBG2(@"## Debug log level 2: DBG1 DBG2");
//            DBG3(@"## Debug log level 3: DBG1 DBG2 DBG3");
//            ...
//        }
//
//////////////////////////////////////////////////////////////////////////////////////////

#ifndef SOLESBY_dbglog_h
#define SOLESBY_dbglog_h

//// If not a DEBUG build, then DBG(...) is a noop

#if DEBUG
#   define DBG(...) NSLog(__VA_ARGS__)
#else
#   define DBG(...)
#endif

//// if we define DBGLOG_LEVEL, then that level and below will be output

#ifdef DBGLOG_LEVEL

#if DEBUG
#if DBGLOG_LEVEL == 0
#   define DBG0(...) NSLog(__VA_ARGS__)
#else
#   define DBG0(...)
#endif
#else
#   define DBG0(...)
#endif

#if DBGLOG_LEVEL == 1
#   define DBG1(...) NSLog(__VA_ARGS__)
#   define DBG2(...)
#   define DBG3(...)
#else
#if DBGLOG_LEVEL == 2
#   define DBG1(...) NSLog(__VA_ARGS__)
#   define DBG2(...) NSLog(__VA_ARGS__)
#   define DBG3(...)
#else
#if DBGLOG_LEVEL >= 3
#   define DBG1(...) NSLog(__VA_ARGS__)
#   define DBG2(...) NSLog(__VA_ARGS__)
#   define DBG3(...) NSLog(__VA_ARGS__)
#else
#   define DBG1(...)
#   define DBG2(...)
#   define DBG3(...)
#endif
#endif
#endif

#else
#   define DBG1(...)
#   define DBG2(...)
#   define DBG3(...)
#endif

#endif // SOLESBY_dbglog_h

