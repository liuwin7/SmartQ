//
//  ChatRobotDB.h
//  SmartQ
//
//  Created by tropsci on 15/11/19.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RobotProtocol.h"
#import <JSQMessagesViewController/JSQMessage.h>

extern NSInteger const kMESSAGE_STATE_PENDDING;
extern NSInteger const kMESSAGE_STATE_SUCCESS;
extern NSInteger const kMESSAGE_STATE_FAILURE;

extern NSInteger const kMESSAGE_DIRECTION_INCOMING;
extern NSInteger const kMESSAGE_DIRECTION_OUTGOING;

@interface ChatRobotDB : NSObject

+ (nonnull instancetype)sharedInstance;

+ (BOOL)robotDatabaseReady;

#pragma mark - 查询

- (nonnull NSArray <RobotProtocol> *)allRobots;

//- (nullable id<RobotProtocol>)robotForSenderID:(nonnull NSString *)senderID;

- (nonnull NSArray <JSQMessage *> *)chatMessageWithRobot:(nonnull id<RobotProtocol>)robot;

- (nonnull NSArray <JSQMessage *> *)chatMessageWithRobot:(nonnull id<RobotProtocol>)robot beforeMessage:(nullable JSQMessage *)baseMessage messageCount:(NSUInteger)count;

#pragma mark - 增加

- (BOOL)addRobot:(nonnull id<RobotProtocol>)robot;

- (NSInteger)addMessage:(nonnull JSQMessage *)message
               senderID:(nonnull NSString *)senderID
                robotID:(nonnull NSString *)robotID
                  state:(NSInteger)state
              direction:(NSInteger)direction;

#pragma mark - 删除

- (BOOL)deleteMessage:(nonnull JSQMessage *)message;

#pragma mark - 修改

- (BOOL)updateMessageID:(NSInteger)messageID state:(NSInteger)state;

@end
