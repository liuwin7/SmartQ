//
//  GeneralRobot.m
//  SmartQ
//
//  Created by tropsci on 15/11/20.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "GeneralRobot.h"

@implementation GeneralRobot

+ (instancetype)sharedRobot {
    NSAssert(YES, @"Must override this method in subclass");
    return nil;
}

- (void)ask:(id<RobotProtocol>)rebot something:(NSString *)question answerBlock:(RobotAnswerBolck)answerBlock {
    NSAssert(YES, @"Must override this method in subclass");
}

#pragma mark - Properties

- (NSString *)robotName {
    return _robotName;
}

- (void)setRobotName:(NSString *)robotName {
    _robotName = robotName;
}

- (NSString *)robotAvator {
    return _robotAvator;
}

- (void)setRobotAvator:(NSString *)robotAvator {
    _robotAvator = robotAvator;
}

- (NSString *)robotID {
    return _robotID;
}


@end
