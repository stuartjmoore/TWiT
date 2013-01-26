//
//  TWNavigationContainer.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/26/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWNavigationContainer : UIViewController

@property (nonatomic, strong) UINavigationController *masterController;
@property (nonatomic, strong) UIViewController *playbarController;

@property (nonatomic, weak) IBOutlet UIView *masterContainer, *playbarContainer;

- (void)hidePlaybar;
- (void)showPlaybar;

@end
