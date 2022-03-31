//
//  YBIBSheetView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/6.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBDataProtocol;

typedef void(^YBIBSheetActionBlock)(id<YBIBDataProtocol> data);

@interface YBIBSheetAction : NSObject

/// 显示的名字
@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) UIImage *icon;

/// 点击回调闭包
@property (nonatomic, copy, nullable) YBIBSheetActionBlock action;

+ (instancetype)actionWithName:(NSString *)name icon:(UIImage *)icon action:(_Nullable YBIBSheetActionBlock)action;

@end


@interface YBIBSheetView : UIView

/// 数据源 (可自定义添加)
@property (nonatomic, strong) NSMutableArray<YBIBSheetAction *> *actions;

/// 背景透明度
@property (nonatomic, assign) CGFloat backAlpha;

/**
 展示

 @param view 指定父视图
 @param orientation 当前方向
 */
- (void)showToView:(UIView *)view orientation:(UIDeviceOrientation)orientation;

/**
 隐藏

 @param animation 是否带动画
 */
- (void)hideWithAnimation:(BOOL)animation;

/// 获取当前数据的闭包
@property (nonatomic, copy) id<YBIBDataProtocol>(^currentdata)(void);

@end

NS_ASSUME_NONNULL_END
