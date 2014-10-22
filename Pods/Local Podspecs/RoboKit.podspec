# -*- coding: utf-8 -*-
#
# Be sure to run `pod spec lint RoboKit.podspec' to ensure this is a
# valid spec.
#
# Remove all comments before submitting the spec. Optional attributes are commented.
#
# For details see: https://github.com/CocoaPods/CocoaPods/wiki/The-podspec-format
#
Pod::Spec.new do |s|
  s.name         = "RoboKit"
  s.version      = "0.3.3"
  s.summary      = "RoboKit is a small collection of utilities and categories."
  s.homepage     = "https://github.com/RobotsAndPencils/RoboKit"
  s.license      = {
    :type => 'MIT',
    :text => <<-LICENSE
Copyright (c) 2012 Robots and Pencils, Inc. All rights reserved.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

"RoboKit" is a trademark of Robots and Pencils, Inc. and may not be used to endorse or promote products derived from this software without specific prior written permission.

Neither the name of the Robots and Pencils, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    LICENSE
  }
  s.authors       = { 
    "Dave Anderson" => "dave@robotsandpencils.com",  
    "Michael Beauregard" => "michael.beauregard@robotsandpencils.com", 
    "Cody Rayment" => "cody.rayment@robotsandpencils.com", 
  }
  s.source       = { :git => "https://github.com/RobotsAndPencils/RoboKit.git", :tag => s.version.to_s }
  
  s.osx.deployment_target = '10.9'
  s.ios.deployment_target = '7.0'

  s.source_files = 'Classes/**/*.{h,m}'
  s.ios.source_files = 'iOS/**/*.{h,m}'
  s.ios.exclude_files = 'OSX/'
  s.osx.source_files = 'OSX/**/*.{h,m}'
  s.osx.exclude_files = 'iOS/'

  s.framework = 'Foundation'
  s.ios.framework = 'UIKit'
  s.osx.framework = 'Cocoa'

  s.requires_arc = true  
end
