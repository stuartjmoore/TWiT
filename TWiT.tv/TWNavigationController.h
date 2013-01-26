//
//  TWNavigationController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/25/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWNavigationController : UINavigationController

@property (nonatomic, strong) UIView *playbarContainer;

- (BOOL)containsPlaybar;
- (void)showPlaybar;
- (void)hidePlaybar;

@end
