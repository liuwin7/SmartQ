//
//  ChatRobotDB.m
//  SmartQ
//
//  Created by tropsci on 15/11/19.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "ChatRobotDB.h"
#import "RobotFactory.h"
#import <FMDB/FMDB.h>

NSString *const DATABASE_PATH = @"/Documents/database.db";

NSInteger const kMESSAGE_STATE_PENDDING = -1;
NSInteger const kMESSAGE_STATE_SUCCESS = 1;
NSInteger const kMESSAGE_STATE_FAILURE = 0;

NSInteger const kMESSAGE_DIRECTION_INCOMING = 1;
NSInteger const kMESSAGE_DIRECTION_OUTGOING = 0;

@implementation ChatRobotDB {
    FMDatabase *_database;
}

+ (BOOL)robotDatabaseReady {
    NSString *dbFilePath = [NSHomeDirectory() stringByAppendingString:DATABASE_PATH];
    BOOL dbFileExist = [[NSFileManager defaultManager] fileExistsAtPath:dbFilePath isDirectory:NULL];
    return dbFileExist;
}

+ (nonnull instancetype)sharedInstance {
    static ChatRobotDB *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _database = [FMDatabase databaseWithPath:[NSHomeDirectory() stringByAppendingString:DATABASE_PATH]];
        if (![self createDatabase]) {
            return nil;
        }
    }
    return self;
}

#pragma mark --

- (BOOL)createDatabase {
    if (![_database open]) {
        NSLog(@"Create database failed %@", [_database lastError]);
        return NO;
    }
    /* RobotTable
     db layout
     __________________
     robot_id       text primary key
     robot_name     text // localized name
     robot_avator   text // image file path
     
     */
    NSString *createRobotTableSQL = @"CREATE TABLE IF NOT EXISTS RobotTable(robot_id TEXT primary key, robot_name TEXT, robot_avator TEXT)";
    
    /* ChatMessageTable
     db layout
     __________________
     message_id         integer primary key
     robot_id           text // foreign key in RobotTable. If the message is outgoing
     sender_id          text // message sender id
     message_content    text // message text
     message_date       text // message received or sended date
     message_direction  integer  // 0 if outgoing message, 1 if incoming message
     */
    NSString *createChatMessageTableSQL = @"CREATE TABLE IF NOT EXISTS ChatMessageTable(message_id INTEGER primary key, robot_id TEXT, sender_id TEXT, message_content TEXT, message_date TEXT, message_state INTEGER, message_direction INTEGER, FOREIGN KEY(robot_id) REFERENCES RobotTable(robot_id))";
    
    [_database beginTransaction];
    [_database executeUpdate:createRobotTableSQL];
    [_database executeUpdate:createChatMessageTableSQL];
    BOOL success = [_database commit];
    if (!success) {
        NSLog(@"Create database failed %@", [_database lastError]);
    }
    [_database close];
    return success;
}

#pragma mark - 查询

- (nonnull NSArray <RobotProtocol> *)allRobots {
    NSMutableArray<RobotProtocol> *robots = [NSMutableArray<RobotProtocol> array];
    if (![_database open]) {
        NSLog(@"Select robots failed %@", [_database lastError]);
        return robots;
    }
    NSString *selectRobotSQL = @"SELECT * FROM RobotTable";
    FMResultSet *resultSet = [_database executeQuery:selectRobotSQL];
    while ([resultSet next]) {
        NSString *robotID = [resultSet stringForColumn:@"robot_id"];
        NSString *robotName = [resultSet stringForColumn:@"robot_name"];
        NSString *robotAvator = [resultSet stringForColumn:@"robot_avator"];
        
        id<RobotProtocol> robot = [RobotFactory robotForRobotID:robotID];
        [robot setRobotName:robotName];
        [robot setRobotAvator:robotAvator];
        
        [robots addObject:robot];
    }
    [_database close];
    return [robots copy];
}

//- (nullable id<RobotProtocol>)robotForSenderID:(nonnull NSString *)senderID {
//    
//}

- (nonnull NSArray <JSQMessage *> *)chatMessageWithRobot:(nonnull id<RobotProtocol>)robot {
    NSMutableArray<JSQMessage *> *historyMessages = [NSMutableArray<JSQMessage *> array];
    if (![_database open]) {
        NSLog(@"Select Message failed %@", [_database lastError]);
        return historyMessages;
    }
    NSString *selectMessageSQL = @"SELECT * FROM RobotTable as a JOIN ChatMessageTable as b ON a.robot_id = b.robot_id WHERE a.robot_id = :robot_id ORDER BY message_date ASC";
    NSDictionary *parameters = @{
                                 @"robot_id": [robot robotID],
                                 };
    FMResultSet *resultSet = [_database executeQuery:selectMessageSQL withParameterDictionary:parameters];
    while ([resultSet next]) {
        NSString *senderID = [resultSet stringForColumn:@"sender_id"];
        NSInteger messageDirection = [resultSet intForColumn:@"message_direction"];
        NSString *robotName = [resultSet stringForColumn:@"robot_name"];
        NSDate *messageDate = [resultSet dateForColumn:@"message_date"];
        NSString *messageContent = [resultSet stringForColumn:@"message_content"];
        NSString *displayName = nil;
        if (messageDirection == kMESSAGE_DIRECTION_INCOMING) {
            displayName = robotName;
        } else {
            displayName = @"Me";
        }
        JSQMessage *jsqMessage = [[JSQMessage alloc] initWithSenderId:senderID
                                                    senderDisplayName:displayName
                                                                 date:messageDate
                                                                 text:messageContent];
        [historyMessages addObject:jsqMessage];
    }
    return [NSArray<JSQMessage *> arrayWithArray:historyMessages];
}

