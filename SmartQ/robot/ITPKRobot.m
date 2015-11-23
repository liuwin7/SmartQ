//
//  ITPKRobot.m
//  SmartQ
//
//  Created by tropsci on 15/11/18.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "ITPKRobot.h"
#import <AFNetworking/AFNetworking.h>

static NSString *const ITPK_ROBOT_API_URL = @"http://i.itpk.cn/api.php";

static NSString *const ITPK_ERROR_DOMAIN = @"ITPK robot error";

static NSString *const ITPK_API_KEY = @"a76e45663ab27eae5e48160a9f9e5d34";
static NSString *const ITPK_API_SECRET = @"2uyxxz9qnl7o";

static const NSInteger ERROR_CODE_NO_QUESTION = 1;

@implementation ITPKRobot

+ (instancetype)sharedRobot {
    static ITPKRobot * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _robotID = @"robot_001";
        _robotName = @"茉莉";
        _robotAvator = @"moly.png";
    }
    return self;
}

#pragma mark - Public Method

- (void)ask:(id<RobotProtocol>)rebot something:(NSString *)question answerBlock:(RobotAnswerBolck)answerBlock {
    NSAssert(answerBlock, @"Must assign a block");
    if (!question.length) {
        NSError *error = [NSError errorWithDomain:ITPK_ERROR_DOMAIN code:ERROR_CODE_NO_QUESTION userInfo:@{NSLocalizedDescriptionKey: @"No question input"}];
        answerBlock(error, nil);
        return;
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 15;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    NSDictionary *parameters = @{
                                 @"type": @"json",
                                 @"api_key": ITPK_API_KEY,
                                 @"api_secret": ITPK_API_SECRET,
                                 @"question": question,
                                 @"limit": @(7),
                                 };
    [manager GET:ITPK_ROBOT_API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             answerBlock(nil, responseObject);
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             if (error.code == 3840) {
                 answerBlock(nil, operation.responseString);
                 return;
             }
             answerBlock(error, nil);
         }];
}

@end
