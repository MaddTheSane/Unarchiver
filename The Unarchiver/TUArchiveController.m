#import "TUArchiveController.h"
#import "TUController.h"
#import "TUTaskListView.h"
#import "TUEncodingPopUp.h"
#import <XADMaster/XADRegex.h>
#import <XADMaster/XADPlatform.h>
#import "UserDefaultKeys.h"



static NSString *globalpassword=nil;
NSStringEncoding globalpasswordencoding=0;

@implementation TUArchiveController
@synthesize taskView = view;
@synthesize dockTileView = docktile;
@synthesize destination;
@synthesize isCancelled = cancelled;
@synthesize folderCreationMode=foldermodeoverride;

+(void)clearGlobalPassword
{
	globalpassword=nil;
	globalpasswordencoding=0;
}

-(instancetype)initWithFilename:(NSString *)filename
{
	if((self=[super init]))
	{
		view=nil;
		docktile=nil;
		unarchiver=nil;

		archivename=[filename copy];
		destination=nil;
		tmpdest=nil;

		selected_encoding=0;

		finishtarget=nil;
		finishselector=NULL;

		foldermodeoverride=copydateoverride=changefilesoverride=-1;
		deletearchiveoverride=openextractedoverride=-1;

		cancelled=NO;
		ignoreall=NO;
		haderrors=NO;

#ifdef UseSandbox
		scopedurls=[NSMutableArray new];
#endif
	}
	return self;
}

-(instancetype)initWithURL:(NSURL *)url
{
	if (!url.fileURL) {
		return nil;
	}
	return self = [self initWithFilename:url.path];
}

-(void)dealloc
{
#ifdef UseSandbox
	for(NSURL *scopedurl in scopedurls)
	{
		[scopedurl stopAccessingSecurityScopedResource];
	}
#endif
}

-(TUCreateEnclosingDirectory)folderCreationMode
{
	if(foldermodeoverride>=0) return foldermodeoverride;
	else return [[NSUserDefaults standardUserDefaults] integerForKey:UDKCreateFolderMode];
}

-(BOOL)copyArchiveDateToExtractedFolder
{
	if(copydateoverride>=0) return copydateoverride!=0;
	else return [[NSUserDefaults standardUserDefaults] integerForKey:UDKModifyFolderDates]==2;
}

-(void)setCopyArchiveDateToExtractedFolder:(BOOL)copydate { copydateoverride=copydate; }

-(BOOL)changeDateOfExtractedSingleItems
{
	if(changefilesoverride>=0) return changefilesoverride!=0;
	else return [[NSUserDefaults standardUserDefaults] boolForKey:UDKModifyFileDates];
}

-(void)setChangeDateOfExtractedSingleItems:(BOOL)changefiles { changefilesoverride=changefiles; }

-(BOOL)deleteArchive
{
	if(deletearchiveoverride>=0) return deletearchiveoverride!=0;
	else return [[NSUserDefaults standardUserDefaults] boolForKey:UDKDelete];
}

-(void)setDeleteArchive:(BOOL)delete { deletearchiveoverride=delete; }

-(BOOL)openExtractedItem
{
	if(openextractedoverride>=0) return openextractedoverride!=0;
	else return [[NSUserDefaults standardUserDefaults] boolForKey:UDKOpen];
}

-(void)setOpenExtractedItem:(BOOL)open { openextractedoverride=open; }




#ifdef UseSandbox
-(void)useSecurityScopedURL:(NSURL *)url
{
	[url startAccessingSecurityScopedResource];
	[scopedurls addObject:url];
}
#endif




-(NSString *)filename
{
	if(!unarchiver) return archivename;
	else return unarchiver.outerArchiveParser.filename;
}

-(NSArray *)allFilenames
{
	if(!unarchiver) return nil;
	return unarchiver.outerArchiveParser.allFilenames;
}

-(BOOL)volumeScanningFailed
{
	NSNumber *failed=unarchiver.archiveParser.properties[XADVolumeScanningFailedKey];
	return failed && failed.boolValue;
}

-(BOOL)caresAboutPasswordEncoding { return unarchiver.archiveParser.caresAboutPasswordEncoding; }




-(NSString *)currentArchiveName
{
	NSString *currfilename=unarchiver.archiveParser.currentFilename;
	if(!currfilename) currfilename=unarchiver.outerArchiveParser.currentFilename;
	return currfilename.lastPathComponent;
}

