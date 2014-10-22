//
//  NSDate+Holidays.m
//  RoboKit
//
//  Created by Stephen Gazzard on 11/8/2013.
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

#import "NSDate+Holidays.h"


@implementation NSDate (Holidays)

+ (NSDateComponents*)newYearsComponentsForYear:(NSInteger)year {
    NSDateComponents *newYearsDateComponents = [[NSDateComponents alloc] init];
    newYearsDateComponents.month = RBKMonthJanuary;
    newYearsDateComponents.day = 1;
    newYearsDateComponents.year = year;
    return newYearsDateComponents;
}

+ (NSDateComponents*)easterSundayComponentsForYear:(NSInteger)year {
    //Calculating Easter is surprisingly complex. Based on arithmetic formula found at http://www.smart.net/~mmontes/oudin.html.
    //variables names aren't good, but are from the formula. Didn't know what else to call 'em. Sorry about that :( - SG
    NSUInteger century = year / 100;
    NSUInteger g = year % 19;
    NSUInteger k = (century - 17) / 25;
    NSUInteger i = (century - century / 4 - (century - k) / 3 + 19 * g + 15) % 30;
    i = i - (i / 28) * (1 - (i / 28) * (29 / (i + 1)) * ((21 - g) / 11));
    NSUInteger j = (year + year / 4 + i + 2 - century + century / 4) % 7;
    NSUInteger l = i - j;
    
    NSDateComponents *easterSundayComponents = [[NSDateComponents alloc] init];
    easterSundayComponents.month = 3 + (l + 40) / 44;
    easterSundayComponents.day = l + 28 - 31 * (easterSundayComponents.month / 4);
    easterSundayComponents.year = year;
    return easterSundayComponents;
}

+ (NSDateComponents*)goodFridayComponentsForEaster:(NSDateComponents*)easter calendar:(NSCalendar*)calendar {
    NSDate *easterDate = [calendar dateFromComponents:easter];
    NSDateComponents *goodFridayOffset = [[NSDateComponents alloc] init];
    goodFridayOffset.day = -2;
    NSDate *goodFriday = [calendar dateByAddingComponents:goodFridayOffset toDate:easterDate options:0];
    return [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:goodFriday];
}

+ (NSDateComponents*)goodFridayComponentsForYear:(NSInteger)year calendar:(NSCalendar*)calendar {
    NSDateComponents *easterComponenets = [NSDate easterSundayComponentsForYear:year];
    return [NSDate goodFridayComponentsForEaster:easterComponenets calendar:calendar];
}

+ (NSDateComponents*)victoriaDayDateComponentsForYear:(NSInteger)year calendar:(NSCalendar*)calendar {
    //Victoria Day (in French: Fête de la Reine) is a federal Canadian public holiday celebrated on the last Monday before May 25
    NSDateComponents *may25Components = [[NSDateComponents alloc] init];
    may25Components.month = RBKMonthMay;
    may25Components.day = 25;
    may25Components.year = year;
    NSDate *may25Date = [calendar dateFromComponents:may25Components];
    NSDateComponents *may25DayOfWeek = [calendar components:NSCalendarUnitWeekday fromDate:may25Date];
    

    NSDateComponents *offset = [[NSDateComponents alloc] init];
    //We now know what day of the week may 25 is on and can work backwards from there.
    if(may25DayOfWeek.weekday > RBKDayOfWeekMonday) {
        //It's Tuesday or ahead, just backtrack
        offset.day = RBKDayOfWeekMonday - may25DayOfWeek.weekday;
    } else {
        //it's last week - we have to subtract that number of days to get to Tuesday from the end
        //of last week, then the number of days we have to go back to get to last week
        offset.day = (RBKDayOfWeekMonday - RBKDayOfWeekSaturday) - may25DayOfWeek.weekday;
    }
    
    NSDate *victoriaDayDate = [calendar dateByAddingComponents:offset toDate:may25Date options:0];
    return [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:victoriaDayDate];
}

+ (NSDateComponents*)canadaDayComponentsForYear:(NSInteger)year {
    NSDateComponents *canadaDayComponents = [[NSDateComponents alloc] init];
    canadaDayComponents.year = year;
    canadaDayComponents.month = RBKMonthJuly;
    canadaDayComponents.day = 1;
    return canadaDayComponents;
}

+ (NSDateComponents*)labourDayDateComponentsForYear:(NSInteger)year calendar:(NSCalendar*)calendar {
    NSDateComponents *labourDayCalculationComponents = [[NSDateComponents alloc] init];
    labourDayCalculationComponents.weekOfMonth = 1;
    labourDayCalculationComponents.weekday = RBKDayOfWeekMonday;
    labourDayCalculationComponents.month = RBKMonthSeptember;
    labourDayCalculationComponents.year = year;

    NSDate *labourDayDate = [calendar dateFromComponents:labourDayCalculationComponents];
    NSDateComponents *labourDayComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:labourDayDate];
    
    //The first week of the month may start after Monday (in fact it is quite likely). If so, then labour day may be calculated
    //to be in August, which would be incorrect. If we find we are not in September, move to the second week of the month
    if(labourDayComponents.month != RBKMonthSeptember) {
        labourDayCalculationComponents.weekOfMonth = 2;
        labourDayDate = [calendar dateFromComponents:labourDayCalculationComponents];
        labourDayComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:labourDayDate];
    }
    return labourDayComponents;
}

