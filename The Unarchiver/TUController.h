#import <Cocoa/Cocoa.h>
#import <XADMaster/XADArchive.h>

#import "TUTaskQueue.h"
#import "TUArchiveController.h"
#import "TUArchiveTaskView.h"
#import "TUTaskListView.h"
@class TUEncodingPopUp;
#import "TUDockTileView.h"
#import "UserDefaultKeys.h"

@interface TUController : NSObject <NSApplicationDelegate> {
	TUTaskQueue *addtasks, *extracttasks;
	NSMutableArray *archivecontrollers;

	TUDockTileView *docktile;

	NSString *selecteddestination;

	BOOL opened;

	IBOutlet NSWindow *mainwindow;
	IBOutlet TUTaskListView *mainlist;
	IBOutlet TUEncodingPopUp *encodingpopup;

	IBOutlet NSWindow *prefswindow;
	IBOutlet NSTabView *prefstabs;
	IBOutlet NSTabViewItem *formattab;
	IBOutlet NSPopUpButton *destinationpopup;
	IBOutlet NSMenuItem *diritem;

	IBOutlet NSButton *singlefilecheckbox;

	//	NSMutableDictionary *filesyslocks;
	//	NSLock *metalock;
}

- (instancetype)init;

- (void)cleanupOrphanedTempDirectories;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSWindow *window;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasRunningExtractions;

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app;
- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename;

- (void)addArchiveControllersForFiles:(NSArray<NSString *> *)filenames destinationType:(UDKDestinationType)desttype;
- (void)addArchiveControllersForURLs:(NSArray<NSURL *> *)urls destinationType:(UDKDestinationType)desttype;
- (void)addArchiveControllerForFile:(NSString *)filename destinationType:(UDKDestinationType)desttype;
- (void)addArchiveController:(TUArchiveController *)archive;
- (void)actuallyAddArchiveController:(TUArchiveController *)archive;
- (TUArchiveController *)archiveControllerForFilename:(NSString *)filename;

- (void)findDestinationForArchiveController:(TUArchiveController *)archive;
- (void)gainAccessToDestinationForArchiveController:(TUArchiveController *)archive;
- (void)checkDestinationForArchiveController:(TUArchiveController *)archive;
- (void)archiveDestinationPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)res contextInfo:(void *)info;
- (void)archiveTaskView:(TUArchiveTaskView *)taskview notWritableResponse:(int)response;
- (void)prepareArchiveController:(TUArchiveController *)archive;
- (void)finishSetupForArchiveController:(TUArchiveController *)archive;
- (void)cancelSetupForArchiveController:(TUArchiveController *)archive;
- (void)addQueueEmpty:(TUTaskQueue *)queue;
- (void)archiveTaskViewCancelledBeforeExtract:(TUArchiveTaskView *)taskview;

- (void)startExtractionForArchiveController:(TUArchiveController *)archive;
- (void)archiveControllerFinished:(TUArchiveController *)archive;

- (void)listResized:(id)sender;

- (void)updateDestinationPopup;
- (IBAction)changeDestination:(id)sender;
- (void)destinationPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)res contextInfo:(void *)context;

- (void)unarchiveToCurrentFolderWithPasteboard:(NSPasteboard *)pboard
									  userData:(NSString *)data
										 error:(NSString **)error;
- (void)unarchiveToDesktopWithPasteboard:(NSPasteboard *)pboard
								userData:(NSString *)data
								   error:(NSString **)error;
- (void)unarchiveToWithPasteboard:(NSPasteboard *)pboard
						 userData:(NSString *)data
							error:(NSString **)error;

- (IBAction)unarchiveToCurrentFolder:(id)sender;
- (IBAction)unarchiveToDesktop:(id)sender;
- (IBAction)unarchiveTo:(id)sender;
- (void)selectAndUnarchiveFilesWithDestination:(UDKDestinationType)desttype;

- (IBAction)changeCreateFolder:(id)sender;

- (IBAction)openSupportBoard:(id)sender;
- (IBAction)openBugReport:(id)sender;
- (IBAction)openHomePage:(id)sender;

+ (NSImage *)iconForPath:(NSString *)path;

/*-(void)lockFileSystem:(NSString *)filename;
-(BOOL)tryFileSystemLock:(NSString *)filename;
-(void)unlockFileSystem:(NSString *)filename;
-(NSNumber *)_fileSystemNumber:(NSString *)filename;*/

@end