-(NSString *)localizedDescriptionOfError:(XADError)error
{
	NSString *errorstr=[XADException describeXADError:error];
	NSString *localizederror=[[NSBundle mainBundle] localizedStringForKey:errorstr value:errorstr table:nil];
	return localizederror;
}

-(NSString *)stringForXADPath:(XADPath *)path
{
	NSStringEncoding encoding=[[NSUserDefaults standardUserDefaults] integerForKey:UDKFileNameEncoding];
	if(!encoding) encoding=selected_encoding;
	if(!encoding) encoding=path.encoding;
	return [path stringWithEncoding:encoding];
}




-(void)prepare
{
	unarchiver=[XADSimpleUnarchiver simpleUnarchiverForPath:archivename error:NULL];
}

-(void)runWithFinishAction:(SEL)selector target:(id)target
{
	finishtarget=target;
	finishselector=selector;

	[view setCancelAction:@selector(archiveTaskViewCancelled:) target:self];

	//[view setupProgressViewInPreparingMode];

	static int tmpcounter=0;
	NSString *tmpdir=[NSString stringWithFormat:@".TheUnarchiverTemp%d",tmpcounter++];
	tmpdest=[destination stringByAppendingPathComponent:tmpdir];

	[NSThread detachNewThreadSelector:@selector(extractThreadEntry) toTarget:self withObject:nil];
}

-(void)extractThreadEntry
{
	@autoreleasepool {
		[self extract];
	}
}

-(void)extract
{
	if(!unarchiver)
	{
		[view displayOpenError:[NSString stringWithFormat:
		NSLocalizedString(@"The contents of the file \"%@\" can not be extracted with this program.",@"Error message for files not extractable by The Unarchiver"),
		archivename.lastPathComponent]];

		[self performSelectorOnMainThread:@selector(extractFailed) withObject:nil waitUntilDone:NO];
		return;
	}

	TUCreateEnclosingDirectory foldermode=self.folderCreationMode;
	BOOL copydatepref=self.copyArchiveDateToExtractedFolder;
	BOOL changefilespref=self.changeDateOfExtractedSingleItems;

	unarchiver.delegate = self;
	[unarchiver setPropagatesRelevantMetadata:YES];
	[unarchiver setAlwaysRenamesFiles:YES];
	unarchiver.copiesArchiveModificationTimeToEnclosingDirectory = copydatepref;
	unarchiver.copiesArchiveModificationTimeToSoloItems = copydatepref && changefilespref;
	unarchiver.resetsDateForSoloItems = !copydatepref && changefilespref;

	XADError error=[unarchiver parse];
	if(error==XADErrorBreak)
	{
		[self performSelectorOnMainThread:@selector(extractFailed) withObject:nil waitUntilDone:NO];
		return;
	}
	else if(error)
	{
		if(![view displayError:[NSString stringWithFormat:
			NSLocalizedString(@"There was a problem while reading the contents of the file \"%@\": %@",@"Error message when encountering an error while parsing an archive"),
			self.currentArchiveName,
			[self localizedDescriptionOfError:error]]
		ignoreAll:&ignoreall])
		{
			[self performSelectorOnMainThread:@selector(extractFailed) withObject:nil waitUntilDone:NO];
			return;
		}
		else
		{
			haderrors=YES;
		}
	}

	switch(foldermode)
	{
		case TUCreateEnclosingDirectoryMutlipleFilesOnly: // Enclose multiple items.
		default:
			unarchiver.destination = tmpdest;
			[unarchiver setRemovesEnclosingDirectoryForSoloItems:YES];
			[self rememberTempDirectory:tmpdest];
			break;

		case TUCreateEnclosingDirectoryAlways: // Always enclose.
			unarchiver.destination = tmpdest;
			[unarchiver setRemovesEnclosingDirectoryForSoloItems:NO];
			[self rememberTempDirectory:tmpdest];
			break;

		case TUCreateEnclosingDirectoryNever: // Never enclose.
			unarchiver.destination = destination;
			[unarchiver setEnclosingDirectoryName:nil];
			break;
	}

	error=[unarchiver unarchive];
	if(error)
	{
		if(error!=XADErrorBreak)
		[view displayOpenError:[NSString stringWithFormat:
			NSLocalizedString(@"There was a problem while extracting the contents of the file \"%@\": %@",@"Error message when encountering an error while extracting entries"),
			self.currentArchiveName,
			[self localizedDescriptionOfError:error]]];

		[self performSelectorOnMainThread:@selector(extractFailed) withObject:nil waitUntilDone:NO];
		return;
	}

	[self performSelectorOnMainThread:@selector(extractFinished) withObject:nil waitUntilDone:NO];
}

