//
//  XNAppDelegate.m
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "XNAppDelegate.h"
#import "XNKeyValueExtractor.h"

#import "XNScrollView.h"
#import "XNTableView.h"

#import "NSObject+XNAnimation.h"

#define TEST_TABLE_VIEW 0
#define SCROLL_VIEW_CLASS XNScrollView

@interface XNAppDelegate () <XNScrollViewDelegate, XNTableViewDataSource, XNTableViewDelegate>
@end

@implementation XNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    XNScrollView *sv = (XNScrollView *)[[SCROLL_VIEW_CLASS alloc] initWithFrame:self.window.bounds];
    [sv setIndicatorStyle:XNScrollViewIndicatorStyleDefault];
    [sv setContentInset:UIEdgeInsetsMake(20, 0, 0, 0)];
    [sv setScrollIndicatorInsets:UIEdgeInsetsMake(20, 0, 0, 0)];
    [sv setDelegate:self];
    [self.window addSubview:sv];
    [sv release];

    CGFloat ratio = (self.window.bounds.size.width / self.window.bounds.size.height);
    CGFloat n = 30;
    CGFloat checkerDimension = 50;
    [sv setContentSize:CGSizeMake(checkerDimension * ceilf(ratio * n), checkerDimension * ceilf(n / ratio))];

    for (CGFloat x = 0; x < sv.contentSize.width; x += checkerDimension) {
      for (CGFloat y = 0; y < sv.contentSize.height; y += checkerDimension) {
        NSInteger ix = x / checkerDimension;
        NSInteger iy = y / checkerDimension;

        if (ix % 2 == iy % 2) {
          UIView *checker = [[UIView alloc] initWithFrame:CGRectMake(x, y, checkerDimension, checkerDimension)];
          checker.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
          [sv addSubview:checker];
          [checker release];
        }
      }
    }

#if TEST_TABLE_VIEW
    XNTableView *tv = [[XNTableView alloc] initWithFrame:CGRectMake(self.window.bounds.size.width * 1.5, self.window.bounds.size.width * 1.5, 320, 480) style:XNTableViewStylePlain];
    [tv setIndicatorStyle:XNScrollViewIndicatorStyleDefault];
    [tv setShowsVerticalScrollIndicator:YES];
    [tv setDelegate:self];
    [tv setClipsToBounds:YES];
    [tv setDataSource:self];
    [sv addSubview:tv];
    [tv release];
#endif

    return YES;
}

- (void)dealloc
{
  [_window release];
  [super dealloc];
}

#pragma mark - XNTableView

- (int)tableView:(XNTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 500;
}

- (XNTableViewCell *)tableView:(XNTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XNTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hi"];
    if (cell == nil) cell = [[[XNTableViewCell alloc] initWithStyle:XNTableViewCellStyleDefault reuseIdentifier:@"hi"] autorelease];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset([[cell contentView] bounds], 0, 1.0f)];
    [label setBackgroundColor:[UIColor colorWithWhite:0.85f alpha:1]];
    label.text = @"hi, i'm a table cell";
    label.font = [UIFont boldSystemFontOfSize:22.0f];
    label.textAlignment = NSTextAlignmentCenter;
    [[cell contentView] addSubview:label];
    return cell;
}

- (void)tableView:(XNTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end
