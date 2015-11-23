//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "ChatModelData.h"
#import "ChatRobotDB.h"
#import "NSUserDefaults+ChatSettings.h"
#import "RobotProtocol.h"

@implementation ChatModelData {
    id<RobotProtocol> _robot;
}

- (instancetype)initWithRobot:(id<RobotProtocol>)robot {
    self = [super init];
    if (self) {
        _robot = robot;
        [self loadMessages];
        [self loadAvator];
        [self loadUser];
        [self loadButtles];
    }
    return self;
}


- (void)loadMessages {
    NSArray *historyMessage = [[ChatRobotDB sharedInstance] chatMessageWithRobot:_robot beforeMessage:nil messageCount:20];
    self.messages = [NSMutableArray<JSQMessage *> arrayWithArray:historyMessage];
}

- (void)loadAvator {
    JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"Me"
                                                                                  backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                        textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                             font:[UIFont systemFontOfSize:14.0f]
                                                                                         diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    JSQMessagesAvatarImage *robotImage = nil;
    UIImage *robotAvatorImage = [UIImage imageNamed:[_robot robotAvator]];
    robotImage = [JSQMessagesAvatarImage avatarWithImage:robotAvatorImage];
    self.avatars = @{
                     kJSQDemoAvatarIdSquires : jsqImage,
                     [_robot robotID] : robotImage,
                      };
}

- (void)loadUser {
    self.users = @{
                   [_robot robotID] : [_robot robotName],
                   kJSQDemoAvatarIdSquires : kJSQDemoAvatarDisplayNameSquires
                   };
}

- (void)loadButtles {
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}

@end
