//
//  TWShowCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Show;

@interface TWShowCell : UICollectionViewCell

@property (nonatomic, strong) Show *show;
@property (nonatomic, weak) IBOutlet UIImageView *albumView;

@end
