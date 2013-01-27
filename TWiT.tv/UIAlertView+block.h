//
//  UIAlertView+block.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/27/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^VoidBlock)();

typedef void (^DismissBlock)(int buttonIndex);
typedef void (^CancelBlock)();
typedef void (^PhotoPickedBlock)(UIImage *chosenImage);

@interface UIAlertView (block) <UIAlertViewDelegate>

+ (UIAlertView*) alertViewWithTitle:(NSString*) title
                            message:(NSString*) message;

+ (UIAlertView*) alertViewWithTitle:(NSString*) title
                            message:(NSString*) message
                  cancelButtonTitle:(NSString*) cancelButtonTitle;

+ (UIAlertView*) alertViewWithTitle:(NSString*) title
                            message:(NSString*) message
                  cancelButtonTitle:(NSString*) cancelButtonTitle
                  otherButtonTitles:(NSArray*) otherButtons
                          onDismiss:(DismissBlock) dismissed
                           onCancel:(CancelBlock) cancelled;

@property (nonatomic, copy) DismissBlock dismissBlock;
@property (nonatomic, copy) CancelBlock cancelBlock;

@end
