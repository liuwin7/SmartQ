//
//  RobotFactory.m
//  SmartQ
//
//  Created by tropsci on 15/11/19.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "RobotFactory.h"
#import "ITPKRobot.h"
#import "SimSimiRobot.h"
#import "TuringRobot.h"

@implementation RobotFactory

+ (nullable id<RobotProtocol>)robotForRobotID:(NSString *)robotID {
    if ([robotID isEqualToString:@"robot_001"]) {
        return [ITPKRobot sharedRobot];
    } else if ([robotID isEqualToString:@"robot_002"]) {
        return [SimSimiRobot sharedRobot];
    } else if ([robotID isEqualToString:@"robot_003"]) {
        return [TuringRobot sharedRobot];
    }
    return nil;
}

@end
