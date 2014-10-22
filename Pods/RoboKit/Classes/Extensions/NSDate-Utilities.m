/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook 3.x and beyond
 BSD License, Use at your own risk
 */

/*
 #import <humor.h> : Not planning to implement: dateByAskingBoyOut and dateByGettingBabysitter
 ----
 General Thanks: sstreza, Scott Lawrence, Kevin Ballard, NoOneButMe, Avi`, August Joki. Emanuele Vulcano, jcromartiej, Blagovest Dachev, Matthias Plappert,  Slava Bushtruk, Ali Servet Donmez, Ricardo1980, pip8786, Danny Thuerin, Dennis Madsen
 */

#import "NSDate-Utilities.h"

#define DATE_COMPONENTS (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekOfYear |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

@implementation NSDate (Utilities)

#pragma mark Relative Dates

+ (NSDate *) dateWithDaysFromNow: (NSInteger) days
{
    // Thanks, Jim Morrison
	return [[NSDate date] dateByAddingDays:days];
}

+ (NSDate *) dateWithDaysBeforeNow: (NSInteger) days
{
    // Thanks, Jim Morrison
	return [[NSDate date] dateBySubtractingDays:days];
}

+ (NSDate *) dateTomorrow
{
	return [NSDate dateWithDaysFromNow:1];
}

+ (NSDate *) dateYesterday
{
	return [NSDate dateWithDaysBeforeNow:1];
}

+ (NSDate *) dateWithHoursFromNow: (NSInteger) dHours
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] + D_HOUR * dHours;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

+ (NSDate *) dateWithHoursBeforeNow: (NSInteger) dHours
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - D_HOUR * dHours;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

+ (NSDate *) dateWithMinutesFromNow: (NSInteger) dMinutes
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] + D_MINUTE * dMinutes;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

+ (NSDate *) dateWithMinutesBeforeNow: (NSInteger) dMinutes
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - D_MINUTE * dMinutes;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

+ (NSArray *)datesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSMutableArray *dates = [NSMutableArray array];
    NSDate *date;
    
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:fromDate toDate:toDate options:0];
    NSUInteger days = [components day] + 1;
    
    for (NSUInteger index = 0; index < days; ++index) {
        date = [toDate dateBySubtractingDays:index];
        [dates addObject:date];
    }
    return dates;
}


#pragma mark Comparing Dates

- (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:aDate];
	return ((components1.year == components2.year) &&
			(components1.month == components2.month) &&
			(components1.day == components2.day));
}

- (BOOL) isToday
{
	return [self isEqualToDateIgnoringTime:[NSDate date]];
}

- (BOOL) isTomorrow
{
	return [self isEqualToDateIgnoringTime:[NSDate dateTomorrow]];
}

- (BOOL) isYesterday
{
	return [self isEqualToDateIgnoringTime:[NSDate dateYesterday]];
}

// This hard codes the assumption that a week is 7 days
- (BOOL) isSameWeekAsDate: (NSDate *) aDate
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:aDate];
	
	// Must be same week of the year. 12/31 and 1/1 will both be week "1" if they are in the same week
	if (components1.weekOfYear != components2.weekOfYear) return NO;
	
	// Must have a time interval under 1 week. Thanks @aclark
	return (abs([self timeIntervalSinceDate:aDate]) < D_WEEK);
}

- (BOOL) isThisWeek
{
	return [self isSameWeekAsDate:[NSDate date]];
}

- (BOOL) isNextWeek
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] + D_WEEK;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return [self isSameWeekAsDate:newDate];
}

- (BOOL) isLastWeek
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - D_WEEK;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return [self isSameWeekAsDate:newDate];
}

// Thanks, mspasov
- (BOOL) isSameMonthAsDate: (NSDate *) aDate
{
    NSDateComponents *components1 = [CURRENT_CALENDAR components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self];
    NSDateComponents *components2 = [CURRENT_CALENDAR components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:aDate];
    return ((components1.month == components2.month) &&
            (components1.year == components2.year));
}

- (BOOL) isThisMonth
{
    return [self isSameMonthAsDate:[NSDate date]];
}

- (BOOL) isSameYearAsDate: (NSDate *) aDate
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:aDate];
	return (components1.year == components2.year);
}

