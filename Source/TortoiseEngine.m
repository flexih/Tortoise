//
//  TortoiseEngine.m
//  Tortoise
//
//  Created by flexih on 2019/5/23.
//  Copyright © 2019 flexih. All rights reserved.
//

#import "TortoiseEngine.h"

@interface TortoiseTaskInfo : NSObject
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) id<NSURLSessionDataDelegate> delegate;
@end

@implementation TortoiseTaskInfo
- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate {
	self = [super init];
	if (self != nil) {
		_task = task;
		_delegate = delegate;
	}
	return self;
}
@end

@interface TortoiseEngine ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, strong) NSMutableDictionary *taskInfoByTaskID;
@end

@implementation TortoiseEngine

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration {
	self = [super init];
	if (self) {
		if (configuration == nil) {
			configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		}

		_taskInfoByTaskID = [[NSMutableDictionary alloc] init];
		
		_sessionQueue = [[NSOperationQueue alloc] init];
		_sessionQueue.name = NSStringFromClass(self.class);
		_sessionQueue.maxConcurrentOperationCount = 1;
		
		_session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_sessionQueue];
		_session.sessionDescription = NSStringFromClass(self.class);
	}
	return self;
}

- (void)dealloc {
	[_session invalidateAndCancel];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate {
	__auto_type task = [self.session dataTaskWithRequest:request];
	__auto_type taskInfo = [[TortoiseTaskInfo alloc] initWithTask:task delegate:delegate];
	@synchronized (self) {
		self.taskInfoByTaskID[@(task.taskIdentifier)] = taskInfo;
	}
	return task;
}

- (TortoiseTaskInfo *)taskInfoForTask:(NSURLSessionTask *)task {
		TortoiseTaskInfo *result;
		@synchronized (self) {
			result = self.taskInfoByTaskID[@(task.taskIdentifier)];
		}
		return result;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
				newRequest:(NSURLRequest *)newRequest
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
	__auto_type taskInfo = [self taskInfoForTask:task];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
		[taskInfo.delegate URLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler];
	} else {
		completionHandler(newRequest);
	}
}

- (void)URLSession:(NSURLSession *)session
							task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
	__auto_type taskInfo = [self taskInfoForTask:task];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
		[taskInfo.delegate URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
	} else {
		completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
	}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
	__auto_type taskInfo = [self taskInfoForTask:task];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:needNewBodyStream:)]) {
		[taskInfo.delegate URLSession:session task:task needNewBodyStream:completionHandler];
	} else {
		completionHandler(nil);
	}
}

- (void)URLSession:(NSURLSession *)session
							task:(NSURLSessionTask *)task
	 didSendBodyData:(int64_t)bytesSent
		totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
	__auto_type taskInfo = [self taskInfoForTask:task];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
		[taskInfo.delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
	}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	__auto_type taskInfo = [self taskInfoForTask:task];
	@synchronized (self) {
		[self.taskInfoByTaskID removeObjectForKey:@(taskInfo.task.taskIdentifier)];
	}
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
		[taskInfo.delegate URLSession:session task:task didCompleteWithError:error];
	}
}

- (void)URLSession:(NSURLSession *)session
					dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
	__auto_type taskInfo = [self taskInfoForTask:dataTask];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
		[taskInfo.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
	} else {
		completionHandler(NSURLSessionResponseAllow);
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
	__auto_type taskInfo = [self taskInfoForTask:dataTask];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)]) {
		[taskInfo.delegate URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	__auto_type taskInfo = [self taskInfoForTask:dataTask];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
		[taskInfo.delegate URLSession:session dataTask:dataTask didReceiveData:data];
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
	__auto_type taskInfo = [self taskInfoForTask:dataTask];
	if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
		[taskInfo.delegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
	} else {
		completionHandler(proposedResponse);
	}
}

@end
