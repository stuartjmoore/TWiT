//
//  TWSplitViewContainer.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWPlaybarViewController;

@interface TWSplitViewContainer : UIViewController

@property (nonatomic, strong) UINavigationController *masterController, *detailController, *modalController;
@property (nonatomic, strong) TWPlaybarViewController *playbarController;

@property (nonatomic, weak) IBOutlet UIView *masterContainer, *detailContainer;
@property (nonatomic, weak) IBOutlet UIView *modalContainer, *modalFlyout;
@property (nonatomic, weak) IBOutlet UIToolbar *modalBlackground;
@property (nonatomic, weak) IBOutlet UIView *playbarContainer;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *modalLeftContraint;

- (IBAction)didTapModalBackground:(UITapGestureRecognizer*)recognizer;
- (IBAction)didPanModalFlyout:(UIPanGestureRecognizer*)recognizer;

- (void)showPlaybar;
- (void)hidePlaybar;

- (void)showModalFlyout;
- (void)hideModalFlyout;

@end