- (BOOL) isThisYear
{
    // Thanks, baspellis
	return [self isSameYearAsDate:[NSDate date]];
}

- (BOOL) isNextYear
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:[NSDate date]];
	
	return (components1.year == (components2.year + 1));
}

- (BOOL) isLastYear
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:NSCalendarUnitYear fromDate:[NSDate date]];
	
	return (components1.year == (components2.year - 1));
}

- (BOOL) isEarlierThanDate: (NSDate *) aDate
{
	return ([self compare:aDate] == NSOrderedAscending);
}

- (BOOL) isLaterThanDate: (NSDate *) aDate
{
	return ([self compare:aDate] == NSOrderedDescending);
}

// Thanks, markrickert
- (BOOL) isInFuture
{
    return ([self isLaterThanDate:[NSDate date]]);
}

// Thanks, markrickert
- (BOOL) isInPast
{
    return ([self isEarlierThanDate:[NSDate date]]);
}


#pragma mark Roles
- (BOOL) isTypicallyWeekend
{
    NSDateComponents *components = [CURRENT_CALENDAR components:NSCalendarUnitWeekday fromDate:self];
    if ((components.weekday == 1) ||
        (components.weekday == 7))
        return YES;
    return NO;
}

- (BOOL) isTypicallyWorkday
{
    return ![self isTypicallyWeekend];
}

#pragma mark Adjusting Dates

- (NSDate *) dateByAddingDays: (NSInteger) dDays
{
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + D_DAY * dDays;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

- (NSDate *) dateBySubtractingDays: (NSInteger) dDays
{
	return [self dateByAddingDays: (dDays * -1)];
}

- (NSDate *) dateByAddingHours: (NSInteger) dHours
{
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + D_HOUR * dHours;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

- (NSDate *) dateBySubtractingHours: (NSInteger) dHours
{
	return [self dateByAddingHours: (dHours * -1)];
}

- (NSDate *) dateByAddingMinutes: (NSInteger) dMinutes
{
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + D_MINUTE * dMinutes;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

- (NSDate *) dateBySubtractingMinutes: (NSInteger) dMinutes
{
	return [self dateByAddingMinutes: (dMinutes * -1)];
}

- (NSDate *) dateAtStartOfDay
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	components.hour = 0;
	components.minute = 0;
	components.second = 0;
	return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)dateAtEndOfDay {
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
    components.hour = 23;
	components.minute = 59;
	components.second = 59;
    return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)dateAtStartOfMonth {
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
    components.day = 0;
    components.hour = 0;
	components.minute = 0;
	components.second = 0;
    return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)dateAtEndOfMonth {
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
    components.month = components.month + 1;
    components.day = -1;
    components.hour = 23;
	components.minute = 59;
	components.second = 59;
    return [CURRENT_CALENDAR dateFromComponents:components];
}


- (NSDateComponents *) componentsWithOffsetFromDate: (NSDate *) aDate
{
	NSDateComponents *dTime = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:aDate toDate:self options:0];
	return dTime;
}

#pragma mark Retrieving Intervals

- (NSInteger) minutesAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [self timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_MINUTE);
}

- (NSInteger) minutesBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:self];
	return (NSInteger) (ti / D_MINUTE);
}

- (NSInteger) hoursAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [self timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_HOUR);
}

- (NSInteger) hoursBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:self];
	return (NSInteger) (ti / D_HOUR);
}

- (NSInteger) daysAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [self timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_DAY);
}

- (NSInteger) daysBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:self];
	return (NSInteger) (ti / D_DAY);
}

// Thanks, dmitrydims
// I have not yet thoroughly tested this
- (NSInteger)distanceInDaysToDate:(NSDate *)anotherDate
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay fromDate:self toDate:anotherDate options:0];
    return components.day;
}

#pragma mark Decomposing Dates

- (NSInteger) nearestHour
{
	NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] + D_MINUTE * 30;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	NSDateComponents *components = [CURRENT_CALENDAR components:NSCalendarUnitHour fromDate:newDate];
	return components.hour;
}

- (NSInteger) hour
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.hour;
}

- (NSInteger) minute
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.minute;
}

- (NSInteger) seconds
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.second;
}

