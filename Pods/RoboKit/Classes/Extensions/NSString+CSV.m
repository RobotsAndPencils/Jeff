//
//  NSString+CSV.m
//  RoboKit
//
//  Created by Michael Beauregard on 11-06-02.
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

//  Originally from: http://www.macresearch.org/cocoa-scientists-part-xxvi-parsing-csv-data

#import "NSString+CSV.h"


@implementation NSString (CSV_Parsing)

-(NSArray *)csvRows {
    NSMutableArray *rows = [NSMutableArray array];
    
    // Get newline character set
    NSMutableCharacterSet *newlineCharacterSet = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
    
    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSet = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
    [importantCharactersSet formUnionWithCharacterSet:newlineCharacterSet];
    
    // Create scanner, and scan string
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    while ( ![scanner isAtEnd] ) {
        // MB: Use an autorelease pool within this loop to avoid piling up too much garbage for larger csv files
        @autoreleasepool {

            BOOL insideQuotes = NO;
            BOOL finishedRow = NO;
            NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
            NSMutableString *currentColumn = [NSMutableString string];
            while ( !finishedRow ) {

                NSString *tempString;
                if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
                    [currentColumn appendString:tempString];
                }
                
                if ( [scanner isAtEnd] ) {
                    if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                    finishedRow = YES;
                }
                else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
                    if ( insideQuotes ) {
                        // Add line break to column text
                        [currentColumn appendString:tempString];
                    }
                    else {
                        // End of row
                        if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                        finishedRow = YES;
                    }
                }
                else if ( [scanner scanString:@"\"" intoString:NULL] ) {
                    if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
                        // Replace double quotes with a single quote in the column string.
                        [currentColumn appendString:@"\""]; 
                    }
                    else {
                        // Start or end of a quoted string.
                        insideQuotes = !insideQuotes;
                    }
                }
                else if ( [scanner scanString:@"," intoString:NULL] ) {  
                    if ( insideQuotes ) {
                        [currentColumn appendString:@","];
                    }
                    else {
                        // This is a column separating comma
                        [columns addObject:currentColumn];
                        currentColumn = [NSMutableString string];
                        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
                    }
                }
            }
            if ( [columns count] > 0 ) [rows addObject:columns];
        }
    }
    
    return rows;
}

@end
