//
//  HMQRCodeReader.m
//  HMTest
//
//  Created by lilingang on 15/7/2.
//  Copyright (c) 2015年 lilingang. All rights reserved.
//

#import "HMQRCodeReader.h"
#import <UIKit/UIKit.h>

@interface HMQRCodeReader ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, copy) NSString *mediaType;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, assign) CGRect subRect;

@property (nonatomic, strong) AVCaptureMetadataOutput    *metadataOutput;
@property (nonatomic, strong) AVCaptureSession           *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation HMQRCodeReader

- (instancetype)initWithParentView:(UIView *)parentView subRect:(CGRect)subRect{
    self = [super init];
    if (self) {
        self.parentView = parentView;
        self.subRect = subRect;
        self.mediaType = AVMediaTypeVideo;
        
        //device
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:self.mediaType];
        
        // Input
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        
        // Output
        self.metadataOutput =[[AVCaptureMetadataOutput alloc] init];
        [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        // Session
        self.session = [[AVCaptureSession alloc] init];
        [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
        if ([self.session canAddInput:deviceInput]) {
            [self.session addInput:deviceInput];
        }
        if ([self.session canAddOutput:self.metadataOutput]) {
            [self.session addOutput:self.metadataOutput];
        }
        self.metadataOutput.rectOfInterest = [self rectOfInterestWithSuperRect:self.parentView.bounds subRect:self.subRect];
        
        // Preview
        self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.videoPreviewLayer.videoGravity =AVLayerVideoGravityResizeAspectFill;
        self.videoPreviewLayer.frame = self.parentView.bounds;
        [self.parentView.layer addSublayer:self.videoPreviewLayer];
        
        [self configureDevice:device];
    }
    return self;
}

#pragma mark - Public Methods

- (void)authorizationStatusWithReslutBlock:(void(^)(BOOL granted, BOOL denied))reslutBlock{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:self.mediaType];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined: {//用户尚未做出了选择这个应用程序的问候
            __weak HMQRCodeReader *weakSelf = self;
            [AVCaptureDevice requestAccessForMediaType:self.mediaType completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateMetadataObjectTypes];
                    if (reslutBlock) {
                        reslutBlock(granted,YES);
                    }
                });
            }];
            break;
        }
        case AVAuthorizationStatusRestricted: {//此应用程序没有被授权访问的照片数据。可能是家长控制权限
            if (reslutBlock) {
                reslutBlock(NO,NO);
            }
            break;
        }
        case AVAuthorizationStatusDenied: {  //用户已经明确否认了这一照片数据的应用程序访问.
            if (reslutBlock) {
                reslutBlock(NO,YES);
            }
            break;
        }
        case AVAuthorizationStatusAuthorized: {//用户已授权应用访问照片数据
            [self updateMetadataObjectTypes];
            if (reslutBlock) {
                reslutBlock(YES,NO);
            }
            break;
        }
        default: {
            break;
        }
    }
}

- (void)startRunning{
    if (![self isRuning]) {
        [self.session startRunning];
    }
}

- (void)stopRunning{
    if ([self isRuning]) {
        [self.session stopRunning];
    }
}

- (BOOL)isRuning{
    return self.session.isRunning;
}

- (void)switchDeviceInput{
    if (![self isRuning]) {
        return;
    }
    for ( AVCaptureDeviceInput *input in self.session.inputs ) {
        AVCaptureDevice *device = input.device;
        if ([device hasMediaType:self.mediaType]) {
            
            AVCaptureDevice *newDevice = nil;
            if (device.position == AVCaptureDevicePositionFront){
                newDevice = [HMQRCodeReader deviceWithPosition:AVCaptureDevicePositionBack];
            } else {
                newDevice = [HMQRCodeReader deviceWithPosition:AVCaptureDevicePositionFront];
            }
            AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:nil];
            
            [self.session beginConfiguration];
            [self.session removeInput:input];
            [self.session addInput:newInput];
            [self.session commitConfiguration];
            [self configureDevice:newDevice];
            

            break;
        }
    }
}

+ (BOOL)hasBackDevice{
    if ([self deviceWithPosition:AVCaptureDevicePositionBack]) {
        return YES;
    } else {
        return nil;
    }
}

#pragma mark - Private Methods

+ (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position{
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (void)configureDevice:(AVCaptureDevice *)device{
    NSError *error = nil;
    [device lockForConfiguration:&error];
    
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    if ([device isFocusModeSupported:focusMode]) {
        [device setFocusMode:focusMode];
    }
    
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    if ([device isExposureModeSupported:exposureMode]) {
        [device setExposureMode:exposureMode];
    }
    
    AVCaptureWhiteBalanceMode whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    if ([device isWhiteBalanceModeSupported:whiteBalanceMode]) {
        [device setWhiteBalanceMode:whiteBalanceMode];
    }
    
    [device unlockForConfiguration];
}

- (void)updateMetadataObjectTypes{
    NSArray *metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    if (self.dataSoure && [self.dataSoure respondsToSelector:@selector(hmQRCodeReaderMetadataObjectTypes)]) {
        metadataObjectTypes = [self.dataSoure hmQRCodeReaderMetadataObjectTypes];
    }
    NSSet *availableSet = [NSSet setWithArray:[self.metadataOutput availableMetadataObjectTypes]];
    if ([availableSet count] > 0) {
        NSMutableArray *disableArray = [[NSMutableArray alloc] init];
        for (NSString *string in metadataObjectTypes) {
            if (![availableSet containsObject:string]) {
                [disableArray addObject:string];
            }
        }
        NSLog(@"unAvailableMetadataObjectTypes：%@",disableArray);
        self.metadataOutput.metadataObjectTypes = metadataObjectTypes;
    }
}


- (CGRect)rectOfInterestWithSuperRect:(CGRect)rect subRect:(CGRect)subRect{
    CGSize size = rect.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920./1080.;  //使用了1080p的图像输出
    CGRect rectOfInterest = rect;
    if (p1 < p2) {
        CGFloat fixHeight = size.width * 1920. / 1080.;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        rectOfInterest = CGRectMake((subRect.origin.y + fixPadding)/fixHeight,
                                    subRect.origin.x/size.width,
                                    subRect.size.height/fixHeight,
                                    subRect.size.width/size.width);
    } else {
        CGFloat fixWidth = size.height * 1080. / 1920.;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        rectOfInterest = CGRectMake(subRect.origin.y/size.height,
                                    (subRect.origin.x + fixPadding)/fixWidth,
                                    subRect.size.height/size.height,
                                    subRect.size.width/fixWidth);
    }
    return rectOfInterest;
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(hmQRCodeReaderDidOutputMetadataObjectTypes:stringValue:)]) {
            [self.delegate hmQRCodeReaderDidOutputMetadataObjectTypes:object.type stringValue:object.stringValue];
        }
    }
}

@end
