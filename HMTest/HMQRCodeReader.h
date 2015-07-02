//
//  HMQRCodeReader.h
//  HMTest
//
//  Created by lilingang on 15/7/2.
//  Copyright (c) 2015年 lilingang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>

@class UIView;

@protocol HMQRCodeReaderDataSource <NSObject>

- (NSArray *)hmQRCodeReaderMetadataObjectTypes;

@end

@protocol HMQRCodeReaderDelegate <NSObject>

- (void)hmQRCodeReaderDidOutputMetadataObjectTypes:(NSString *)type stringValue:(NSString *)stringValue;

@end

@interface HMQRCodeReader : NSObject

@property (nonatomic, weak) id<HMQRCodeReaderDelegate> delegate;
@property (nonatomic, weak) id<HMQRCodeReaderDataSource> dataSoure;

/**
 *  判断是否有后置摄像头
 *
 *  @return 有返回YES
 */
+ (BOOL)hasBackDevice;

/**
 *  唯一初始话方法
 *
 *  @param parentView 显示在哪个view上
 *  @param subRect    有效地识别区域
 *
 *  @return HMQRCodeReader 对象
 */
- (instancetype)initWithParentView:(UIView *)parentView subRect:(CGRect)subRect;

/**
 *  初始化完毕优先调用,请求权限
 *
 *  @param reslutBlock granted用户是否授权，denied 是否是用户拒绝,优先判断granted，granted为YES的情况下忽略第二个参数
 */
- (void)authorizationStatusWithReslutBlock:(void(^)(BOOL granted, BOOL denied))reslutBlock;

/**
 *  CaptureSession 开始运行 在authorizationStatusWithReslutBlock回调中使用
 */
- (void)startRunning;

/**
 *  CaptureSession 停止运行
 */
- (void)stopRunning;

/**
 *  判断CaptureSession是否正在运行
 *
 *  @return CaptureSession正在运行返回YES
 */

- (BOOL)isRuning;

/**
 *  在CaptureSession运行状态下切换摄像头
 */
- (void)switchDeviceInput;

@end