- (NSInteger) day
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.day;
}

- (NSInteger) month
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.month;
}

- (NSInteger) week
{
    return self.weekOfYear;
}

- (NSInteger) weekOfMonth
{
    NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
    return components.weekOfMonth;
}

- (NSInteger) weekOfYear
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.weekOfYear;
}

- (NSInteger) weekday
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.weekday;
}

- (NSInteger) nthWeekday // e.g. 2nd Tuesday of the month is 2
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.weekdayOrdinal;
}

- (NSInteger) year
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	return components.year;
}


// Time Since functions
- (NSString *)timeAgo
{
    NSDate *now = [NSDate date];
    NSInteger deltaSeconds = (NSInteger)(fabs([self timeIntervalSinceDate:now]));
    NSInteger deltaMinutes = (NSInteger)(deltaSeconds / 60.0);
    
    NSInteger minutes;
    
    if(deltaSeconds < 5)
    {
        return @"Just now";
    }
    else if(deltaSeconds < 60)
    {
        return [self stringFromFormat:@"%d seconds ago" withValue:deltaSeconds];
    }
    else if(deltaSeconds < 120)
    {
        return @"A minute ago";
    }
    else if (deltaMinutes < 60)
    {
        return [self stringFromFormat:@"%d minutes ago" withValue:deltaMinutes];
    }
    else if (deltaMinutes < 120)
    {
        return @"An hour ago";
    }
    else if (deltaMinutes < (24 * 60))
    {
        minutes = (NSInteger)floor(deltaMinutes/60);
        return [self stringFromFormat:@"%d hours ago" withValue:minutes];
    }
    else if (deltaMinutes < (24 * 60 * 2))
    {
        return @"Yesterday";
    }
    else if (deltaMinutes < (24 * 60 * 7))
    {
        minutes = (NSInteger)floor(deltaMinutes/(60 * 24));
        return [self stringFromFormat:@"%d days ago" withValue:minutes];
    }
    else if (deltaMinutes < (24 * 60 * 14))
    {
        return @"Last week";
    }
    else if (deltaMinutes < (24 * 60 * 31))
    {
        minutes = (NSInteger)floor(deltaMinutes/(60 * 24 * 7));
        return [self stringFromFormat:@"%d weeks ago" withValue:minutes];
    }
    else if (deltaMinutes < (24 * 60 * 61))
    {
        return @"Last month";
    }
    else if (deltaMinutes < (24 * 60 * 365.25))
    {
        minutes = (NSInteger)floor(deltaMinutes/(60 * 24 * 30));
        return [self stringFromFormat:@"%d months ago" withValue:minutes];
    }
    else if (deltaMinutes < (24 * 60 * 731))
    {
        return @"Last year";
    }
    
    minutes = (NSInteger)floor(deltaMinutes/(60 * 24 * 365));
    return [self stringFromFormat:@"%d years ago" withValue:minutes];
}

// Similar to timeAgo, but only returns "
- (NSString *)dateTimeAgo
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate * now = [NSDate date];
    NSDateComponents *components = [calendar components:
                                    NSCalendarUnitYear|
                                    NSCalendarUnitMonth|
                                    NSCalendarUnitWeekOfYear|
                                    NSCalendarUnitDay|
                                    NSCalendarUnitHour|
                                    NSCalendarUnitMinute|
                                    NSCalendarUnitSecond
                                               fromDate:self
                                                 toDate:now
                                                options:0];
    
    if (components.year >= 1)
    {
        if (components.year == 1)
        {
            return @"1 year ago";
        }
        return [self stringFromFormat:@"%d years ago" withValue:components.year];
    }
    else if (components.month >= 1)
    {
        if (components.month == 1)
        {
            return @"1 month ago";
        }
        return [self stringFromFormat:@"%d months ago" withValue:components.month];
    }
    else if (components.weekOfYear >= 1)
    {
        if (components.weekOfYear == 1)
        {
            return @"1 week ago";
        }
        return [self stringFromFormat:@"%d weeks ago" withValue:components.weekOfYear];
    }
    else if (components.day >= 1)    // up to 6 days ago
    {
        if (components.day == 1)
        {
            return @"1 day ago";
        }
        return [self stringFromFormat:@"%d days ago" withValue:components.day];
    }
    else if (components.hour >= 1)   // up to 23 hours ago
    {
        if (components.hour == 1)
        {
            return @"An hour ago";
        }
        return [self stringFromFormat:@"%d hours ago" withValue:components.hour];
    }
    else if (components.minute >= 1) // up to 59 minutes ago
    {
        if (components.minute == 1)
        {
            return @"A minute ago";
        }
        return [self stringFromFormat:@"%d minutes ago" withValue:components.minute];
    }
    else if (components.second < 5)
    {
        return @"Just now";
    }
    
    // between 5 and 59 seconds ago
    return [self stringFromFormat:@"%d seconds ago" withValue:components.second];
}



