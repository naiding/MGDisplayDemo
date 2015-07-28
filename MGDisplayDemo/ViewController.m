//
//  ViewController.m
//  MGDisplayDemo
//
//  Created by Leon on 15/7/28.
//  Copyright (c) 2015年 Leon. All rights reserved.
//

#import "ViewController.h"
#import "MGDisplayImageView.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *button;
@property (strong, nonatomic) MGDisplayImageView *displayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonTapped:(id)sender
{
    [self.displayer showImageView:self.button.imageView];
}

- (UIButton *)button
{
    if (_button == nil) {
        _button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f,200.0f)];
        _button.center = self.view.center;
        [_button setImage:[UIImage imageNamed:@"hehe"] forState:UIControlStateNormal];
        _button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        _button.userInteractionEnabled = YES;
        [_button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _button;
}

- (MGDisplayImageView *)displayer
{
    if (_displayer == nil) {
        _displayer = [[MGDisplayImageView alloc]init];
    }
    
    return _displayer;
}

@end
