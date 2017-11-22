#import <Cocoa/Cocoa.h>
#import "UserDefaultKeys.h"

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

        [[NSUserDefaults standardUserDefaults] registerDefaults:@{UDKDetectionThreshold: @80,
            UDKFileNameEncoding: @0,
            UDKDelete: @NO,
            UDKOpen: @NO,
            #ifdef IsLegacyVersion
			UDKDestination: @(UDKDestinationCurrentFolder),
            #else
            UDKDestination: @(UDKDestinationUninitialized),
            #endif
            UDKCreateFolderMode: @(TUCreateEnclosingDirectoryMutlipleFilesOnly),
            UDKModifyFolderDates: @1,
            UDKModifyFileDates: @NO,
            UDKDestinationPath: desktop}];

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
