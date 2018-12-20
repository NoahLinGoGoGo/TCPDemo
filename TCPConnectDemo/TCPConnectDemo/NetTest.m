//
//  NetTest.m
//  TCPConnectDemo
//
//  Created by HSDM10 on 2018/12/19.
//  Copyright © 2018年 HSDM10. All rights reserved.
//

#import "NetTest.h"
#import "GCDAsyncSocket.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
@interface NetTest ()<GCDAsyncSocketDelegate>
{
    int port;
    NSString *host;
    long TAG_SEND;
}


@property (strong, nonatomic)GCDAsyncSocket * serverSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSockets;

@end

@implementation NetTest

- (id)init {
    self = [super init];
    
    host = [self getIPAddressesToDo:YES];
    if (!host) {
        host = @"127.0.0.1";
    }
    port = 11000;
    NSLog(@"ipStr: %@ port:%d",host,port);
    
    return self;
}


- (void)creatrCerver {
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self      delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError * error = nil;
    [self.serverSocket acceptOnPort:port error:&error];

    if (error) {
        NSLog(@"initAsyncSocket [error description]:%@", [error description]);
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    } else {
        NSLog(@"Tcp Server Listen...");
    }
}

- (void)connect {
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:port error:&error];
    if (error) {
        NSLog(@"Connect failed! host=%@, port=%d, error=%@", host, port, error);
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    }
}

- (void)sendData {
    [self.clientSocket writeData:[@"send teststrteststr" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1. tag:TAG_SEND];
}


#pragma mark- GCDAsyncserverSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    self.clientSockets = newSocket;
    NSLog(@"GCDAsyncSocket:didAcceptNewSocket");
    [newSocket readDataWithTimeout:-1 tag:0];
    
    if (self.delegate) {
        [self.delegate onNetTestResult:true];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"didConnectToHost host=%@ port=%d", host, port);
    //[sock writeData:[@"connect teststr" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1. tag:TAG_SEND];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString * receive = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"GCDAsyncSocket receive:%@ receive.length:%lu", receive, (unsigned long)receive.length);
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    NSLog(@"socketDidDisconnect socket=%@, error=%@", sock, err);
    if (sock == self.clientSocket && err) {
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"didWriteDataWithTag tag:%ld",tag);
}

#pragma mark - IP地址
//获取设备当前网络IP地址
- (NSString *)getIPAddressesToDo:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddressesToDo];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

//获取所有相关IP信息
- (NSDictionary *)getIPAddressesToDo
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
@end
