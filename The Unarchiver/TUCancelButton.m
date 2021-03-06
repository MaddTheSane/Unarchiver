#import "TUCancelButton.h"

@implementation TUCancelButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		normal = [NSImage imageNamed:@"close_normal"];
		hover = [NSImage imageNamed:@"close_hover"];
		press = [NSImage imageNamed:@"close_press"];
		self.image = normal;
		self.alternateImage = press;
		[self setShowsBorderOnlyWhileMouseInside:YES];
		((NSButtonCell *)self.cell).highlightsBy = NSContentsCellMask;
	}
	return self;
}

- (void)mouseEntered:(NSEvent *)event
{
	if (self.enabled)
		self.image = hover;
	[super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event
{
	self.image = normal;
	[super mouseExited:event];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (void)setTrackingRect
{
	NSPoint loc = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
	BOOL inside = ([self hitTest:loc] == self);
	if (inside)
		[self.window makeFirstResponder:self];
	trackingtag = [self addTrackingRect:self.visibleRect owner:self userData:nil assumeInside:inside];
}

- (void)clearTrackingRect
{
	[self removeTrackingRect:trackingtag];
}

- (void)resetCursorRects
{
	[super resetCursorRects];
	[self clearTrackingRect];
	[self setTrackingRect];
}

- (void)viewWillMoveToWindow:(NSWindow *)win
{
	if (!win && self.window)
		[self clearTrackingRect];
}

- (void)viewDidMoveToWindow
{
	if (self.window)
		[self setTrackingRect];
}

@end
