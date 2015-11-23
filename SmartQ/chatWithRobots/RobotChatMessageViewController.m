//
//  ITPKMessageViewController.m
//  SmartQ
//
//  Created by tropsci on 15/11/18.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "RobotChatMessageViewController.h"
#import "ITPKRobot.h"
#import "ChatRobotDB.h"

NSString *const SHOW_ROBOT_SETTING_SEGUE_ID = @"robotSettingIdentifier";

NSString *const CITY_WEATHER = @"城市天气";
NSString *const MAKE_JOKES = @"讲个笑话";
NSString *const LOOKUP_QQ_NUMBER = @"查询QQ号码";
NSString *const IDIOM_CHAIN = @"成语接龙";

@implementation RobotChatMessageViewController 
- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.robot robotName];
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Setting"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self action:@selector(rightAction:)];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
    
    if (![[self.robot robotID] isEqualToString:@"robot_001"]) {
        // 茉莉机器人的时候，才会有特殊的功能
        self.inputToolbar.contentView.leftBarButtonItemWidth = 0;
        self.inputToolbar.contentView.leftContentPadding = 0;
    }
        
    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = kJSQDemoAvatarIdSquires;
    self.senderDisplayName = kJSQDemoAvatarDisplayNameSquires;
    
    // 定义textview
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.inputToolbar.contentView.textView.returnKeyType = UIReturnKeySend;

    
    CGSize avatorSize = CGSizeMake(kJSQMessagesCollectionViewAvatarSizeDefault, kJSQMessagesCollectionViewAvatarSizeDefault);
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = avatorSize;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = avatorSize;

    BOOL maybeHaveEarlierMessage = self.chatData.messages.count == 20;
    self.showLoadEarlierMessagesHeader = maybeHaveEarlierMessage;
    
    /**
     *  Register custom menu actions for cells.
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action"
                                                                                      action:@selector(customAction:)] ];
    
    /**
     *  OPT-IN: allow cells to be deleted
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
//    self.collectionView.collectionViewLayout.springinessEnabled = YES;
    
}


#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
    NSString *text = textView.text;
    if ([text containsString:@"\r"] || [text containsString:@"\n"]) {
        NSString *trimedString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self didPressSendButton:nil
                 withMessageText:trimedString
                        senderId:kJSQDemoAvatarIdSquires
               senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                            date:[NSDate date]];
    }
}


#pragma mark - Event Action

- (void)rightAction:(UIBarButtonItem *)item {
    [self performSegueWithIdentifier:SHOW_ROBOT_SETTING_SEGUE_ID sender:self];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    // 保存到数据库
    NSInteger sendedMessageID = [[ChatRobotDB sharedInstance] addMessage:message
                                                           senderID:kJSQDemoAvatarIdSquires
                                                            robotID:[self.robot robotID]
                                                              state:kMESSAGE_STATE_PENDDING
                                                          direction:kMESSAGE_DIRECTION_OUTGOING];
    // 提问robot
    [self.robot ask:self.robot something:text answerBlock:^(NSError *error, id answer) {
        if (!error) {
            self.showTypingIndicator = !self.showTypingIndicator;
            [self scrollToBottomAnimated:YES];
            NSString *response = nil;
            if ([answer isKindOfClass:[NSDictionary class]]) {
                response = [(NSDictionary *)answer objectForKey:@"content"];
            } else if ([answer isKindOfClass:[NSString class]]){
                response = answer;
            }
            if (!response) {
                response = @"Error";
            }
            JSQMessage *receivedMessage = [[JSQMessage alloc]
                                           initWithSenderId:[self.robot robotID]
                                           senderDisplayName:[self.robot robotName]
                                           date:[NSDate date]
                                           text:response];
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            [self.chatData.messages addObject:receivedMessage];
            
            // 修改之前
            [[ChatRobotDB sharedInstance] updateMessageID:sendedMessageID state:kMESSAGE_STATE_SUCCESS];
            
            // 保存到数据库
            [[ChatRobotDB sharedInstance] addMessage:receivedMessage
                                            senderID:[self.robot robotID]
                                             robotID:[self.robot robotID]
                                               state:kMESSAGE_STATE_SUCCESS
                                           direction:kMESSAGE_DIRECTION_INCOMING];
            [self finishReceivingMessageAnimated:YES];
        } else {
            // 展示一个未发送成功的已发消息
            [[ChatRobotDB sharedInstance] updateMessageID:sendedMessageID state:kMESSAGE_STATE_FAILURE];
            NSLog(@"Error %@", error);
        }
    }];
    [self.chatData.messages addObject:message];
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"实用工具"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:CITY_WEATHER, MAKE_JOKES, LOOKUP_QQ_NUMBER, IDIOM_CHAIN, nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    if (buttonIndex == 1) {
        // 讲笑话
        [self didPressSendButton:nil
                 withMessageText:MAKE_JOKES
                        senderId:kJSQDemoAvatarIdSquires
               senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                            date:[NSDate date]];
    } else if (buttonIndex == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:CITY_WEATHER
                                                            message:@"输入城市名称"
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    } else if (buttonIndex == 2) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOOKUP_QQ_NUMBER
                                                            message:@"输入QQ号码"
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    } else if (buttonIndex == 3) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:IDIOM_CHAIN
                                                            message:@"输入四字成语"
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if (buttonIndex == 1) { // 确定按钮
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        [alertTextField resignFirstResponder];
        NSString *inputText = [[alertTextField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([alertView.title isEqualToString:CITY_WEATHER]) {
            if (inputText.length) {
                NSString *questionString = [NSString stringWithFormat:@"天气预报%@", inputText];
                [self didPressSendButton:nil
                         withMessageText:questionString
                                senderId:kJSQDemoAvatarIdSquires
                       senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                    date:[NSDate date]];
            }
        } else if ([alertView.title isEqualToString:LOOKUP_QQ_NUMBER]) {
            if (inputText.length) {
                NSString *questionString = [NSString stringWithFormat:@"@qq%@", inputText];
                [self didPressSendButton:nil
                         withMessageText:questionString
                                senderId:kJSQDemoAvatarIdSquires
                       senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                    date:[NSDate date]];
            }
        } else if ([alertView.title isEqualToString:IDIOM_CHAIN]) {
            if (inputText.length) {
                NSString *questionString = [NSString stringWithFormat:@"@cy%@", inputText];
                [self didPressSendButton:nil
                         withMessageText:questionString
                                senderId:kJSQDemoAvatarIdSquires
                       senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                    date:[NSDate date]];
            }
        }
    }
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.chatData.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.chatData.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatData.outgoingBubbleImageData;
    }
    
    return self.chatData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatData.avatars[self.senderId];
    }
    return [self.chatData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.chatData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    
    [[[UIAlertView alloc] initWithTitle:@"Custom Action"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.chatData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    JSQMessage *baseItem = [self.chatData.messages firstObject];
    NSArray *histroyMessageArray = [[ChatRobotDB sharedInstance] chatMessageWithRobot:self.robot beforeMessage:baseItem messageCount:20];
    
    if (!histroyMessageArray.count) {
        self.showLoadEarlierMessagesHeader = NO;
    }
    
    NSRange insertRange = NSMakeRange(0, [histroyMessageArray count]);
    [self.chatData.messages insertObjects:histroyMessageArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:insertRange]];
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadData];
    
    NSIndexPath *scrollToIndexPath = [NSIndexPath indexPathForRow:[histroyMessageArray count] inSection:0];
    [self.collectionView scrollToItemAtIndexPath:scrollToIndexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender {
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.chatData.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

#pragma mark - UINavigation Prepare
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SHOW_ROBOT_SETTING_SEGUE_ID]) {
        
    }
}

@end
