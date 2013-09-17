//
//  TWChatViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 9/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWChatViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIWebView *chatWebView;
@property (nonatomic, weak) IBOutlet UIToolbar *chatToolbarView;
@property (nonatomic, weak) IBOutlet UITextField *chatField;
@property (nonatomic, weak) IBOutlet UIButton *chatSendButton;

@property (nonatomic, strong) NSString *chatNick;

- (void)loadWithNickname:(NSString*)nickname;
- (IBAction)sendChatMessage:(UIButton*)sender;

- (BOOL)isChatLoaded;

- (IBAction)close:(UIButton*)sender;

@end
