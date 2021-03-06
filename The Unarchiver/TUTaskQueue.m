#import "TUTaskQueue.h"

@implementation TUTaskQueue
@synthesize running;
@synthesize stalled;

- (instancetype)init
{
	if ((self = [super init])) {
		tasks = [NSMutableArray new];
		running = NO;
		stalled = NO;
		finishtarget = nil;
		finishselector = NULL;
	}
	return self;
}

- (void)setFinishAction:(SEL)selector target:(id)target
{
	finishtarget = target;
	finishselector = selector;
}

- (id)taskWithTarget:(id)target
{
	return [[TUTaskTrampoline alloc] initWithTarget:target queue:self];
}

- (void)newTaskWithTarget:(id)target invocation:(NSInvocation *)invocation
{
	[invocation retainArguments];

	[tasks addObject:target];
	[tasks addObject:invocation];

	[self restart];
}

- (void)stallCurrentTask
{
	if (!running) {
		return;
	}

	stalled = YES;
	running = NO;
}

- (void)finishCurrentTask
{
	if (!running) {
		return;
	}

	[tasks removeObjectAtIndex:0];
	[tasks removeObjectAtIndex:0];
	running = NO;

	[self restart];
}

- (BOOL)isEmpty
{
	return !running && !stalled;
}

- (void)restart
{
	if (running) {
		return;
	}
	if (!tasks.count) {
		[finishtarget performSelector:finishselector withObject:self];
		return;
	}

	running = YES;
	stalled = NO;

	[self performSelector:@selector(startTask) withObject:nil afterDelay:0];
}

- (void)startTask
{
	id target = tasks[0];
	NSInvocation *invocation = tasks[1];

	[invocation invokeWithTarget:target];
}

@end

@implementation TUTaskTrampoline

- (instancetype)initWithTarget:(id)target queue:(TUTaskQueue *)queue;
{
	actual = target;
	parent = queue;
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	return [actual methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	[parent newTaskWithTarget:actual invocation:invocation];
}

@end
