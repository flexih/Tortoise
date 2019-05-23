//
//  TortoiseEngine.h
//  Tortoise
//
//  Created by flexih on 2019/5/23.
//  Copyright © 2019 flexih. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TortoiseEngine : NSObject<NSURLSessionDataDelegate>

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
