//
//  ViewController.m
//  Tortoise
//
//  Created by flexih on 2019/5/23.
//  Copyright © 2019 flexih. All rights reserved.
//

#import "ViewController.h"
#import "TortoiseURLProtocol.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	[TortoiseURLProtocol inspectWKWebView];
	[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.mafengwo.cn/i/12822142.html?origin=paopao_app"]]];
}


@end
