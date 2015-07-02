//
//  ViewController.m
//  HMTest
//
//  Created by lilingang on 15/6/26.
//  Copyright (c) 2015年 lilingang. All rights reserved.
//

#import "ViewController.h"
#import "HMQRCodeReader.h"

@interface ViewController ()<HMQRCodeReaderDataSource,HMQRCodeReaderDelegate>

@property (nonatomic, strong) HMQRCodeReader *qrCodeReader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.qrCodeReader = [[HMQRCodeReader alloc] initWithParentView:self.view subRect:CGRectMake(60, 60, 200, 200)];
    self.qrCodeReader.delegate = self;
    self.qrCodeReader.dataSoure = self;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(60, 60, 200, 200)];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.5;
    [self.view addSubview:view];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(60, 280, 100, 100)];
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(aaaa) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    __weak ViewController *weakSelf = self;
    [self.qrCodeReader authorizationStatusWithReslutBlock:^(BOOL granted, BOOL denied) {
        if (granted) {
            [weakSelf.qrCodeReader startRunning];
        } else {
            
        }
    }];
    
}

- (void)aaaa{
    [self.qrCodeReader switchDeviceInput];
}

-(NSArray *)hmQRCodeReaderMetadataObjectTypes{
    return @[AVMetadataObjectTypeQRCode];
}

- (void)hmQRCodeReaderDidOutputMetadataObjectTypes:(NSString *)type stringValue:(NSString *)stringValue{
    NSLog(@"%@,%@",type,stringValue);
    [self.qrCodeReader stopRunning];
}

@end