-(void)extractFinished
{
	BOOL deletearchivepref=self.deleteArchive;
	BOOL openfolderpref=self.openExtractedItem;

	BOOL soloitem=unarchiver.wasSoloItem;

	// Move files out of temporary directory, if we used one.
	NSString *newpath=nil;
	if(unarchiver.enclosingDirectoryName)
	{
		NSString *path=unarchiver.createdItem;
		NSString *filename=path.lastPathComponent;

		newpath=[destination stringByAppendingPathComponent:filename];

		// Check if we accidentally created a package.
		if(!soloitem)
		if([[NSWorkspace sharedWorkspace] isFilePackageAtPath:path])
		{
			newpath=newpath.stringByDeletingPathExtension;
		}

		// Avoid collisions.
		newpath=[XADSimpleUnarchiver _findUniquePathForOriginalPath:newpath];

		// Move files into place
		[XADPlatform moveItemAtPath:path toPath:newpath];
		[XADPlatform removeItemAtPath:tmpdest];
	}

	// Remove temporary directory from crash recovery list.
	[self forgetTempDirectory:tmpdest];

	// Delete archive if requested, but only if no errors were encountered.
	if(deletearchivepref && !haderrors)
	{
		NSString *directory=archivename.stringByDeletingLastPathComponent;
		NSArray *allpaths=unarchiver.outerArchiveParser.allFilenames;
		NSMutableArray *allfiles=[NSMutableArray arrayWithCapacity:allpaths.count];
		NSEnumerator *enumerator=[allpaths objectEnumerator];
		NSString *path;
		while((path=[enumerator nextObject]))
		{
			if([path.stringByDeletingLastPathComponent isEqual:directory])
			[allfiles addObject:path.lastPathComponent];
		}

		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
		source:directory destination:@"" files:allfiles tag:nil];
		//[self playSound:@"/System/Library/Components/CoreAudio.component/Contents/Resources/SystemSounds/dock/drag to trash.aif"];
	}

	// Open folder if requested.
	if(openfolderpref)
	{
		if(newpath)
		{
			BOOL isdir;
			[[NSFileManager defaultManager] fileExistsAtPath:newpath isDirectory:&isdir];
			if(isdir&&![[NSWorkspace sharedWorkspace] isFilePackageAtPath:newpath])
			{
				[[NSWorkspace sharedWorkspace] openFile:newpath];
			}
			else
			{
				[[NSWorkspace sharedWorkspace] selectFile:newpath inFileViewerRootedAtPath:@""];
			}
		}
		else
		{
			[[NSWorkspace sharedWorkspace] openFile:destination];
		}
	}
	else if([newpath matchedByPattern:@"/Library/Mail Downloads/[^/]+$"])
	{
		[[NSWorkspace sharedWorkspace] selectFile:newpath inFileViewerRootedAtPath:@""];
	}

	[docktile hideProgress];
	[finishtarget performSelector:finishselector withObject:self];
}

-(void)extractFailed
{
	[XADPlatform removeItemAtPath:tmpdest];

	[self forgetTempDirectory:tmpdest];

	[docktile hideProgress];
	[finishtarget performSelector:finishselector withObject:self];
}

-(void)rememberTempDirectory:(NSString *)tmpdir
{
	NSUserDefaults *defs=[NSUserDefaults standardUserDefaults];
	NSArray *tmpdirs=[defs arrayForKey:@"orphanedTempDirectories"];
	if(!tmpdirs) tmpdirs=@[];
	[defs setObject:[tmpdirs arrayByAddingObject:tmpdir] forKey:@"orphanedTempDirectories"];
	[defs synchronize];
}

-(void)forgetTempDirectory:(NSString *)tmpdir
{
	NSUserDefaults *defs=[NSUserDefaults standardUserDefaults];
	NSMutableArray *tmpdirs=[[defs arrayForKey:@"orphanedTempDirectories"] mutableCopy];
	[tmpdirs removeObject:tmpdir];
	[defs setObject:tmpdirs forKey:@"orphanedTempDirectories"];
	[defs synchronize];
}




-(void)archiveTaskViewCancelled:(TUArchiveTaskView *)taskview
{
	cancelled=YES;
}




-(BOOL)extractionShouldStopForSimpleUnarchiver:(XADSimpleUnarchiver *)unarchiver
{
	return cancelled;
}

