//
//  NetTest.h
//  TCPConnectDemo
//
//  Created by HSDM10 on 2018/12/19.
//  Copyright © 2018年 HSDM10. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NetTestDelegate
@optional
// TCP连接结果，不是发送数据失败结果
-(void) onNetTestResult:(Boolean) result;
@end

@interface NetTest : NSObject
@property (weak, nonatomic) id<NetTestDelegate> delegate;

- (void)creatrCerver;
- (void)connect;
- (void)sendData;

@end

NS_ASSUME_NONNULL_END
