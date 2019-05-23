//
//  TortoiseURLProtocol.h
//  Tortoise
//
//  Created by flexih on 2019/5/21.
//  Copyright © 2019 flexih. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TortoiseURLProtocol : NSURLProtocol

+ (void)inspectWKWebView;
+ (void)uninspectWKWebView;

@end

NS_ASSUME_NONNULL_END
