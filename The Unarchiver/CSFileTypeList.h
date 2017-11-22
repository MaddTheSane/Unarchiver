#import <Cocoa/Cocoa.h>

@class CSFileTypeListSource;

@interface CSFileTypeList : NSTableView {
	CSFileTypeListSource *datasource;
	NSView *blockerview;
}

@property (class) BOOL disabledInSandbox;

- (instancetype)initWithCoder:(NSCoder *)coder;
- (instancetype)initWithFrame:(NSRect)frame;

- (IBAction)selectAll:(id)sender;
- (IBAction)deselectAll:(id)sender;

@end

/*
	Columns:
	enabled (checkbox)
	description (string)
	extensions (string)
	[type] (string)
*/

@interface CSFileTypeListSource : NSObject <NSTableViewDataSource> {
	NSArray *filetypes;
}

- (instancetype)init NS_DESIGNATED_INITIALIZER;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString *> *readFileTypes;

- (void)claimAllTypesExceptAlternate;
- (void)surrenderAllTypes;
- (void)claimType:(NSString *)type;
- (void)surrenderType:(NSString *)type;
- (void)setHandler:(NSString *)handler forType:(NSString *)type;
- (void)removeHandlerForType:(NSString *)type;

@end
