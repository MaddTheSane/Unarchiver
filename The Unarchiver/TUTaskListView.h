#import <Cocoa/Cocoa.h>

@class TUTaskView;

@interface TUTaskListView : NSView {
	CGFloat totalheight;

	SEL resizeaction;
	id resizetarget;
}

- (instancetype)initWithFrame:(NSRect)frame;

- (void)addTaskView:(TUTaskView *)taskview;
- (void)removeTaskView:(TUTaskView *)taskview;
- (BOOL)containsTaskView:(TUTaskView *)taskview;
- (void)setHeight:(CGFloat)height forView:(NSView *)view;
- (void)_layoutSubviews;

- (void)setResizeAction:(SEL)action target:(id)target;

@property (readonly) NSSize preferredSize;

@end

@interface TUTaskView : NSView

- (instancetype)init;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) TUTaskListView *taskListView;

@end

@interface TUMultiTaskView : TUTaskView

- (instancetype)init;
- (void)setDisplayedView:(NSView *)dispview;

@end
