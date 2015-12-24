//
//  SimSimiRobot.m
//  SmartQ
//
//  Created by tropsci on 15/11/20.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "SimSimiRobot.h"
#import "AFNetworking.h"

static NSString *const SIMSIMI_ROBOT_API_URL = @"http://sandbox.api.simsimi.com/request.p";

static NSString *const SIMSIMI_ERROR_DOMAIN = @"SimSimi robot error";

static NSString *const SIMSIMI_API_KEY = @"20d8f86c-7633-418d-b739-69ab2355e771";

static const NSInteger ERROR_CODE_NO_QUESTION  = 444;

static const NSInteger ERROR_CODE_BAD_REQUEST  = 400;
static const NSInteger ERROR_CODE_UNAUTHORIZED = 401;
static const NSInteger ERROR_CODE_NOT_FOUND    = 404;
static const NSInteger ERROR_CODE_SERVER_ERROR = 500;


@implementation SimSimiRobot

+ (instancetype)sharedRobot {
    static SimSimiRobot * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _robotID = @"robot_002";

        _robotName = @"SimSimi";
        _robotAvator = @"SimSimi.png";
    }
    return self;
}

#pragma mark - Public Method

- (void)ask:(id<RobotProtocol>)rebot something:(NSString *)question answerBlock:(RobotAnswerBolck)answerBlock {
    NSAssert(answerBlock, @"Must assign a block");
    if (!question.length) {
        NSError *error = [self errorForCode:ERROR_CODE_NO_QUESTION];
        answerBlock(error, nil);
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 15;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    NSDictionary *parameters = @{
                                 @"key": SIMSIMI_API_KEY,
                                 @"text": question,
                                 @"lc": @"ch",
                                 @"ft": @"1.0",
                                 };
    
    [manager GET:SIMSIMI_ROBOT_API_URL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        NSInteger resultCode = [[responseDictionary objectForKey:@"result"] integerValue];
        if (100 == resultCode) {
            NSString *responseString = [responseDictionary objectForKey:@"response"];
            answerBlock(nil, responseString);
        } else {
            NSError *error = [self errorForCode:resultCode];
            answerBlock(error, nil);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        answerBlock(error, nil);
    }];
}

#pragma mark - 
- (NSError *)errorForCode:(NSInteger)errorCode {
    NSSet *knownErrorCode = [NSSet setWithObjects:
                             @(ERROR_CODE_NO_QUESTION),
                             @(ERROR_CODE_BAD_REQUEST),
                             @(ERROR_CODE_UNAUTHORIZED),
                             @(ERROR_CODE_NOT_FOUND),
                             @(ERROR_CODE_SERVER_ERROR),
                             nil];
    NSError *error = nil;
    if ([knownErrorCode containsObject:@(errorCode)]) {
        NSString *errorDescribe = @"Unknown Error";
        switch (errorCode) {
            case ERROR_CODE_NO_QUESTION:
                errorDescribe = @"No Question Input";
                break;
            case ERROR_CODE_BAD_REQUEST:
                errorDescribe = @"Bad Request";
                break;
            case ERROR_CODE_UNAUTHORIZED:
                errorDescribe = @"Unauthorized";
                break;
            case ERROR_CODE_NOT_FOUND:
                errorDescribe = @"Not Found";
                break;
            case ERROR_CODE_SERVER_ERROR:
                errorDescribe = @"Server Error";
                break;
            default:
                break;
        }
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: errorDescribe,
                                   };
        error = [NSError errorWithDomain:SIMSIMI_ERROR_DOMAIN code:errorCode userInfo:userInfo];
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Unknown Error",
                                   };
        error = [NSError errorWithDomain:SIMSIMI_ERROR_DOMAIN code:errorCode userInfo:userInfo];
    }
    return error;
}

@end
