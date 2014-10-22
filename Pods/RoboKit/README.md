# RoboKit

## About

RoboKit is collection of categories that we've found useful and potentially reusable. Include the whole library to get everything or just use specific .h/.m pairs if you only want specific functionality.

## Installation

### Cocoapods
RoboKit is not yet in the cocoapods Add the following to your podfile

`pod 'RoboKit', :git => 'git@github.com:RobotsAndPencils/RoboKit.git'`

### Manual
1. Add RoboKit.xcodeproj to your project 
2. In the **Build Phases** for your target, set the RoboClient library as a **Target Dependency**
3. Add `#import <RoboKit/RBKCommonUtils.h>` to your target's `.pch` file
4. Optionally add additional imports to your `.pch` or `.h`/`.m` file to leverage other features.  e.g. `#import <RoboKit/UIView+RoboKit.h>`

## Usage

The macros and other helpful tidbits in `RBKCommonUtils.h` are self explanitory or have examples.

Please see the corresponding `RoboKitTest.m` for how to use the categories.

## Test Coverage

All +RoboKit categories are covered by unit tests.

The following are not yet covered by unit tests.

* NSData+Base64 
* NSString+CSV

---

Copyright (c) 2012 Robots and Pencils, Inc. All rights reserved.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

"RoboKit" is a trademark of Robots and Pencils, Inc. and may not be used to endorse or promote products derived from this software without specific prior written permission.

Neither the name of the Robots and Pencils, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

