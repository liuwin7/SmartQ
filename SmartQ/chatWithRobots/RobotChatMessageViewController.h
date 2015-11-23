//
//  ITPKMessageViewController.h
//  SmartQ
//
//  Created by tropsci on 15/11/18.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "ChatModelData.h"
#import "RobotProtocol.h"

@interface RobotChatMessageViewController : JSQMessagesViewController
<UIAlertViewDelegate, UIActionSheetDelegate, JSQMessagesComposerTextViewPasteDelegate>

@property (strong, nonatomic) ChatModelData *chatData;

@property(nonatomic, strong)id<RobotProtocol> robot;

@end
