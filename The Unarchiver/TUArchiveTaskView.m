#import "TUArchiveTaskView.h"
#import "TUArchiveController.h"


@implementation TUArchiveTaskView
{
	NSMutableArray *nibObjects;
}
@synthesize archiveController = archive;

-(instancetype)init
{
	if((self=[super init]))
	{
		archive=nil;

		waitview=nil;
		progressview=nil;
		notwritableview=nil;
		errorview=nil;
		openerrorview=nil;
		passwordview=nil;
		encodingview=nil;

		pauselock=[[NSConditionLock alloc] initWithCondition:0];
		nibObjects = [[NSMutableArray alloc] init];
	}
	return self;
}


-(void)setCancelAction:(SEL)selector target:(id)target
{
	canceltarget=target;
	cancelselector=selector;
}



-(void)setName:(NSString *)name
{
	[namefield performSelectorOnMainThread:@selector(setStringValue:) withObject:name waitUntilDone:NO];
}

-(void)setProgress:(double)fraction
{
	[self performSelectorOnMainThread:@selector(_setProgress:)
	withObject:@(fraction) waitUntilDone:NO];
}

-(void)_setProgress:(NSNumber *)fraction
{
	if(progressindicator.indeterminate)
	{
		actionfield.stringValue = [NSString stringWithFormat:
		NSLocalizedString(@"Extracting \"%@\"",@"Status text while extracting an archive"),
		archive.filename.lastPathComponent];
		progressindicator.doubleValue = 0;
		progressindicator.maxValue = 1;
		[progressindicator setIndeterminate:NO];
		// TODO: Update dock
	}

	progressindicator.doubleValue = fraction.doubleValue;
	// TODO: Update dock
}




-(void)displayNotWritableErrorWithResponseAction:(SEL)selector target:(id)target
{
	[self performSelectorOnMainThread:@selector(setupNotWritableView) withObject:nil waitUntilDone:NO];
	[self setUIResponseAction:selector target:target];
}

-(BOOL)displayError:(NSString *)error ignoreAll:(BOOL *)ignoreall
{
	[self performSelectorOnMainThread:@selector(setupErrorView:) withObject:error waitUntilDone:NO];

	BOOL res=[self waitForResponseFromUI];

	[self performSelectorOnMainThread:@selector(setDisplayedView:) withObject:progressview waitUntilDone:NO];

	if(res && ignoreall)
	{
		if(errorapplyallcheck.state==NSOnState) *ignoreall=YES;
		else *ignoreall=NO;
	}

	return res;
}

-(void)displayOpenError:(NSString *)error
{
	[self performSelectorOnMainThread:@selector(setupOpenErrorView:) withObject:error waitUntilDone:NO];
	[self waitForResponseFromUI];
}

-(NSStringEncoding)displayEncodingSelectorForXADString:(id <XADString>)string
{
	[self performSelectorOnMainThread:@selector(setupEncodingViewForXADString:)
	withObject:string waitUntilDone:NO];

	BOOL res=[self waitForResponseFromUI];

	[self performSelectorOnMainThread:@selector(setDisplayedView:) withObject:progressview waitUntilDone:NO];

	if(res) return encodingpopup.selectedTag;
	else return 0;
}

-(NSString *)displayPasswordInputWithApplyToAllPointer:(BOOL *)applyall encodingPointer:(NSStringEncoding *)encoding
{
	[self performSelectorOnMainThread:@selector(setupPasswordView) withObject:nil waitUntilDone:NO];

	BOOL res=[self waitForResponseFromUI];

	[self performSelectorOnMainThread:@selector(setDisplayedView:) withObject:progressview waitUntilDone:NO];

	if(archive.caresAboutPasswordEncoding) *encoding=passwordpopup.selectedTag;
	else *encoding=0;

	if(res && applyall)
	{
		if(passwordapplyallcheck.state==NSOnState) *applyall=YES;
		else *applyall=NO;
	}

	if(res) return passwordfield.stringValue;
	else return nil;
}



-(void)setupWaitView
{
	if(!waitview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"WaitView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	[self updateWaitView];

	NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:archive.filename];
	icon.size = waiticon.frame.size;
	waiticon.image = icon;

	[self setDisplayedView:waitview];
}

-(void)updateWaitView
{
	NSString *filename=archive.filename.lastPathComponent;
	NSArray *allfilenames=archive.allFilenames;
	if(allfilenames && allfilenames.count>1)
	{
		waitfield.stringValue = [NSString stringWithFormat:
		NSLocalizedString(@"%@ (+%d more)",@"Status text for queued multi-part archives"),
		filename,allfilenames.count-1];
	}
	else
	{
		waitfield.stringValue = filename;
	}
}

-(void)setupProgressViewInPreparingMode
{
	if(!progressview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"ProgressView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	actionfield.stringValue = [NSString stringWithFormat:
	NSLocalizedString(@"Preparing to extract \"%@\"",@"Status text when preparing to extract an archive"),
	archive.filename.lastPathComponent];

	namefield.stringValue = @"";

	NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:archive.filename];
	icon.size = progressicon.frame.size;
	progressicon.image = icon;

	[progressindicator setIndeterminate:YES];
	[progressindicator startAnimation:self];

	[self setDisplayedView:progressview];
}

