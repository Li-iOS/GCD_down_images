//
//  ViewController.m
//  GCD_down_images
//
//  Created by ljw on 16/4/11.
//  Copyright © 2016年 ljw. All rights reserved.
//

#import "ViewController.h"

static const NSInteger rowNumbers = 4;
static const CGFloat   imageH     = 60.0f;

@interface ViewController ()

@property (nonatomic, strong) UIButton *serialQueueBtn;
@property (nonatomic, strong) UIButton *concurrentQueueBtn;
@property (nonatomic, strong) UIButton *groupBtn;
@property (nonatomic, strong) UIButton *applyQueue;
@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) NSArray *imageUrls;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self addBtnViews];

    
    // dispatch_after 函数
    dispatch_time_t  timer = dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC);
    dispatch_after(timer, dispatch_get_main_queue(), ^{
        NSLog(@"after 3s dosome thing");
    });
    
    
    // dispatch_once
    
    static dispatch_once_t onceToken = nil;
    dispatch_once(&onceToken, ^{
    // 做些操作 无论经历多少个哪个线程里 只执行一次之后不再执行。
    });
    
    
}


- (void)serialQueueAction:(UIButton *)btn {
    
    dispatch_queue_t syqueue = dispatch_queue_create("com.queue.serial", DISPATCH_QUEUE_SERIAL);
//    dispatch_queue_t syqueue = dispatch_get_main_queue();
    __block typeof(self) Wself = self;
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
            dispatch_async(syqueue, ^{
                UIImageView *imageV = Wself.imageViews[i];
                NSURL *url = [NSURL URLWithString:Wself.imageUrls[i]];
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageV.image = image;
                });
                NSLog(@"i = %ld  %lf ", i, imageV.image.scale);
            });
            
        }
    // 执行顺序为 0 ，1，2，3，4，5，6，7，8，9，10，11....... 依次进行
}


- (void)concurrentQueueAction:(UIButton *)btn {
    
    dispatch_queue_t queue = dispatch_queue_create("com.queue.concurrent", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __block typeof(self) Wself = self;
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
        dispatch_async(queue, ^{
            UIImageView *imageV = Wself.imageViews[i];
            NSURL *url = [NSURL URLWithString:Wself.imageUrls[i]];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            dispatch_async(dispatch_get_main_queue(), ^{
                imageV.image = image;
            });
            NSLog(@"i = %ld  %lf ", i, imageV.image.scale);
        });
        
    }
    // conCurrent 线程因为不用等待 block 执行结果，并行处理， 所以顺序随机。
}

