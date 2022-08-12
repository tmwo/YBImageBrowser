//
//  YBIBSheetView.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/6.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBSheetView.h"
#import "YBIBUtilities.h"
#import "YBIBCopywriter.h"


@implementation YBIBSheetAction
+ (instancetype)actionWithName:(NSString *)name icon:(UIImage *)icon action:(YBIBSheetActionBlock)action {
    YBIBSheetAction *sheetAction = [YBIBSheetAction new];
    sheetAction.name = name;
    sheetAction.icon = icon;
    sheetAction.action = action;
    return sheetAction;
}
@end


@interface YBIBSheetCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation YBIBSheetCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor colorWithRed:145/255.0 green:145/255.0 blue:176/255.0 alpha:1];
        _titleLabel.font = [UIFont systemFontOfSize:11];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _iconView = [[UIImageView alloc] init];
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_iconView];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    _iconView.frame = CGRectMake(((width - 46) / 2), 0, 46, 46);
    _titleLabel.frame = CGRectMake(0, 54, width, 16);
}
@end


static CGFloat kTopOffsetSpace = 78;
static CGFloat kBottomOffsetSpace = 32;

@interface YBIBSheetView () <UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@end

@implementation YBIBSheetView {
    CGFloat _cellWidth;
    CGRect _tableShowFrame;
    CGRect _tableHideFrame;
    NSTimeInterval _showDuration;
    NSTimeInterval _hideDuration;
}

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _showDuration = 0.2;
        _hideDuration = 0.1;
        _backAlpha = 0.55;
        _actions = [NSMutableArray array];
        [self addSubview:self.containerView];
        [self addGestureRecognizer:self.panGesture];
        [self.containerView addSubview:self.lineView];
        [self.containerView addSubview:self.titleLabel];
        [self.containerView addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - public

- (void)showToView:(UIView *)view orientation:(UIDeviceOrientation)orientation {
    if (self.actions.count == 0) return;
    
    [view addSubview:self];
    self.frame = view.bounds;
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    CGFloat tableHeight = kTopOffsetSpace + 68 * (self.actions.count/4 + 1) + kBottomOffsetSpace + YBIBSafeAreaBottomHeight();
    
    _tableShowFrame = self.frame;
    _tableShowFrame.size.height = MIN(0.7 * viewHeight, tableHeight);
    _tableShowFrame.origin.y = viewHeight - _tableShowFrame.size.height;
    
    _tableHideFrame = _tableShowFrame;
    _tableHideFrame.origin.y = viewHeight;
    
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.containerView.frame = _tableHideFrame;

    self.lineView.frame = CGRectMake((viewWidth - 32) / 2, 12, 32, 4);
    self.titleLabel.frame = CGRectMake(0, 32, viewWidth, 22);
    self.collectionView.frame = CGRectMake(0, kTopOffsetSpace, self.bounds.size.width, 68 * (self.actions.count/4 + 1));

    [UIView animateWithDuration:_showDuration animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self->_backAlpha];
        self.containerView.frame = self->_tableShowFrame;
    }];

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.containerView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.containerView.layer.mask = maskLayer;
}

- (void)hideWithAnimation:(BOOL)animation {
    if (!self.superview) return;
    
    void(^animationsBlock)(void) = ^{
        self.containerView.frame = self->_tableHideFrame;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    };
    void(^completionBlock)(BOOL n) = ^(BOOL n){
        [self removeFromSuperview];
    };
    if (animation) {
        [UIView animateWithDuration:_hideDuration animations:animationsBlock completion:completionBlock];
    } else {
        animationsBlock();
        completionBlock(NO);
    }
}
#pragma mark -
#pragma mark - UIGestureRecognizerDelegate
static CGFloat lastTransitionY;
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint translation = [panGesture translationInView:self.containerView];
    // 限制最大的拖动范围
    CGFloat contentM = (self.frame.size.height - self.containerView.frame.size.height);
    if (translation.y > 0) { // 向下拖拽
        CGRect contentFrame = self.containerView.frame;
        contentFrame.origin.y += translation.y;
        self.containerView.frame = contentFrame;

    }else if (translation.y < 0 && self.containerView.frame.origin.y > contentM) { // 向上拖拽
        CGRect contentFrame = self.containerView.frame;
        contentFrame.origin.y = MAX((self.containerView.frame.origin.y + translation.y), contentM);
        self.containerView.frame = contentFrame;
    }

    [panGesture setTranslation:CGPointZero inView:self.containerView];
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [panGesture velocityInView:self.containerView];
        BOOL offsetY =  self.containerView.frame.origin.y > self.containerView.frame.size.height*0.7l;
        if ((velocity.y > 0 && lastTransitionY > 5) || offsetY) {// 结束时的速度>0 滑动距离> 5 且UIScrollView滑动到最顶部
            [self hideWithAnimation:YES];
        }else {
            [self show];
        }
    }
    lastTransitionY = translation.y;
}

- (void)show {
    [UIView animateWithDuration:0.25f animations:^{
        self.maskView.alpha = 1;
        CGRect frame = self.containerView.frame;
        frame.origin.y = self.frame.size.height - frame.size.height;
        self.containerView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}
#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.containerView.frame, point)) {
        [self hideWithAnimation:YES];
    }
}

#pragma mark - collectionView deleDate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.actions.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bounds.size.width / MIN(4, self.actions.count), 68);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YBIBSheetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(YBIBSheetCell.class) forIndexPath:indexPath];
    YBIBSheetAction *action = self.actions[indexPath.item];
    [cell.titleLabel setText:action.name];
    [cell.iconView setImage:action.icon];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    YBIBSheetAction *action = self.actions[indexPath.item];
    if (action.action) action.action(self.currentdata());
}

#pragma mark - getters
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        cv.alwaysBounceVertical = NO;
        cv.scrollEnabled = NO;
        cv.showsHorizontalScrollIndicator = NO;
        cv.backgroundColor = [UIColor clearColor];
        cv.delegate = self;
        cv.dataSource = self;
        [cv registerClass:YBIBSheetCell.class forCellWithReuseIdentifier:NSStringFromClass(YBIBSheetCell.class)];
        _collectionView = cv;
    }
    return _collectionView;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [_containerView setBackgroundColor:[UIColor colorWithRed:37/255.0 green:38/255.0 blue:61/255.0 alpha:1.0]];
    }
    return _containerView;
}

- (UIView *)lineView {
    if (!_lineView) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithRed:52/255.0 green:53/255.0 blue:82/255.0 alpha:1.0];
        view.layer.cornerRadius = 2;
        view.layer.masksToBounds = YES;
        _lineView = view;
    }
    return _lineView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:18];
        label.text = [YBIBCopywriter sharedCopywriter].more;
        _titleLabel = label;
    }
    return _titleLabel;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}
@end
