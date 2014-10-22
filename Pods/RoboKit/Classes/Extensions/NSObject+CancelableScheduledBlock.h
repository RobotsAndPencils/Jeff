//
//  NSObject+JTCancelableScheduledBlock.h
//
//  Created by James Tang on 20/08/2011.
//  http://ioscodesnippet.tumblr.com/
//

@interface NSObject (CancelableScheduledBlock)



- (void)RBK_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

- (void)RBK_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel;



@end
