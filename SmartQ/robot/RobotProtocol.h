//
//  RobotProtocol.h
//  SmartQ
//
//  Created by tropsci on 15/11/18.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RobotAnswerBolck)(NSError *error, id answer);

/**
 *  All Robots must conform this protocol
 */
@protocol RobotProtocol <NSObject>

@property(nonatomic, strong)NSString *robotName;
@property(nonatomic, strong)NSString *robotAvator;
@property(nonatomic, readonly)NSString *robotID; // sender id

+ (instancetype)sharedRobot;

/**
 *  A delegate method
 *
 *  @param rebot       robot entity
 *  @param question    the question that robot request
 *  @param answerBlock response block
 */
- (void)ask:(id<RobotProtocol>)rebot something:(NSString *)question answerBlock:(RobotAnswerBolck)answerBlock;

@end