-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)sender encodingNameForXADString:(id <XADString>)string
{
	// TODO: Stop using NSStringEncoding.

	// If the user has set an encoding in the preferences, always use this.
	NSStringEncoding setencoding=[[NSUserDefaults standardUserDefaults] integerForKey:UDKFileNameEncoding];
	if(setencoding) return [XADString encodingNameForEncoding:setencoding];

	// If the user has already been asked for an encoding, try to use it.
	// Otherwise, if the confidence in the guessed encoding is high enough, try that.
	int threshold=(int)[[NSUserDefaults standardUserDefaults] integerForKey:UDKDetectionThreshold];

	NSStringEncoding encoding=0;
	if(selected_encoding) encoding=selected_encoding;
	else if(string.confidence*100>=threshold) encoding=string.encoding;

	// If we have an encoding we trust, and it can decode the string, use it.
	if(encoding && [string canDecodeWithEncoding:encoding])
	return [XADString encodingNameForEncoding:encoding];

	// Otherwise, ask the user for an encoding.
	selected_encoding=[view displayEncodingSelectorForXADString:string];
	if(!selected_encoding)
	{
		cancelled=YES;
		return nil;
	}
	return [XADString encodingNameForEncoding:selected_encoding];
}

-(void)simpleUnarchiverNeedsPassword:(XADSimpleUnarchiver *)sender
{
	if(globalpassword)
	{
		sender.password = globalpassword;
		if(globalpasswordencoding)
		{
			sender.archiveParser.passwordEncodingName =	[XADString encodingNameForEncoding:globalpasswordencoding];
		}
	}
	else
	{
		BOOL applytoall;
		NSStringEncoding encoding;
		NSString *password=[view displayPasswordInputWithApplyToAllPointer:&applytoall
		encodingPointer:&encoding];

		if(password)
		{
			sender.password = password;
			if(encoding)
			{
				sender.archiveParser.passwordEncodingName =	[XADString encodingNameForEncoding:encoding];
			}

			if(applytoall)
			{
				globalpassword=[password copy];
				globalpasswordencoding=encoding;
			}
		}
		else
		{
			cancelled=YES;
		}
	}
}

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)sender willExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path
{
	XADPath *name=dict[XADFileNameKey];

	// TODO: Do something prettier here.
	NSStringEncoding encoding=[[NSUserDefaults standardUserDefaults] integerForKey:UDKFileNameEncoding];
	if(!encoding) encoding=selected_encoding;
	if(!encoding) encoding=name.encoding;

	NSString *namestring=[name stringWithEncoding:encoding];

	if(name) [view setName:namestring];
	else [view setName:@""];
}

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)sender
extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileProgress:(off_t)fileprogress of:(off_t)filesize
totalProgress:(off_t)totalprogress of:(off_t)totalsize
{
	double progress;
	if(totalsize) progress=(double)totalprogress/(double)totalsize;
	else progress=1;

	[view setProgress:progress];
	[docktile setProgress:progress];
}

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)sender
estimatedExtractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileProgress:(double)fileprogress totalProgress:(double)totalprogress
{
	[view setProgress:totalprogress];
	[docktile setProgress:totalprogress];
}

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)sender didExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path error:(XADError)error;
{
	if(ignoreall||cancelled) return;

	if(error)
	{
		XADPath *filename=dict[XADFileNameKey];

		NSNumber *isresfork=dict[XADIsResourceForkKey];
		if(isresfork&&isresfork.boolValue)
		{
			cancelled=![view displayError:[NSString stringWithFormat:
				NSLocalizedString(@"Could not extract the resource fork for the file \"%@\" from the archive \"%@\":\n%@",@"Error message string. The first %@ is the file name, the second the archive name, the third is error message"),
				[self stringForXADPath:filename],
				self.currentArchiveName,
				[self localizedDescriptionOfError:error]]
			ignoreAll:&ignoreall];
		}
		else
		{
			cancelled=![view displayError:[NSString stringWithFormat:
				NSLocalizedString(@"Could not extract the file \"%@\" from the archive \"%@\": %@",@"Error message string. The first %@ is the file name, the second the archive name, the third is error message"),
				[self stringForXADPath:filename],
				self.currentArchiveName,
				[self localizedDescriptionOfError:error]]
			ignoreAll:&ignoreall];
		}

		haderrors=YES;
	}
}

/*-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)sender replacementPathForEntryWithDictionary:(NSDictionary *)dict
originalPath:(NSString *)path suggestedPath:(NSString *)unique;
-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)sender deferredReplacementPathForOriginalPath:(NSString *)path
suggestedPath:(NSString *)unique;*/

@end

