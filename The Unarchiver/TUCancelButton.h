#import <Cocoa/Cocoa.h>


@interface TUCancelButton:NSButton
{
	NSImage *normal,*hover,*press;
	NSTrackingRectTag trackingtag;
}

-(instancetype)initWithCoder:(NSCoder *)coder;

-(void)mouseEntered:(NSEvent *)event;
-(void)mouseExited:(NSEvent *)event;

@end
