#import <Cocoa/Cocoa.h>

@interface TUDockTileView : NSView
{
	double progress,lastupdate,lastwidth;
}

-(instancetype)initWithFrame:(NSRect)frame;

-(void)setCount:(NSInteger)count;
-(void)setProgress:(double)fraction;
-(void)hideProgress;

-(void)drawRect:(NSRect)rect;

@property (NS_NONATOMIC_IOSONLY, readonly) NSRect progressBarOuterFrame;
-(NSRect)progressBarFrameForFraction:(double)fraction;

@end
