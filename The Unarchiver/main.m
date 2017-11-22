#import <Cocoa/Cocoa.h>

int main(int argc,const char **argv)
{
	@autoreleasepool {

        NSString *desktop;

        #if MAC_OS_X_VERSION_MIN_REQUIRED>=MAC_OS_X_VERSION_10_4
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,NSUserDomainMask,YES);
        if(paths.count) desktop=paths[0];
        else desktop=[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
        #else
        desktop=[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
        #endif

        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"autoDetectionThreshold": @"80",
            @"filenameEncoding": @"0",
            @"deleteExtractedArchive": @"0",
            @"openExtractedFolder": @"0",
            #ifdef IsLegacyVersion
            @"1",@"extractionDestination",
            #else
            @"extractionDestination": @"4",
            #endif
            @"createFolder": @"1",
            @"folderModifiedDate": @"1",
            @"changeDateOfFiles": @"0",
            @"extractionDestinationPath": desktop}];

	}

	// Try to increase number of available file descriptors for huge multi-part archives.
	struct rlimit rl;
	int err=getrlimit(RLIMIT_NOFILE,&rl);
	if(err==0)
	{
		//rl.rlim_cur=RLIM_INFINITY;
		rl.rlim_cur=rl.rlim_max;
		setrlimit(RLIMIT_NOFILE,&rl);
	}

	return NSApplicationMain(argc,argv);
}
