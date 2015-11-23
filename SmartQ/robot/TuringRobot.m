//
//  TuringRobot.m
//  SmartQ
//
//  Created by tropsci on 15/11/20.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "TuringRobot.h"
#import <AFNetworking/AFNetworking.h>

static NSString *const TURING_ROBOT_API_URL = @"http://www.tuling123.com/openapi/api";

static NSString *const TURING_ERROR_DOMAIN = @"Turing robot error";

static NSString *const TURING_API_KEY = @"85cf16d61197a2d4b3d2d01ee5dfe134";

static NSString *const TURING_ROBOT_USER_ID_KEY = @"TURING_ROBOT_USER_ID_KEY";

static const NSInteger RESPONSE_CODE_OK = 100000;
static const NSInteger ERROR_CODE_NO_QUESTION = 1;
static const NSInteger ERROR_CODE_KEY_ERROR                         = 40001;
static const NSInteger ERROR_CODE_EMPTY_INFO                        = 40002;
static const NSInteger ERROR_CODE_KEY_ERROR_OR_UNACTIVATE_ACCOUNT   = 40003;
static const NSInteger ERROR_CODE_OUT_OF_USE_TIMES                  = 40004;
static const NSInteger ERROR_CODE_NO_SUPPORT                        = 40005;
static const NSInteger ERROR_CODE_ROBOT_UPGRADING                   = 40006;
static const NSInteger ERROR_CODE_REQUEST_FORMATE_ERROR             = 40007;


@implementation TuringRobot {
    NSString *_turingRobotUserID;
}

+ (instancetype)sharedRobot {
    static TuringRobot * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _robotID = @"robot_003";
        
        _robotName = @"Turing";
        _robotAvator = @"Turing.png";
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSString *turingRobotUserID = [userDefault stringForKey:TURING_ROBOT_USER_ID_KEY];
        if (!turingRobotUserID) {
            turingRobotUserID = [[NSUUID UUID] UUIDString];
            [userDefault setObject:turingRobotUserID forKey:TURING_ROBOT_USER_ID_KEY];
            [userDefault synchronize];
        }
        _turingRobotUserID = turingRobotUserID;
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
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 15;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/json", nil];
    NSDictionary *parameters = @{
                                 @"key": TURING_API_KEY,
                                 @"info": question,
                                 @"userid": _turingRobotUserID,
                                 };
    [manager GET:TURING_ROBOT_API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             NSDictionary *responseDictionary = (NSDictionary *)responseObject;
             NSInteger resultCode = [[responseDictionary objectForKey:@"code"] integerValue];
             if (RESPONSE_CODE_OK == resultCode) {
                 NSString *responseString = [responseDictionary objectForKey:@"text"];
                 answerBlock(nil, responseString);
             } else {
                 NSError *error = [self errorForCode:resultCode];
                 answerBlock(error, nil);
             }
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             answerBlock(error, nil);
         }];
}


#pragma mark -
- (NSError *)errorForCode:(NSInteger)errorCode {
    NSSet *knownErrorCode = [NSSet setWithObjects:
                             @(ERROR_CODE_NO_QUESTION),
                             @(ERROR_CODE_KEY_ERROR),
                             @(ERROR_CODE_EMPTY_INFO),
                             @(ERROR_CODE_KEY_ERROR_OR_UNACTIVATE_ACCOUNT),
                             @(ERROR_CODE_OUT_OF_USE_TIMES),
                             @(ERROR_CODE_NO_SUPPORT),
                             @(ERROR_CODE_ROBOT_UPGRADING),
                             @(ERROR_CODE_REQUEST_FORMATE_ERROR),
                             nil];
    NSError *error = nil;
    if ([knownErrorCode containsObject:@(errorCode)]) {
        NSString *errorDescribe = @"Unknown Error";
        switch (errorCode) {
            case ERROR_CODE_NO_QUESTION:
                errorDescribe = @"No Question Input";
                break;
            case ERROR_CODE_KEY_ERROR:
                errorDescribe = @"Invalid Key";
                break;
            case ERROR_CODE_EMPTY_INFO:
                errorDescribe = @"Empty Info";
                break;
            case ERROR_CODE_KEY_ERROR_OR_UNACTIVATE_ACCOUNT:
                errorDescribe = @"Key Error Or Account Error";
                break;
            case ERROR_CODE_OUT_OF_USE_TIMES:
                errorDescribe = @"API Using Time Is Out of Allowable Number";
                break;
            case ERROR_CODE_NO_SUPPORT:
                errorDescribe = @"No Support Request";
                break;
            case ERROR_CODE_ROBOT_UPGRADING:
                errorDescribe = @"Server Is Upgrading";
                break;
            case ERROR_CODE_REQUEST_FORMATE_ERROR:
                errorDescribe = @"Request Formate Error";
                break;
            default:
                break;
        }
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: errorDescribe,
                                   };
        error = [NSError errorWithDomain:TURING_ERROR_DOMAIN code:errorCode userInfo:userInfo];
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Unknown Error",
                                   };
        error = [NSError errorWithDomain:TURING_ERROR_DOMAIN code:errorCode userInfo:userInfo];
    }
    return error;
}

@end
