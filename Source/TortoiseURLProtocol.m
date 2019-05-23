//
//  TortoiseURLProtocol.m
//  Tortoise
//
//  Created by flexih on 2019/5/21.
//  Copyright © 2019 flexih. All rights reserved.
//

#import "TortoiseURLProtocol.h"
#import "TortoiseEngine.h"

static NSString *kTortoiseURLProtocolKey = @"kTortoiseURLProtocolKey";
static NSString *schemaHTTP = @"http";
static NSString *schemaHTTPS = @"https";
//@"WKBrowsingContextController"
static int8_t className[] = {0x57, 0x4b, 0x42, 0x72, 0x6f, 0x77, 0x73, 0x69, 0x6e, 0x67, 0x43, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x43, 0x6f, 0x6e, 0x74, 0x72, 0x6f, 0x6c, 0x6c, 0x65, 0x72};
//@"registerSchemeForCustomProtocol:"
static int8_t registerSelector[] = {0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x53, 0x63, 0x68, 0x65, 0x6d, 0x65, 0x46, 0x6f, 0x72, 0x43, 0x75, 0x73, 0x74, 0x6f, 0x6d, 0x50, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x3a};

//@"unregisterSchemeForCustomProtocol"
static int8_t unregisterSelector[] = {0x75, 0x6e, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x53, 0x63, 0x68, 0x65, 0x6d, 0x65, 0x46, 0x6f, 0x72, 0x43, 0x75, 0x73, 0x74, 0x6f, 0x6d, 0x50, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x3a};
#ifndef ARRAY_SIZE
#define ARRAY_SIZE(array) sizeof(array)/sizeof(array[0])
#endif
#define SEL_NAME(bytes) [[NSString alloc] initWithBytesNoCopy:bytes length:ARRAY_SIZE(bytes) encoding:NSASCIIStringEncoding freeWhenDone:NO]

@interface TortoiseURLProtocol ()<NSURLSessionDataDelegate>
@property (nonatomic, copy) NSURLSessionTask *task;
@end

@implementation TortoiseURLProtocol

+ (void)inspectWKWebView {
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"v@:@"]];
	invocation.target = NSClassFromString(SEL_NAME(className));
	invocation.selector = NSSelectorFromString(SEL_NAME(registerSelector));
	[invocation setArgument:&schemaHTTP atIndex:2];
	[invocation invoke];
	[invocation setArgument:&schemaHTTPS atIndex:2];
	[invocation invoke];
	[NSURLProtocol registerClass:self];
}

+ (void)uninspectWKWebView {
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"v@:@"]];
	invocation.target = NSClassFromString(SEL_NAME(className));
	invocation.selector = NSSelectorFromString(SEL_NAME(unregisterSelector));
	[invocation setArgument:&schemaHTTP atIndex:2];
	[invocation invoke];
	[invocation setArgument:&schemaHTTPS atIndex:2];
	[invocation invoke];
	[NSURLProtocol unregisterClass:self];
}

+ (TortoiseEngine *)sharedEngine {
	static TortoiseEngine *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__auto_type configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.protocolClasses = @[self];
		instance = [[TortoiseEngine alloc] initWithConfiguration:configuration];
	});
	return instance;
}

- (void)startLoading {
	NSMutableURLRequest *recursiveRequest = [[self request] mutableCopy];
	[[self class] setProperty:@YES forKey:kTortoiseURLProtocolKey inRequest:recursiveRequest];
	self.task = [[self.class sharedEngine] dataTaskWithRequest:recursiveRequest delegate:self];
	[self.task resume];
}

- (void)stopLoading {
	if (self.task) {
		[self.task cancel];
		self.task = nil;
	}
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
	return [super requestIsCacheEquivalent:a toRequest:b];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	if ([NSURLProtocol propertyForKey:kTortoiseURLProtocolKey inRequest:request]) {
		return false;
	}
	__auto_type scheme = request.URL.scheme.lowercaseString;
	if (([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) &&
			[request.HTTPMethod compare:@"GET" options:NSCaseInsensitiveSearch] == 0) {
		return true;
	}
	return false;
}

- (void)URLSession:(NSURLSession *)session
					dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
	[self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
	completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	[self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
	if (error == nil) {
		[self.client URLProtocolDidFinishLoading:self];
	} else if ([[error domain] isEqual:NSURLErrorDomain] && ([error code] == NSURLErrorCancelled)) {
	} else {
		[self.client URLProtocol:self didFailWithError:error];
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
	completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
	NSMutableURLRequest *redirectRequest;
	redirectRequest = [request mutableCopy];
	[[self class] removePropertyForKey:kTortoiseURLProtocolKey inRequest:redirectRequest];
	[self.client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
	[self.task cancel];
	[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSURLCredential *credential;
		if ([[challenge.protectionSpace authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust]) {
			SecTrustRef trust = [[challenge protectionSpace] serverTrust];
			if (trust) {
				OSStatus err = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)@[]);
				if (err == noErr) {
					err = SecTrustSetAnchorCertificatesOnly(trust, false);
					if (err == noErr) {
						SecTrustResultType trustResult;
						err = SecTrustEvaluate(trust, &trustResult);
						if (err == noErr) {
							if ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified)) {
								credential = [NSURLCredential credentialForTrust:trust];
							}
						}
					}
				}
			}
		}
		if (credential) {
			completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
		} else {
			completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
		}
	});
}

@end
