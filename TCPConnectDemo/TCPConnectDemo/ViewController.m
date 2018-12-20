//
//  ViewController.m
//  TCPConnectDemo
//
//  Created by HSDM10 on 2018/12/19.
//  Copyright © 2018年 HSDM10. All rights reserved.
//

#import "ViewController.h"
#import "NetTest.h"

@interface ViewController ()<NetTestDelegate>
@property (strong, nonatomic) NetTest* netTest;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.netTest = [[NetTest alloc] init];
    self.netTest.delegate = self;
}


- (IBAction)creatrCerver:(UIButton *)sender {
    [self.netTest creatrCerver];
}

- (IBAction)connect:(UIButton *)sender {
    [self.netTest connect];
}

- (IBAction)sendData:(UIButton *)sender {
    [self.netTest sendData];
}

-(void) onNetTestResult:(Boolean) result {
    NSLog(@"onNetTestResult: %d", result);
}

#pragma mark- GCDAsyncserverSocketDelegate

@end
