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

typedef enum {
    XNTableViewCellAccessoryNone,
    XNTableViewCellAccessoryDisclosureIndicator,
    XNTableViewCellAccessoryDetailDisclosureButton,
    XNTableViewCellAccessoryCheckmark
} XNTableViewCellAccessoryType;

typedef enum {
    XNTableViewCellSeparatorStyleNone,
    XNTableViewCellSeparatorStyleSingleLine,
    XNTableViewCellSeparatorStyleSingleLineEtched
} XNTableViewCellSeparatorStyle;

typedef enum {
    XNTableViewCellStyleDefault,
    XNTableViewCellStyleValue1,
    XNTableViewCellStyleValue2,
    XNTableViewCellStyleSubtitle
} XNTableViewCellStyle;

typedef enum {
    XNTableViewCellSelectionStyleNone,
    XNTableViewCellSelectionStyleBlue,
    XNTableViewCellSelectionStyleGray
} XNTableViewCellSelectionStyle;

typedef enum {
    XNTableViewCellEditingStyleNone,
    XNTableViewCellEditingStyleDelete,
    XNTableViewCellEditingStyleInsert
} XNTableViewCellEditingStyle;

@class XNTableViewCellSeparator, UILabel, UIImageView;

@interface XNTableViewCell : UIView {
@private
    XNTableViewCellStyle _style;
    XNTableViewCellSeparator *_seperatorView;
    UIView *_contentView;
    UILabel *_textLabel;
    UILabel *_detailTextLabel; // not yet displayed!
    UIImageView *_imageView;
    UIView *_backgroundView;
    UIView *_selectedBackgroundView;
    XNTableViewCellAccessoryType _accessoryType;
    UIView *_accessoryView;
    XNTableViewCellAccessoryType _editingAccessoryType;
    XNTableViewCellSelectionStyle _selectionStyle;
    NSInteger _indentationLevel;
    BOOL _editing;
    BOOL _selected;
    BOOL _highlighted;
    BOOL _showingDeleteConfirmation;
    NSString *_reuseIdentifier;
    CGFloat _indentationWidth;
}

- (id)initWithStyle:(XNTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
- (void)prepareForReuse;

@property (nonatomic, readonly, retain) UIView *contentView;
@property (nonatomic, readonly, retain) UILabel *textLabel;
@property (nonatomic, readonly, retain) UILabel *detailTextLabel;
@property (nonatomic, readonly, retain) UIImageView *imageView;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *selectedBackgroundView;
@property (nonatomic) XNTableViewCellSelectionStyle selectionStyle;
@property (nonatomic) NSInteger indentationLevel;
@property (nonatomic) XNTableViewCellAccessoryType accessoryType;
@property (nonatomic, retain) UIView *accessoryView;
@property (nonatomic) XNTableViewCellAccessoryType editingAccessoryType;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing; // not yet implemented
@property (nonatomic, readonly) BOOL showingDeleteConfirmation;  // not yet implemented
@property (nonatomic, readonly, copy) NSString *reuseIdentifier;
@property (nonatomic, assign) CGFloat indentationWidth; // 10 per default

@end
