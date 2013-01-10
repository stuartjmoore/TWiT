//
//  TWSplitViewContainer.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWSplitViewContainer.h"

@implementation TWSplitViewContainer

- (void)setMasterController:(UIViewController*)masterController
{
    _masterController = masterController;
    
    [self addChildViewController:masterController];
    
    masterController.view.frame = self.masterContainer.bounds;
    [self.masterContainer addSubview:masterController.view];
}

- (void)setDetailController:(UIViewController *)detailController
{
    _detailController = detailController;
    
    [self addChildViewController:detailController];
    
    detailController.view.frame = self.detailContainer.bounds;
    [self.detailContainer addSubview:detailController.view];
}

- (void)setModalController:(UIViewController*)modalController
{
    _modalController = modalController;
    
    [self addChildViewController:modalController];
    
    modalController.view.frame = self.modalContainer.bounds;
    [self.modalContainer addSubview:modalController.view];
}

@end
