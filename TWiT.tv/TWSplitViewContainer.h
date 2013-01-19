//
//  TWSplitViewContainer.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWSplitViewContainer : UIViewController

@property (nonatomic, strong) UINavigationController *masterController, *detailController, *modalController;
@property (nonatomic, strong) UIViewController *playbarController;

@property (nonatomic, weak) IBOutlet UIView *masterContainer, *detailContainer;
@property (nonatomic, weak) IBOutlet UIView *modalContainer, *modalBlackground, *modalFlyout;
@property (nonatomic, weak) IBOutlet UIView *playbarContainer;

- (void)hidePlaybar;
- (void)showPlaybar;

@end
