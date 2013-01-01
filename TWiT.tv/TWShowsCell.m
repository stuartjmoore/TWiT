//
//  TWShowsCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowsCell.h"

@implementation TWShowsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _spacing = 14;
        _size = 88;
        _columns = 3;
        _visibleColumns = 0;
    }
    return self;
}

- (void)setShows:(NSArray*)shows
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, UIScreen.mainScreen.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:245/255.0 alpha:1].CGColor);
    CGContextFillRect(context, self.bounds);
    /*
    for(Show *show in shows)
    {
        int column = [shows indexOfObject:show];
        CGRect frame = CGRectMake(self.spacing+column*(self.size+self.spacing), self.spacing/2, self.size, self.size);
        
        CGContextSetShadow(context, CGSizeMake(0, 2), 4);
        
        UIImage *image = show.albumArt.image;
        [image drawInRect:frame];
    }
    */
    for(UIImage *show in shows)
    {
        int column = [shows indexOfObject:show];
        CGRect frame = CGRectMake(self.spacing+column*(self.size+self.spacing), self.spacing/2,
                                  self.size, self.size);
        
        CGContextSetShadow(context, CGSizeMake(0, 2), 4);
        
        [show drawInRect:frame];
    }
    
    self.icons = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.visibleColumns = shows.count;
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)drawRect:(CGRect)rect
{
    [self.icons drawInRect:self.bounds];
}

@end
