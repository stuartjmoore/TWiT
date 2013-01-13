//
//  TWPlayerViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Enclosure;

@interface TWPlayerViewController : UIViewController

@property (nonatomic, strong) Enclosure *enclosure;

- (IBAction)close:(UIBarButtonItem*)sender;

@end
