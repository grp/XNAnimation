/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "XNScrollView.h"
#import "XNTableViewCell.h"
#import "NSIndexPath+XNTableView.h"

extern NSString *const XNTableViewIndexSearch;

@class XNTableView;

@protocol XNTableViewDelegate <XNScrollViewDelegate>
@optional
- (CGFloat)tableView:(XNTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)tableView:(XNTableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(XNTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)tableView:(XNTableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(XNTableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)tableView:(XNTableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(XNTableView *)tableView heightForFooterInSection:(NSInteger)section;
- (UIView *)tableView:(XNTableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(XNTableView *)tableView viewForFooterInSection:(NSInteger)section;

- (void)tableView:(XNTableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(XNTableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)tableView:(XNTableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol XNTableViewDataSource <NSObject>
@required
- (NSInteger)tableView:(XNTableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (XNTableViewCell *)tableView:(XNTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSInteger)numberOfSectionsInTableView:(XNTableView *)tableView;
- (NSString *)tableView:(XNTableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString *)tableView:(XNTableView *)tableView titleForFooterInSection:(NSInteger)section;

- (void)tableView:(XNTableView *)tableView commitEditingStyle:(XNTableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(XNTableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
@end

typedef enum {
    XNTableViewStylePlain,
    XNTableViewStyleGrouped
} XNTableViewStyle;

typedef enum {
    XNTableViewScrollPositionNone,
    XNTableViewScrollPositionTop,
    XNTableViewScrollPositionMiddle,
    XNTableViewScrollPositionBottom
} XNTableViewScrollPosition;

typedef enum {
    XNTableViewRowAnimationFade,
    XNTableViewRowAnimationRight,
    XNTableViewRowAnimationLeft,
    XNTableViewRowAnimationTop,
    XNTableViewRowAnimationBottom,
    XNTableViewRowAnimationNone,
    XNTableViewRowAnimationMiddle
} XNTableViewRowAnimation;

@interface XNTableView : XNScrollView {
@private
    XNTableViewStyle _style;
    id<XNTableViewDataSource> _dataSource;
    BOOL _needsReload;
    CGFloat _rowHeight;
    UIColor *_separatorColor;
    XNTableViewCellSeparatorStyle _separatorStyle;
    UIView *_tableHeaderView;
    UIView *_tableFooterView;
    BOOL _allowsSelection;
    BOOL _allowsSelectionDuringEditing;
    BOOL _editing;
    NSIndexPath *_selectedRow;
    NSIndexPath *_highlightedRow;
    NSMutableDictionary *_cachedCells;
    NSMutableSet *_reusableCells;
    NSMutableArray *_sections;
    CGFloat _sectionHeaderHeight;
    CGFloat _sectionFooterHeight;
    
    struct {
        unsigned heightForRowAtIndexPath : 1;
        unsigned heightForHeaderInSection : 1;
        unsigned heightForFooterInSection : 1;
        unsigned viewForHeaderInSection : 1;
        unsigned viewForFooterInSection : 1;
        unsigned willSelectRowAtIndexPath : 1;
        unsigned didSelectRowAtIndexPath : 1;
        unsigned willDeselectRowAtIndexPath : 1;
        unsigned didDeselectRowAtIndexPath : 1;
        unsigned willBeginEditingRowAtIndexPath : 1;
        unsigned didEndEditingRowAtIndexPath : 1;
        unsigned titleForDeleteConfirmationButtonForRowAtIndexPath: 1;
    } _delegateHas;
    
    struct {
        unsigned numberOfSectionsInTableView : 1;
        unsigned titleForHeaderInSection : 1;
        unsigned titleForFooterInSection : 1;
        unsigned commitEditingStyle : 1;
        unsigned canEditRowAtIndexPath : 1;
    } _dataSourceHas;
}

- (id)initWithFrame:(CGRect)frame style:(XNTableViewStyle)style;
- (void)reloadData;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;
- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(XNTableViewCell *)cell;
- (NSArray *)indexPathsForVisibleRows;
- (NSArray *)visibleCells;
- (XNTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (XNTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGRect)rectForSection:(NSInteger)section;
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForFooterInSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)beginUpdates;
- (void)endUpdates;

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(XNTableViewRowAnimation)animation;
- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(XNTableViewRowAnimation)animation;

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(XNTableViewRowAnimation)animation;	// not implemented
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(XNTableViewRowAnimation)animation;	// not implemented

- (NSIndexPath *)indexPathForSelectedRow;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(XNTableViewScrollPosition)scrollPosition;

- (void)scrollToNearestSelectedRowAtScrollPosition:(XNTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(XNTableViewScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)setEditing:(BOOL)editing animated:(BOOL)animate;

@property (nonatomic, readonly) XNTableViewStyle style;
@property (nonatomic, assign) id<XNTableViewDelegate> delegate;
@property (nonatomic, assign) id<XNTableViewDataSource> dataSource;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) XNTableViewCellSeparatorStyle separatorStyle;
@property (nonatomic, retain) UIColor *separatorColor;
@property (nonatomic, retain) UIView *tableHeaderView;
@property (nonatomic, retain) UIView *tableFooterView;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsSelectionDuringEditing;	// not implemented
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic) CGFloat sectionHeaderHeight;
@property (nonatomic) CGFloat sectionFooterHeight;

@end
