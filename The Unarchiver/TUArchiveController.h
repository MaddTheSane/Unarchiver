#import <XADMaster/XADSimpleUnarchiver.h>

#import "TUArchiveTaskView.h"
#import "TUDockTileView.h"
#import "UserDefaultKeys.h"

@class TUController, TUEncodingPopUp;

@interface TUArchiveController : NSObject <XADSimpleUnarchiverDelegate> {
	TUArchiveTaskView *view;
	TUDockTileView *docktile;
	XADSimpleUnarchiver *unarchiver;

	NSString *archivename, *destination, *tmpdest;
	NSStringEncoding selected_encoding;

	id finishtarget;
	SEL finishselector;

	TUCreateEnclosingDirectory foldermodeoverride;
	int copydateoverride, changefilesoverride;
	int deletearchiveoverride, openextractedoverride;

	BOOL cancelled, ignoreall, haderrors;

#ifndef IsLegacyVersion
	NSMutableArray<NSURL *> *scopedurls;
#endif
}

+ (void)clearGlobalPassword;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFilename:(NSString *)filename NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithURL:(NSURL *)url;

@property (strong) TUArchiveTaskView *taskView;
@property (strong) TUDockTileView *dockTileView;
@property (copy) NSString *destination;
@property (nonatomic) TUCreateEnclosingDirectory folderCreationMode;
@property (nonatomic) BOOL copyArchiveDateToExtractedFolder;
@property BOOL changeDateOfExtractedSingleItems;
@property (nonatomic) BOOL deleteArchive;
@property (nonatomic) BOOL openExtractedItem;

@property BOOL isCancelled;

#ifdef UseSandbox
- (void)useSecurityScopedURL:(NSURL *)url;
#endif

@property (readonly, copy) NSString *filename;
@property (readonly, copy) NSArray<NSString *> *allFilenames;
@property (readonly) BOOL volumeScanningFailed;
@property (readonly) BOOL caresAboutPasswordEncoding;

@property (readonly, copy) NSString *currentArchiveName;
- (NSString *)localizedDescriptionOfError:(XADError)error;
- (NSString *)stringForXADPath:(XADPath *)path;

- (void)prepare;
- (void)runWithFinishAction:(SEL)selector target:(id)target;

- (void)extractThreadEntry;
- (void)extract;
- (void)extractFinished;
- (void)extractFailed;
- (void)rememberTempDirectory:(NSString *)tmpdir;
- (void)forgetTempDirectory:(NSString *)tmpdir;

- (void)archiveTaskViewCancelled:(TUArchiveTaskView *)taskview;

@end
