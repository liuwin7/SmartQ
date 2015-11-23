//
//  RobotFactory.h
//  SmartQ
//
//  Created by tropsci on 15/11/19.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RobotProtocol.h"

@interface RobotFactory : NSObject

+ (nullable id<RobotProtocol>)robotForRobotID:(nonnull NSString *)robotID;

@end