+ (NSDateComponents*)thanksgivingDateComponentsForYear:(NSInteger)year calendar:(NSCalendar*)calendar {
    NSDateComponents *thanksgivingCalculationComponents = [[NSDateComponents alloc] init];
    thanksgivingCalculationComponents.weekOfMonth = 2;
    thanksgivingCalculationComponents.weekday = RBKDayOfWeekMonday;
    thanksgivingCalculationComponents.month = RBKMonthOctober;
    thanksgivingCalculationComponents.year = year;
    
    NSDate *thanksgivingDate = [calendar dateFromComponents:thanksgivingCalculationComponents];
    NSDateComponents *thanksgivingDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:thanksgivingDate];
    
    //The first week of the month may start after Monday, in which case we may get thanksgiving on the first Thursday of the month.
    //The earliest thanksgiving can be and be on the second Sunday of the month is the 8th. If Thanksgiving comes before that,
    //jump forward a month and recalculate.
    if(thanksgivingDateComponents.day < 8) {
        thanksgivingCalculationComponents.weekOfMonth = 3;
        thanksgivingDate = [calendar dateFromComponents:thanksgivingCalculationComponents];
        thanksgivingDateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:thanksgivingDate];
    }
    return thanksgivingDateComponents;
}

+ (NSDateComponents*)remembranceDayDateComponentsForYear:(NSInteger)year {
    NSDateComponents *remembranceDayDateComponents = [[NSDateComponents alloc] init];
    remembranceDayDateComponents.year = year;
    remembranceDayDateComponents.month = RBKMonthNovember;
    remembranceDayDateComponents.day = 11;
    return remembranceDayDateComponents;
}

+ (NSDateComponents*)christmasDateComponentsForYear:(NSInteger)year {
    NSDateComponents *christmasDateComponents = [[NSDateComponents alloc] init];
    christmasDateComponents.year = year;
    christmasDateComponents.month = RBKMonthDecember;
    christmasDateComponents.day = 25;
    return christmasDateComponents;
}

+ (NSDateComponents*)boxingDayDateComponentsForYear:(NSInteger)year {
    NSDateComponents *boxingDayDateComponents = [[NSDateComponents alloc] init];
    boxingDayDateComponents.year = year;
    boxingDayDateComponents.month = RBKMonthDecember;
    boxingDayDateComponents.day = 26;
    return boxingDayDateComponents;
}

+ (NSArray*)holidayComponentsForYear:(NSInteger)year calendar:(NSCalendar*)calendar {
    NSMutableArray *result = [NSMutableArray array];
    
    [result addObject:[NSDate newYearsComponentsForYear:year]];
    NSDateComponents *easterComponents = [NSDate easterSundayComponentsForYear:year];
    [result addObject:easterComponents];
    [result addObject:[NSDate goodFridayComponentsForEaster:easterComponents calendar:calendar]];
    [result addObject:[NSDate victoriaDayDateComponentsForYear:year calendar:calendar]];
    [result addObject:[NSDate canadaDayComponentsForYear:year]];
    [result addObject:[NSDate labourDayDateComponentsForYear:year calendar:calendar]];
    [result addObject:[NSDate thanksgivingDateComponentsForYear:year calendar:calendar]];
    [result addObject:[NSDate remembranceDayDateComponentsForYear:year]];
    [result addObject:[NSDate christmasDateComponentsForYear:year]];
    [result addObject:[NSDate boxingDayDateComponentsForYear:year]];
    
    //Move any holidays off of the weekend if necessary
    for(NSUInteger dateIndex = 0; dateIndex < [result count]; dateIndex++) {
        NSDateComponents *dateComponents = result[dateIndex];
        NSDate *date = [[calendar dateFromComponents:dateComponents] nextNonWeekendDayInCalendar:calendar];
        [result replaceObjectAtIndex:dateIndex withObject:[calendar components:NSCalendarUnitYear | NSCalendarUnitDay | NSCalendarUnitMonth fromDate:date]];
    }
    
    return result;
}

- (NSDate*)nextNonWeekendDayInCalendar:(NSCalendar*)calendar {
    NSDateComponents *dayOfWeekComponents = [calendar components:NSCalendarUnitWeekday fromDate:self];
    NSDateComponents *daysToMoveDateForward = [[NSDateComponents alloc] init];
    switch(dayOfWeekComponents.weekday) {
        default:
            return self;
        case RBKDayOfWeekSaturday:
            daysToMoveDateForward.day = 2;
            break;
        case RBKDayOfWeekSunday:
            daysToMoveDateForward.day = 1;
            break;
    }
    return [calendar dateByAddingComponents:daysToMoveDateForward toDate:self options:0];
}

- (NSDate*)nextNonHolidayDayInCalendar:(NSCalendar*)calendar {
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    NSArray *holidayComponents = [NSDate holidayComponentsForYear:dateComponents.year calendar:calendar];
    
    for(NSDateComponents *holidayDateComponents in holidayComponents) {
        if(holidayDateComponents.day == dateComponents.day && holidayDateComponents.month == dateComponents.month) {
            //This date is a holiday! Move it forward one day
            NSDateComponents *offset = [[NSDateComponents alloc] init];
            offset.day = 1;
            NSDate *date = [calendar dateByAddingComponents:offset toDate:self options:0];
            //cannot assume we are not on a holiday anymore - must be certain!
            return [date nextNonHolidayDayInCalendar:calendar];
        }
    }
    return self;
}

- (NSDate*)nextNonWeekendOrHolidayInCalendar:(NSCalendar*)calendar {
    NSDate *result = self;
    NSDate *lastDate = nil;
    //Need a bit of looping going on here. For example: Next holiday is good Friday. Good Friday pushes user to Saturday, which
    //is then a weekend. Then the weekend pushes them to Monday, which is the placeholder for Easter Sunday. So user should be pushed
    //to the following Tuesday. So keep applying both until the date is the same as it started, then we'll know all is well.
    while(![result isEqual:lastDate]) {
        lastDate = result;
        result = [[result nextNonWeekendDayInCalendar:calendar] nextNonHolidayDayInCalendar:calendar];
    }
    
    return result;
}



@end
