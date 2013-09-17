//
//  TWChatViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 9/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWChatViewController.h"
#import "UIAlertView+block.h"

@implementation TWChatViewController

- (void)viewDidLoad
{
    self.chatToolbarView.barStyle = UIBarStyleBlack;
}

- (void)loadWithNickname:(NSString*)nickname
{
    self.chatNick = nickname;

    // TODO: UNDO:
    //NSString *urlString = [NSString stringWithFormat:@"http://webchat.twit.tv/?nick=%@&uio=MT1mYWxzZSY3PWZhbHNlJjM9ZmFsc2UmMTA9dHJ1ZSYxMz1mYWxzZSYxND1mYWxzZQ23", self.chatNick];
    NSString *urlString = [NSString stringWithFormat:@"http://webchat.twit.tv/?nick=%@&channels=twitlive&uio=MT1mYWxzZSY3PWZhbHNlJjM9ZmFsc2UmMTA9dHJ1ZSYxMz1mYWxzZSYxND1mYWxzZQ23", self.chatNick];
    
    [self.chatWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    self.chatWebView.hidden = YES;
    
    if([self.chatWebView respondsToSelector:@selector(scrollView)])
        self.chatWebView.scrollView.scrollEnabled = NO;
    else
        [self.chatWebView.subviews.lastObject setScrollEnabled:NO];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    NSString *loginJS = @"javascript:(function evilGenius(){\
                          document.getElementsByTagName('input')[0].click();\
                          })();";
    
    [webView stringByEvaluatingJavaScriptFromString:loginJS];
    
    NSString *path = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"chatRoom.css"];
    NSString *css = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    css = [css stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    css = [css stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    css = [css stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    
    NSString *styleJS = [NSString stringWithFormat:@"javascript:(function evilGenius(){\
                         var s=document.createElement(\"style\");\
                         s.setAttribute(\"type\",\"text/css\");\
                         s.innerHTML=\"%@\";\
                         document.getElementsByTagName(\"head\")[0].appendChild(s);\
                         })();", css];
    
    [webView stringByEvaluatingJavaScriptFromString:styleJS];
    
    webView.hidden = NO;
}

#pragma mark - Actions

- (BOOL)isChatLoaded
{
    return self.chatWebView.request;
}

- (IBAction)sendChatMessage:(UIButton*)sender
{
    NSString *messageJS = [NSString stringWithFormat:@"javascript:(function evilGenius(){\
                           document.forms[0].elements[0].value = '%@';\
                           document.getElementsByTagName('input')[1].click();\
                           })();", self.chatField.text];
    
    [self.chatWebView stringByEvaluatingJavaScriptFromString:messageJS];
    self.chatField.text = @"";
}

/*
- (void)layoutChatViewWithKeyboardSize:(CGSize)keyboardSize
{
    if(self.chatView.hidden)
    {
        self.delegate.player.view.frame = self.view.bounds;
    }
    else if(!self.infoView.hidden)
    {
        CGRect chatFrame = self.view.bounds;
        chatFrame.size.height -= keyboardSize.height;
        self.chatView.frame = chatFrame;
    }
    else if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        CGRect playerFrame = self.view.bounds;
        playerFrame.size.height = playerFrame.size.width * (9.0f/16.0f);
        self.delegate.player.view.frame = playerFrame;
        
        CGRect chatFrame = self.view.bounds;
        
        if(keyboardSize.height == 0)
            chatFrame.origin.y = playerFrame.size.height;
        else
            chatFrame.origin.y = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? playerFrame.size.height : 0;
        
        chatFrame.size.height = self.view.bounds.size.height - chatFrame.origin.y - keyboardSize.height;
        self.chatView.frame = chatFrame;
    }
    else
    {
        if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            CGRect playerFrame = self.view.bounds;
            playerFrame.size.height = playerFrame.size.width * (9.0f/16.0f);
            self.delegate.player.view.frame = playerFrame;
            
            CGRect chatFrame = self.view.bounds;
            
            if(keyboardSize.height == 0)
            {
                chatFrame.origin.y = playerFrame.size.height;
                chatFrame.size.height -= playerFrame.size.height;
            }
            else
            {
                chatFrame.size.height -= keyboardSize.height;
            }
            
            self.chatView.frame = chatFrame;
        }
        else
        {
            CGRect chatFrame = self.view.bounds;
            
            if(keyboardSize.height == 0)
            {
                self.delegate.player.view.frame = self.view.bounds;
            }
            else
            {
                CGRect playerFrame = self.view.bounds;
                playerFrame.origin.y -= keyboardSize.height / 2.0f;
                playerFrame.size.height = playerFrame.size.width * (9.0f/16.0f);
                self.delegate.player.view.frame = playerFrame;
            }
            
            chatFrame.size.height -= keyboardSize.height;
            self.chatView.frame = chatFrame;
        }
    }
}
*/

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    if([request.URL.absoluteString hasPrefix:@"http://webchat.twit.tv/"])
    {
        return YES;
    }
    else
    {
        [UIAlertView alertViewWithTitle:@"Open in Browser?"
                                message:[NSString stringWithFormat:@"%@", request.URL.host]
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@[@"Open"]
                              onDismiss:^(int buttonIndex) {
                                  [UIApplication.sharedApplication openURL:request.URL];
                              }
                               onCancel:^(){}];
        
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Leave

- (IBAction)close:(UIButton*)sender
{
    [self.chatField resignFirstResponder];
    [NSNotificationCenter.defaultCenter postNotificationName:@"chatRoomDidHide" object:self]; // TODO: Delegate
}

@end
