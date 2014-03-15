//
//  JEFUploaderProtocol 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

typedef void (^JEFUploaderCompletionBlock)(BOOL, NSURL *, NSError *);

NS_ENUM(NSInteger, JEFUploaderType) {
    JEFUploaderTypeDepositBox = 0,
    JEFUploaderTypeDropbox
};

@protocol JEFUploaderProtocol <NSObject>

+ (id <JEFUploaderProtocol>)uploader;

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(JEFUploaderCompletionBlock)completion;

@end
