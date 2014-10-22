//
//  RBKCommonUtils.h
//  RoboKit
// 
//  Created by Michael J. Sikorsky on 10-11-25.
//
//  Copyright (c) 2012 Robots and Pencils, Inc. All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  "RoboKit" is a trademark of Robots and Pencils, Inc. and may not be used to endorse or promote products derived from this software without specific prior written permission.
//
//  Neither the name of the Robots and Pencils, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

/*
 * RBKLog is almost a drop-in replacement for NSLog (and equivlaent to DLog)
 * RBKLog();
 * RBKLog(@"here");
 * RBKLog(@"value: %d", x);
 * Unfortunately this doesn't work RBKLog(aStringVariable); you have to do this instead RBKLog(@"%@", aStringVariable);
 */
#ifdef DEBUG
#	define RBKLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   define RBKLogCall RBKLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd))
#else
#	define RBKLog(...)
#endif

// RBKLogAlways always displays output regardless of the DEBUG setting
#define RBKLogAlways(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

/*
 * Check if something is nil, null, zero length, or zero count
 * Thanks Wil http://wilshipley.com/blog/2005/10/pimp-my-code-interlude-free-code.html
 */
static inline BOOL RBKIsEmpty(id thing) {
    return thing == nil
    || ([thing isEqual:[NSNull null]]) //JS addition for things like coredata
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

/*
 * Radian <-> Degree conversion
 */
#define RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) / (CGFloat)M_PI * 180.0f)
#define DEGREES_TO_RADIANS(__ANGLE__) ((CGFloat)M_PI * (__ANGLE__) / 180.0f)

/*
 * Selectively suppress "Perform selector may cause a leak because its selector is unknown" warnings
 */
#define SuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)

/*
* Detect if we're currently running as a test target or not (for Test scheme set Environment Varible IS_TARGET_TEST to 1 )
*/
#define IS_TEST_TARGET [[[NSProcessInfo processInfo] environment] objectForKey:@"IS_TARGET_TEST"]