- (nonnull NSArray <JSQMessage *> *)chatMessageWithRobot:(nonnull id<RobotProtocol>)robot beforeMessage:(nullable JSQMessage *)baseMessage messageCount:(NSUInteger)count {
    
    if (!count) {
        return [NSArray array];
    }
    
    if (!baseMessage) {
        NSArray *array = [self chatMessageWithRobot:robot];
        if (count > [array count]) {
            count = [array count];
        }
        NSRange messageRange = NSMakeRange([array count] - count, count);
        return [array subarrayWithRange:messageRange];
    }
    
    NSMutableArray<JSQMessage *> *historyMessages = [NSMutableArray<JSQMessage *> array];
    if (![_database open]) {
        NSLog(@"Select Message failed %@", [_database lastError]);
        return historyMessages;
    }
    NSString *selectMessageSQL = @"SELECT * FROM RobotTable as a JOIN ChatMessageTable as b ON a.robot_id = b.robot_id WHERE a.robot_id = :robot_id AND b.message_date < :baseMessageDate ORDER BY message_date ASC LIMIT :messageCount";
    NSDictionary *parameters = @{
                                 @"robot_id": [robot robotID],
                                 @"baseMessageDate": baseMessage.date,
                                 @"messageCount": @(count),
                                 };
    FMResultSet *resultSet = [_database executeQuery:selectMessageSQL withParameterDictionary:parameters];
    while ([resultSet next]) {
        NSString *senderID = [resultSet stringForColumn:@"sender_id"];
        NSInteger messageDirection = [resultSet intForColumn:@"message_direction"];
        NSString *robotName = [resultSet stringForColumn:@"robot_name"];
        NSDate *messageDate = [resultSet dateForColumn:@"message_date"];
        NSString *messageContent = [resultSet stringForColumn:@"message_content"];
        NSString *displayName = nil;
        if (messageDirection == kMESSAGE_DIRECTION_INCOMING) {
            displayName = robotName;
        } else {
            displayName = @"Me";
        }
        JSQMessage *jsqMessage = [[JSQMessage alloc] initWithSenderId:senderID
                                                    senderDisplayName:displayName
                                                                 date:messageDate
                                                                 text:messageContent];
        [historyMessages addObject:jsqMessage];
    }
    return [NSArray<JSQMessage *> arrayWithArray:historyMessages];
}

#pragma mark - 增加

- (BOOL)addRobot:(nonnull id<RobotProtocol>)robot {
    if (![_database open]) {
        NSLog(@"Insert robot failed %@", [_database lastError]);
        return NO;
    }
    NSString *insertRobotSQL = @"INSERT INTO RobotTable(robot_id, robot_name, robot_avator) VALUES (:robot_id, :robot_name, :robot_avator)";
    NSDictionary *parameters = @{
                                 @"robot_id": [robot robotID],
                                 @"robot_name": [robot robotName],
                                 @"robot_avator": [robot robotAvator],
                                 };
    BOOL success = [_database executeUpdate:insertRobotSQL withParameterDictionary:parameters];
    if (!success) {
        NSLog(@"Insert robot failed %@", [_database lastError]);
    }
    [_database close];
    return success;
}

- (NSInteger)addMessage:(nonnull JSQMessage *)message
               senderID:(nonnull NSString *)senderID
                robotID:(nonnull NSString *)robotID
                  state:(NSInteger)state
              direction:(NSInteger)direction {
    if (![_database open]) {
        NSLog(@"Insert message failed %@", [_database lastError]);
        return -1;
    }
    
    NSString *insertRobotSQL = @"INSERT INTO ChatMessageTable(message_id, robot_id, sender_id, message_content, message_date, message_state,  message_direction) VALUES (NULL, :robot_id, :sender_id, :message_content, :message_date, :message_state, :message_direction)";
    NSDictionary *parameters = @{
                                 @"robot_id": robotID,
                                 @"sender_id": senderID,
                                 @"message_content": [message text],
                                 @"message_date": [message date],
                                 @"message_state": @(state),
                                 @"message_direction":@(direction),
                                 };
    BOOL success = [_database executeUpdate:insertRobotSQL withParameterDictionary:parameters];
    if (!success) {
        NSLog(@"Insert robot failed %@", [_database lastError]);
        [_database close];
        return -1;
    }
    NSInteger lastRowID = [_database lastInsertRowId];
    [_database close];
    return lastRowID;
}

#pragma mark - 删除

- (BOOL)deleteMessage:(nonnull JSQMessage *)message {
    return YES;
}

#pragma mark - 修改

- (BOOL)updateMessageID:(NSInteger)messageID state:(NSInteger)state {
    if (![_database open]) {
        NSLog(@"Update message failed %@", [_database lastError]);
        return NO;
    }
    NSString *updateRobotSQL = @"UPDATE ChatMessageTable SET message_state = :message_state WHERE message_id = :message_id";
    NSDictionary *parameters = @{
                                 @"message_state": @(state),
                                 @"message_id":@(messageID),
                                 };
    BOOL success = [_database executeUpdate:updateRobotSQL withParameterDictionary:parameters];
    if (!success) {
        NSLog(@"Insert robot failed %@", [_database lastError]);
    }
    [_database close];
    return success;
}


@end
