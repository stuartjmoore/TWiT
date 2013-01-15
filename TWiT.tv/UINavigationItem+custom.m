//
//  UINavigationItem+custom.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "UINavigationItem+custom.h"

@implementation UINavigationItem (custom)

- (void)setTitle:(NSString*)title
{
    for(UIView *view in self.titleView.subviews)
    {
        if([view isKindOfClass:UILabel.class])
        {
            UILabel *titleLabel = (UILabel*)view;
            titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:24];
            titleLabel.text = title;
            
            CGSize size = [title sizeWithFont:[UIFont fontWithName:@"Vollkorn-BoldItalic" size:13]];
            if(size.width > titleLabel.frame.size.width)
            {
                titleLabel.font = [UIFont fontWithName:titleLabel.font.fontName size:13];
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