- (void)groupBtnAction:(UIButton *)btn {
    

    // 比如，想现在在 2-12 的图片最后下载第一张图 可以用到 group 当然仅限于 concurrent Queue
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __block typeof(self) Wself = self;
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
        
        dispatch_group_async(group, queue, ^{
            if (!i) { return; }
            UIImageView *imageV = Wself.imageViews[i];
            NSURL *url = [NSURL URLWithString:Wself.imageUrls[i]];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            dispatch_async(dispatch_get_main_queue(), ^{
                imageV.image = image;
            });
            NSLog(@"i = %ld  %lf ", i, imageV.image.scale);
        });
    }
    NSLog(@"groupgroupgroupgroupgroup 不阻塞线程");
    dispatch_group_notify(group, queue, ^{
        UIImageView *imageV = Wself.imageViews[0];
        NSURL *url = [NSURL URLWithString:Wself.imageUrls[0]];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageV.image = image;
        });
        NSLog(@"i = 0  %lf ", imageV.image.scale);
    });
}
- (void)applyQueueAction:(UIButton *)btn {
    
    dispatch_queue_t queue = dispatch_queue_create("com.queue.concurrent", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_queue_t syqueue = dispatch_queue_create("com.queue.serial", DISPATCH_QUEUE_SERIAL);
   
    __block typeof(self) Wself = self;
    
    dispatch_apply(Wself.imageUrls.count, queue, ^(size_t i) {
     
         UIImageView *imageV = Wself.imageViews[i];
         NSURL *url = [NSURL URLWithString:Wself.imageUrls[i]];
         UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
         dispatch_async(dispatch_get_main_queue(), ^{
             imageV.image = image;
         });
         NSLog(@"i = %zd %lf ", i, imageV.image.scale);
     });
    NSLog(@"apply Queue apply Queue apply Queue 类似于 serial线程");
}


- (void)addBtnViews {
    [self.view addSubview:self.serialQueueBtn];
    [self.view addSubview:self.concurrentQueueBtn];
    [self.view addSubview:self.groupBtn];
    [self.view addSubview:self.applyQueue];
    [self addImageViews];

}



- (void)viewDidLayoutSubviews {
    
    CGFloat width = self.view.frame.size.width/5.0f;
    CGFloat gap   = (width / 4.0);
    self.serialQueueBtn.frame  = CGRectMake(gap, 64, width, 50);
    self.concurrentQueueBtn.frame = CGRectMake(gap*2+width, 64, width, 50);
    self.groupBtn.frame = CGRectMake(gap*3+width*2, 64, width, 50);
    self.applyQueue.frame = CGRectMake(gap*4+width*3, 64, width, 50);
    
    CGFloat _y      = 120.0f;
    CGFloat x       = 0.0f;
    CGFloat iGap    = (self.view.frame.size.width - imageH * rowNumbers)/(rowNumbers+1);
    NSInteger count = self.imageViews.count;
    NSInteger rows  = count % rowNumbers ? count / rowNumbers+1: count / rowNumbers ;
    
    for (NSInteger i = 0; i < rows; i++) {
        CGFloat y = _y+iGap*i+imageH*i;
        for (NSInteger j = 0; j < rowNumbers; j++) {
            x = j * imageH + (j+1) * iGap;
            UIImageView *image = [self.view viewWithTag:100+i*rowNumbers+j];
            image.frame        = CGRectMake(x, y, imageH, imageH);
        }
    }
}
- (UIButton *)serialQueueBtn {
    if (!_serialQueueBtn) {
        _serialQueueBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_serialQueueBtn setTitle:@"同Serial" forState:UIControlStateNormal];
        [_serialQueueBtn addTarget:self action:@selector(serialQueueAction:) forControlEvents:UIControlEventTouchUpInside];
        [_serialQueueBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
        _serialQueueBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _serialQueueBtn;
}


- (UIButton *)concurrentQueueBtn {
    if (!_concurrentQueueBtn) {
        _concurrentQueueBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_concurrentQueueBtn setTitle:@"异步current" forState:UIControlStateNormal];
        [_concurrentQueueBtn addTarget:self action:@selector(concurrentQueueAction:) forControlEvents:UIControlEventTouchUpInside];
        [_concurrentQueueBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
        _concurrentQueueBtn.titleLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _concurrentQueueBtn;
}


- (UIButton *)groupBtn {
    if (!_groupBtn) {
        _groupBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_groupBtn setTitle:@"group下载" forState:UIControlStateNormal];
        [_groupBtn addTarget:self action:@selector(groupBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_groupBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
        _groupBtn.titleLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _groupBtn;
}
- (UIButton *)applyQueue {
    if (!_applyQueue) {
        _applyQueue = [UIButton buttonWithType:UIButtonTypeCustom];
        [_applyQueue setTitle:@"c-队列" forState:UIControlStateNormal];
        [_applyQueue addTarget:self action:@selector(applyQueueAction:) forControlEvents:UIControlEventTouchUpInside];
        [_applyQueue setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
        _applyQueue.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _applyQueue;
}

- (NSMutableArray *)imageViews {
    if (!_imageViews) {
        _imageViews = [NSMutableArray array];
    }
    return _imageViews;
}

- (NSArray *)imageUrls {
    if (!_imageUrls) {
        _imageUrls =  @[ @"http://pic.qiantucdn.com/58pic/18/48/34/5627d17edb694_1024.jpg",
                         @"http://pic.qiantucdn.com/58pic/18/96/91/90m58PICpQR_1024.jpg",
                         @"http://www.pp3.cn/uploads/allimg/111114/11033633S-3.jpg",
                         @"http://pic.qiantucdn.com/58pic/16/66/54/74G58PICnSN_1024.jpg",
                         @"http://pic.qiantucdn.com/58pic/18/93/30/30C58PIC3Vs_1024.jpg",
                         @"http://dl.bizhi.sogou.com/images/2012/01/20/119668.jpg?f=download",
                         @"http://www.deskcar.com/desktop/fengjing/2013812103350/11.jpg",
                         @"http://www.deskcar.com/desktop/star/world/20081017165318/27.jpg",
                         @"http://image.tianjimedia.com/uploadImages/2012/012/2YXG0J416V69.jpg",
                         @"http://www.pp3.cn/uploads/allimg/111112/110G3D03-12.jpg",
                         @"http://e.hiphotos.baidu.com/zhidao/pic/item/5366d0160924ab18eb02b75e35fae6cd7b890b46.jpg",
                         @"http://www.pp3.cn/uploads/allimg/111122/112U12H1-2.jpg"];
    }
    return _imageUrls;
}



- (void)addImageViews {
    
    for (NSInteger i = 0; i < 12; i++) {
        UIImageView *image = [[UIImageView alloc] init];
        [self.imageViews addObject:image];
        image.tag = 100+i;
        image.backgroundColor = [UIColor redColor];
        [self.view addSubview:image];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