- (NSString *)dateTimeUntilNow
{
    NSDate * now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitHour
                                               fromDate:self
                                                 toDate:now
                                                options:0];
    
    if (components.hour >= 6) // if more than 6 hours ago, change precision
    {
        NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                                 inUnit:NSCalendarUnitEra
                                                forDate:self];
        NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                               inUnit:NSCalendarUnitEra
                                              forDate:now];
        
        NSInteger diffDays = endDay - startDay;
        if (diffDays == 0) // today!
        {
            NSDateComponents * startHourComponent = [calendar components:NSCalendarUnitHour fromDate:self];
            NSDateComponents * endHourComponent = [calendar components:NSCalendarUnitHour fromDate:self];
            if (startHourComponent.hour < 12 &&
                endHourComponent.hour > 12)
            {
                return @"This morning";
            }
            else if (startHourComponent.hour >= 12 &&
                     startHourComponent.hour < 18 &&
                     endHourComponent.hour >= 18)
            {
                return @"This afternoon";
            }
            return @"Today";
        }
        else if (diffDays == 1)
        {
            return @"Yesterday";
        }
        else
        {
            NSInteger startWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                      inUnit:NSCalendarUnitEra
                                                     forDate:self];
            NSInteger endWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                    inUnit:NSCalendarUnitEra
                                                   forDate:now];
            NSInteger diffWeeks = endWeek - startWeek;
            if (diffWeeks == 0)
            {
                return @"This week";
            }
            else if (diffWeeks == 1)
            {
                return @"Last week";
            }
            else
            {
                NSInteger startMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                           inUnit:NSCalendarUnitEra
                                                          forDate:self];
                NSInteger endMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                         inUnit:NSCalendarUnitEra
                                                        forDate:now];
                NSInteger diffMonths = endMonth - startMonth;
                if (diffMonths == 0)
                {
                    return @"This month";
                }
                else if (diffMonths == 1)
                {
                    return @"Last month";
                }
                else
                {
                    NSInteger startYear = [calendar ordinalityOfUnit:NSCalendarUnitYear
                                                              inUnit:NSCalendarUnitEra
                                                             forDate:self];
                    NSInteger endYear = [calendar ordinalityOfUnit:NSCalendarUnitYear
                                                            inUnit:NSCalendarUnitEra
                                                           forDate:now];
                    NSInteger diffYears = endYear - startYear;
                    if (diffYears == 0)
                    {
                        return @"This year";
                    }
                    else if (diffYears == 1)
                    {
                        return @"Last year";
                    }
                }
            }
        }
    }
    
    // anything else uses "time ago" precision
    return [self dateTimeAgo];
}



- (NSString *) stringFromFormat:(NSString *)format withValue:(NSInteger)value
{
    return [NSString stringWithFormat:format, value];
}

- (NSString *) timeAgoWithLimit:(NSTimeInterval)limit
{
    return [self timeAgoWithLimit:limit dateFormat:NSDateFormatterFullStyle andTimeFormat:NSDateFormatterFullStyle];
}

- (NSString *) timeAgoWithLimit:(NSTimeInterval)limit dateFormat:(NSDateFormatterStyle)dFormatter andTimeFormat:(NSDateFormatterStyle)tFormatter
{
    if (fabs([self timeIntervalSinceDate:[NSDate date]]) <= limit)
        return [self timeAgo];
    
    return [NSDateFormatter localizedStringFromDate:self
                                          dateStyle:dFormatter
                                          timeStyle:tFormatter];
}
@end
