#import "TUTaskListView.h"

@implementation TUTaskListView

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		resizetarget = nil;
		totalheight = -1;
		[self setAutoresizesSubviews:YES];
	}
	return self;
}

- (void)addTaskView:(TUTaskView *)taskview
{
	taskview.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[self addSubview:taskview];
	[self _layoutSubviews];
}

- (void)removeTaskView:(TUTaskView *)taskview
{
	//	[self _markAsResizable:subview];
	//	[self _calcTotalHeightExcluding:subview];
	//	[self _notifySizeChange];
	[taskview removeFromSuperview];
	[self _layoutSubviews];
}

- (BOOL)containsTaskView:(TUTaskView *)taskview
{
	return [self.subviews indexOfObjectIdenticalTo:taskview] != NSNotFound;
}

- (void)setHeight:(CGFloat)height forView:(NSView *)view
{
	NSRect frame = view.frame;
	frame.size.height = height;
	view.frame = frame;
	[self _layoutSubviews];
}

- (void)_layoutSubviews
{
	CGFloat oldheight = totalheight;

	totalheight = 0;
	for (NSView *subview in [self.subviews reverseObjectEnumerator])
		totalheight += subview.frame.size.height + 1;
	if (totalheight)
		totalheight -= 1;

	NSRect listframe = self.frame;
	CGFloat y = listframe.size.height - totalheight;

	for (NSView *subview in [self.subviews reverseObjectEnumerator]) {
		NSRect frame = subview.frame;

		frame.origin.x = 0;
		frame.origin.y = y;
		frame.size.width = listframe.size.width;

		subview.frame = frame;

		y += frame.size.height + 1;
	}

	if (oldheight != totalheight) {
		[resizetarget performSelector:resizeaction withObject:self];
	}

	//	CGFloat newheight=y;
	//	CGFloat newy=listframe.origin.y+newheight-listframe.size.height;
	//	[self setFrame:NSMakeRect(listframe.origin.x,newy,listframe.size.width,newheight)];
	//	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
	BOOL isblue = NO;

	NSColor *whitecol = [NSColor whiteColor];
	NSColor *bluecol = [NSColor colorWithCalibratedRed:237.0 / 255.0 green:242.0 / 255.0 blue:1 alpha:1];

	for (NSView *subview in self.subviews) {
		NSRect frame = subview.frame;

		if (isblue)
			[bluecol set];
		else
			[whitecol set];
		isblue = !isblue;

		[NSBezierPath fillRect:frame];

		[[NSColor lightGrayColor] set];
		[NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height, frame.size.width, 1)];
	}
}

- (void)setResizeAction:(SEL)action target:(id)target
{
	resizeaction = action;
	resizetarget = target;
}

- (NSSize)preferredSize
{
	return NSMakeSize(self.frame.size.width, totalheight);
}

@end

@implementation TUTaskView

- (instancetype)init
{
	if ((self = [super init])) {
	}
	return self;
}

- (TUTaskListView *)taskListView
{
	id superview = self.superview;
	if (!superview)
		return nil;
	if (![superview isKindOfClass:[TUTaskListView class]])
		return nil;

	return superview;
}

@end

@implementation TUMultiTaskView

- (instancetype)init
{
	if ((self = [super init])) {
		[self setAutoresizesSubviews:YES];
	}
	return self;
}

- (void)setDisplayedView:(NSView *)dispview
{
	for (NSView *subview in self.subviews)
		[subview removeFromSuperview];

	NSSize viewsize = dispview.frame.size;
	NSSize selfsize = self.frame.size;

	if (!selfsize.height) {
		selfsize = viewsize;
		self.frame = NSMakeRect(0, 0, selfsize.width, selfsize.height);
	}

	dispview.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	dispview.frame = NSMakeRect(0, 0, selfsize.width, viewsize.height);
	[self addSubview:dispview];

	[[self taskListView] setHeight:viewsize.height forView:self];
}

@end
