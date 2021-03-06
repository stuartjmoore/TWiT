//
//  TWNavigationItem.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/25/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWNavigationItem.h"

#define MIN_FONT_SIZE 14

@implementation TWNavigationItem

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self setTitle:self.title];
    }
    return self;
}

- (void)setTitle:(NSString*)title
{
    [super setTitle:title];
    
    for(UIView *view in self.titleView.subviews)
    {
        if([view isKindOfClass:UILabel.class])
        {
            UILabel *titleLabel = (UILabel*)view;
            titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:18];
            titleLabel.text = title;
            
            CGSize size = [title sizeWithAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Vollkorn-BoldItalic" size:MIN_FONT_SIZE] }];
            
            if(size.width >= titleLabel.frame.size.width)
            {
                titleLabel.font = [UIFont fontWithName:titleLabel.font.fontName size:MIN_FONT_SIZE];
                titleLabel.numberOfLines = 2;
            }
            else
            {
                titleLabel.numberOfLines = 1;
            }
        }
    }
}

@end