-(void)setupNotWritableView
{
	if(!notwritableview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"NotWritableView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	[self setDisplayedView:notwritableview];
	[self getUserAttention];
}

-(void)setupErrorView:(NSString *)error
{
	if(!errorview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"ErrorView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	errorfield.stringValue = error;
	[self setDisplayedView:errorview];
	[self getUserAttention];
}

-(void)setupOpenErrorView:(NSString *)error
{
	if(!openerrorview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"OpenErrorView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	openerrorfield.stringValue = error;
	[self setDisplayedView:openerrorview];
	[self getUserAttention];
}

-(void)setupPasswordView
{
	if(!passwordview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"PasswordView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	passwordmessagefield.stringValue = [NSString stringWithFormat:
	NSLocalizedString(@"You need to supply a password to open the archive \"%@\".",@"Status text when asking for a password"),
	archive.filename.lastPathComponent];

	NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:archive.filename];
	icon.size = passwordicon.frame.size;
	passwordicon.image = icon;

	if(archive.caresAboutPasswordEncoding)
	{
		NSRect frame=passwordview.frame;
		frame.size.height=106;
		passwordview.frame = frame;

		[passwordpopup buildEncodingListWithDefaultEncoding];
		[passwordpopup selectItemWithTag:0];
	}
	else
	{
		NSRect frame=passwordview.frame;
		frame.size.height=86;
		passwordview.frame = frame;

		[passwordpopuplabel setHidden:YES];
		[passwordpopup setHidden:YES];
	}

	[self setDisplayedView:passwordview];
	[passwordfield.window makeFirstResponder:passwordfield];
	[self getUserAttention];
}

-(void)setupEncodingViewForXADString:(id <XADString>)string
{
	namestring=string; // Does not need retaining, as the thread that provided it is paused.

	if(!encodingview)
	{
		NSArray *nibObjs = nil;
		NSNib *nib=[[NSNib alloc] initWithNibNamed:@"EncodingView" bundle:nil];
		[nib instantiateWithOwner:self topLevelObjects:&nibObjs];
		[nibObjects addObjectsFromArray:nibObjs];
	}

	NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:archive.filename];
	icon.size = encodingicon.frame.size;
	encodingicon.image = icon;

	NSStringEncoding encoding=string.encoding;

	[encodingpopup buildEncodingListMatchingXADString:string];
	if(encoding)
	{
		int index=(int)[encodingpopup indexOfItemWithTag:encoding];
		if(index>=0) [encodingpopup selectItemAtIndex:index];
		else [encodingpopup selectItemAtIndex:[encodingpopup indexOfItemWithTag:NSISOLatin1StringEncoding]];
	}

	[self selectEncoding:self];

	[self setDisplayedView:encodingview];
	[passwordfield.window makeFirstResponder:passwordfield];
	[self getUserAttention];
}




-(void)getUserAttention
{
	[self performSelectorOnMainThread:@selector(getUserAttentionOnMainThread) withObject:nil waitUntilDone:NO];
}

-(void)getUserAttentionOnMainThread
{
	[NSApp activateIgnoringOtherApps:YES];
	[self.window makeKeyAndOrderFront:self];
}




-(IBAction)cancelWait:(id)sender
{
	[sender setEnabled:NO];
	[canceltarget performSelector:cancelselector withObject:self];
}

-(IBAction)cancelExtraction:(id)sender
{
	[sender setEnabled:NO];
	[canceltarget performSelector:cancelselector withObject:self];
}

-(IBAction)stopAfterNotWritable:(id)sender
{
	[self provideResponseFromUI:0];
}

-(IBAction)extractToDesktopAfterNotWritable:(id)sender
{
	[self provideResponseFromUI:1];
}

-(IBAction)extractElsewhereAfterNotWritable:(id)sender
{
	[self provideResponseFromUI:2];
}

-(IBAction)stopAfterError:(id)sender
{
	[self provideResponseFromUI:NO];
}

-(IBAction)continueAfterError:(id)sender
{
	[self provideResponseFromUI:YES];
}

-(IBAction)okAfterOpenError:(id)sender
{
	[self provideResponseFromUI:0];
}

-(IBAction)stopAfterPassword:(id)sender
{
	[self provideResponseFromUI:NO];
}

-(IBAction)continueAfterPassword:(id)sender
{
	[self provideResponseFromUI:YES];
}

-(IBAction)stopAfterEncoding:(id)sender
{
	[self provideResponseFromUI:NO];
}

-(IBAction)continueAfterEncoding:(id)sender
{
	[self provideResponseFromUI:YES];
}

-(IBAction)selectEncoding:(id)sender
{
	NSStringEncoding encoding=encodingpopup.selectedTag;
	if([namestring canDecodeWithEncoding:encoding]) encodingfield.stringValue = [namestring stringWithEncoding:encoding];
	else encodingfield.stringValue = @""; // Can't happen, probably.
}



// Uiiiiii~ Aisuuuuu~
-(int)waitForResponseFromUI
{
	responsetarget=nil;
	[pauselock lockWhenCondition:1];
	[pauselock unlockWithCondition:0];
	return uiresponse;
}

-(void)setUIResponseAction:(SEL)selector target:(id)target
{
	responsetarget=target;
	responseselector=selector;
}

-(void)provideResponseFromUI:(int)response
{
	if(responsetarget)
	{
		NSInvocation *invocation=[NSInvocation invocationWithMethodSignature:
		[responsetarget methodSignatureForSelector:responseselector]];

		invocation.target = responsetarget;
		invocation.selector = responseselector;
		__unsafe_unretained id aSelf = self;
		[invocation setArgument:&aSelf atIndex:2];
		[invocation setArgument:&response atIndex:3];

		[invocation invoke];
//		[invocation performSelector:@selector(invoke) withObject:nil afterDelay:0];
	}
	else
	{
		uiresponse=response;
		[pauselock lockWhenCondition:0];
		[pauselock unlockWithCondition:1];
	}
}


@end
