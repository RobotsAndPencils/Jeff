//
//  NSObject+JTCancelableScheduledBlock.m
//
//  Created by James Tang on 20/08/2011.
//  http://ioscodesnippet.tumblr.com/
//

#import "NSObject+CancelableScheduledBlock.h"



@implementation NSObject (CancelableScheduledBlock)


#pragma mark - Private

- (void)delayedAddOperation:(NSOperation *)operation {
	
    [[NSOperationQueue currentQueue] addOperation:operation];
	
}

#pragma mark - Public

- (void)RBK_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay {
    
    if (!block) return;
	
    [self performSelector:@selector(delayedAddOperation:)
	 
               withObject:[NSBlockOperation blockOperationWithBlock:block]
	 
               afterDelay:delay];
	
}



- (void)RBK_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel {
    if (cancel) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    [self RBK_performBlock:block afterDelay:delay];
	
}

@end
