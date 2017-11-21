#import <Cocoa/Cocoa.h>

@class CSFileTypeListSource;

@interface CSFileTypeList:NSTableView
{
	CSFileTypeListSource *datasource;
	NSView *blockerview;
}

+(void)setDisabledInSandbox:(BOOL)disabled;

-(id)initWithCoder:(NSCoder *)coder;
-(id)initWithFrame:(NSRect)frame;
-(void)dealloc;

-(IBAction)selectAll:(id)sender;
-(IBAction)deselectAll:(id)sender;

@end

/*
	Columns:
	enabled (checkbox)
	description (string)
	extensions (string)
	[type] (string)
*/

@interface CSFileTypeListSource:NSObject <NSTableViewDataSource>
{
	NSArray *filetypes;
}

-(id)init;
-(void)dealloc;
-(NSArray *)readFileTypes;

-(void)claimAllTypesExceptAlternate;
-(void)surrenderAllTypes;
-(void)claimType:(NSString *)type;
-(void)surrenderType:(NSString *)type;
-(void)setHandler:(NSString *)handler forType:(NSString *)type;
-(void)removeHandlerForType:(NSString *)type;

@end

