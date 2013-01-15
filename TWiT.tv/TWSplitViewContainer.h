//
//  TWSplitViewContainer.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWSplitViewContainer : UIViewController

@property (nonatomic, weak) IBOutlet UINavigationController *masterController, *detailController, *modalController;
@property (nonatomic, weak) IBOutlet UIView *masterContainer, *detailContainer;
@property (nonatomic, weak) IBOutlet UIView *modalContainer, *modalBlackground, *modalFlyout;

@end
