#import <Cocoa/Cocoa.h>

@interface TUTaskQueue : NSObject {
	NSMutableArray *tasks;
	BOOL running, stalled;

	id finishtarget;
	SEL finishselector;
}

- (instancetype)init;

- (void)setFinishAction:(SEL)selector target:(id)target;

- (id)taskWithTarget:(id)target;
- (void)newTaskWithTarget:(id)target invocation:(NSInvocation *)invocation;

- (void)stallCurrentTask;
- (void)finishCurrentTask;

@property (readonly, getter=isRunning) BOOL running;
@property (readonly, getter=isStalled) BOOL stalled;
@property (readonly, getter=isEmpty) BOOL empty;

- (void)restart;

@end

@interface TUTaskTrampoline : NSProxy {
	id actual;
	TUTaskQueue *parent;
}

- (instancetype)initWithTarget:(id)target queue:(TUTaskQueue *)queue;

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
- (void)forwardInvocation:(NSInvocation *)invocation;

@end
