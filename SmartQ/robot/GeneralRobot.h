//
//  GeneralRobot.h
//  SmartQ
//
//  Created by tropsci on 15/11/20.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RobotProtocol.h"

@interface GeneralRobot : NSObject <RobotProtocol> {
    // protocol property
    NSString *_robotName;
    NSString *_robotAvator;
    NSString *_robotID;
}


@end
