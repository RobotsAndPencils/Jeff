//
//  NSDate+RoboKit.m
//  RoboKit
//
//  Created by Michael Beauregard on 11-09-06.
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

#import "NSDate+RoboKit.h"

@implementation NSDate (NSDate_RoboKit)

+ (NSDate *)RBK_dateFromString:(NSString *)string withFormat:(NSString *)format {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:format];
    NSDate *date = [formatter dateFromString:string];
    return date;
}

// useful for testing against a specific date
//    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
//    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
//    NSDate *currentDate = [inputFormatter dateFromString:@"2010-03-01 12:00"];
//    [inputFormatter release];


+ (NSString *)RBK_stringInISOFormatForDate:(NSDate *)date {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	[inputFormatter setDateFormat:@"yyyy-MM-dd"];
	NSString * value = [inputFormatter stringFromDate:date];
	return value;
	
}

+ (NSDate *)RBK_dateAtHour:(NSInteger)hour daysFromToday:(NSInteger)days
{
    return [NSDate RBK_dateAtHour:hour daysFromDate:[NSDate date] days:days];
}

+ (NSDate *)RBK_dateAtHour:(NSInteger)hour daysFromDate:(NSDate *)date days:(NSInteger)days
{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
    NSDateComponents *dateComponents = [calendar components:flags fromDate:date];
    
    [dateComponents setHour:hour];
    return [NSDate dateWithTimeInterval:60 * 60 * 24 * days sinceDate:[calendar dateFromComponents:dateComponents]];
}

- (NSInteger)RBK_minuteIntervalSinceDate:(NSDate *)date {
    NSTimeInterval time = [self timeIntervalSinceDate:date];
	return (NSInteger)round(time / 60);
}


@end
