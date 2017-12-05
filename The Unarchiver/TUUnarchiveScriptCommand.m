#import "TUUnarchiveScriptCommand.h"
#import "UserDefaultKeys.h"

//keys for the parameters of the command
#define PKdestination @"destination"
#define PKdeleting @"deletingOriginal"
#define PKopening @"opening"
#define PKcreatingFolder @"creatingFolder"
#define PKwaitUntilFinished @"waitUntilFinished"

//! Enum for the AppleScript enumerarion "File Destination"
typedef NS_ENUM(OSType, destinationFolder) {
	destinationFolderDesktop = 'Desk',
	destinationFolderAskUser = 'AskU',
	destinationFolderOriginal = 'Orig',
	destinationFolderUserDefault = 'UDef'
};

//! Enum for the AppleScript enumerarion "Create new folder"
typedef NS_ENUM(OSType, creatingFolderEnum) {
	creatingFolderNever = 'NevE',
	creatingFolderOnly = 'OnlY',
	creatingFolderAlways = 'AlwA'
};

@implementation TUUnarchiveScriptCommand {
	NSTimer *restoringTimer;
	TUController *appController; //!< Needed for calling the unarchaving methods
	BOOL deleteOriginals;
	BOOL openFolders; //!< currently not used (at least in Not Legacy)
	BOOL waitUntilFinished;
	TUCreateEnclosingDirectory creatingFolder;
	UDKDestinationType desttype;
	NSString *extractDestination;
}

#pragma mark Overriding methods:
- (instancetype)initWithCommandDescription:(NSScriptCommandDescription *)commandDef
{
	self = [super initWithCommandDescription:commandDef];
	if (self) {
		extractDestination = [[NSUserDefaults standardUserDefaults] stringForKey:UDKDestinationPath];
		appController = [NSApplication sharedApplication].delegate;
	}
	return self;
}

- (id)performDefaultImplementation
{
/*
	 The commands will be something like:
	 unarchive listOfArchives(orPaths?) [to destination] [deleting yes] [opening yes]
	 */
#ifdef DEBUG
	NSLog(@"Running default implementation of command \"unarchive\"");
#endif

	//Get the files to unarchive (an array) and the arguments
	NSArray *files = self.directParameter;
	NSDictionary *evaluatedArgs = self.evaluatedArguments;

	//We check that all the files exists
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSString *file in files) {
		if (![fileManager fileExistsAtPath:file]) {
			return [self errorFileDontExist:file];
		}
	}
	//Check and evaluate the parameter "destination"
	id destination = evaluatedArgs[PKdestination];
	UDKDestinationType destinationIntValue;
	if (destination) {
		if ([destination isKindOfClass:[NSString class]] && [fileManager fileExistsAtPath:destination]) {
			extractDestination = destination;
			destinationIntValue = UDKDestinationCustomPath;
		} else {
			destinationFolder destinationLongValue = [destination unsignedIntValue];
			switch (destinationLongValue) {
				case destinationFolderDesktop:
					destinationIntValue = UDKDestinationCustomPath;
					extractDestination = (@"~/Desktop").stringByExpandingTildeInPath;
					break;
				case destinationFolderOriginal:
					destinationIntValue = UDKDestinationCurrentFolder;
					break;
				case destinationFolderAskUser:
					destinationIntValue = UDKDestinationSelected;
					break;
				case destinationFolderUserDefault:
					destinationIntValue = UDKDestinationDesktop;
					break;
				default:
					//If there is no parameter we use the user defaults
					destinationIntValue = [[NSUserDefaults standardUserDefaults] integerForKey:UDKDestination];
					break;
			}
		}
	} else {
		destinationIntValue = [[NSUserDefaults standardUserDefaults] integerForKey:UDKDestination];
	}
	desttype = destinationIntValue;

	//Get the rest of optional parameters
	deleteOriginals = [self evalBooleanParameterForKey:PKdeleting];
	openFolders = [self evalBooleanParameterForKey:PKopening];
	waitUntilFinished = [self evalBooleanParameterForKey:PKwaitUntilFinished];

	creatingFolderEnum creatingFolderValue = [evaluatedArgs[PKcreatingFolder] unsignedIntValue];
	switch (creatingFolderValue) {
		case creatingFolderNever:
			creatingFolder = TUCreateEnclosingDirectoryNever;
			break;
		case creatingFolderOnly:
			creatingFolder = TUCreateEnclosingDirectoryMutlipleFilesOnly;
			break;
		case creatingFolderAlways:
			creatingFolder = TUCreateEnclosingDirectoryAlways;
			break;
		default:
			creatingFolder = [[NSUserDefaults standardUserDefaults] integerForKey:UDKCreateFolderMode];
			break;
	}

	for (NSString *filename in files) {
		[self unarchiveFile:filename];
	}

	if (waitUntilFinished) {
		restoringTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5] interval:0.5 target:self selector:@selector(quitIfPossible) userInfo:nil repeats:YES];
		NSRunLoop *mainLoop = [NSRunLoop currentRunLoop];
		[mainLoop addTimer:restoringTimer forMode:NSDefaultRunLoopMode];
		[self suspendExecution];
	}
	return nil;
}

#pragma mark Custom methods

- (BOOL)evalBooleanParameterForKey:(NSString *)parameterKey
{
	NSDictionary *evaluatedArgs = self.evaluatedArguments;
	id parameter = evaluatedArgs[parameterKey];
	if (!parameter) {
		if ([parameterKey isEqualToString:PKdeleting]) {
			return [[NSUserDefaults standardUserDefaults] boolForKey:UDKDelete];
		}
		if ([parameterKey isEqualToString:PKopening]) {
			return [[NSUserDefaults standardUserDefaults] boolForKey:UDKOpen];
		}
		if ([parameterKey isEqualToString:PKwaitUntilFinished]) {
			return YES;
		}
	}
	return [parameter boolValue];
}

- (id)errorFileDontExist:(NSString *)file
{
	self.scriptErrorNumber = fnfErr;
	NSString *errorMessage = [NSString stringWithFormat:@"The file %@ doesn't exist.", file];
	self.scriptErrorString = errorMessage;
	return nil;
}

- (void)quitIfPossible
{
	if ([appController hasRunningExtractions]) {
		return;
	}
	[self resumeExecutionWithResult:nil];
}

- (void)unarchiveFile:(NSString *)fileName
{
	NSString *destination;
	switch (desttype) {
		default:
		case UDKDestinationCurrentFolder:
			destination = fileName.stringByDeletingLastPathComponent;
			break;
		case UDKDestinationDesktop:
			destination = [[NSUserDefaults standardUserDefaults] stringForKey:UDKDestinationPath];
			break;
		case UDKDestinationCustomPath:
			destination = extractDestination;
			break;
	}

	TUArchiveController *archiveController = [[TUArchiveController alloc] initWithFilename:fileName];
	archiveController.destination = destination;
	archiveController.deleteArchive = deleteOriginals;
	archiveController.folderCreationMode = creatingFolder;
	archiveController.openExtractedItem = openFolders;
	[appController addArchiveController:archiveController];
}

@end
