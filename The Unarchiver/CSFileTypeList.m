#import "CSFileTypeList.h"

static BOOL IsLeopardOrAbove()
{
	return NSAppKitVersionNumber >= 949;
}

static BOOL IsYosemiteOrAbove()
{
	return NSAppKitVersionNumber >= 1343;
}

@implementation CSFileTypeList

static BOOL DisabledInSandbox = YES;

+ (void)setDisabledInSandbox:(BOOL)disabled
{
	DisabledInSandbox = disabled;
}

+ (BOOL)disabledInSandbox
{
	return DisabledInSandbox;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		datasource = [CSFileTypeListSource new];
		self.dataSource = datasource;
		blockerview = nil;

		[self disableOnAppStore];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		NSLog(@"Custom view mode in IB not supported yet");

		datasource = [CSFileTypeListSource new];
		self.dataSource = datasource;
		blockerview = nil;

		[self disableOnAppStore];
	}
	return self;
}

- (IBAction)selectAll:(id)sender
{
	[datasource claimAllTypesExceptAlternate];
	[self reloadData];
}

- (IBAction)deselectAll:(id)sender
{
	[datasource surrenderAllTypes];
	[self reloadData];
}

- (void)disableOnAppStore
{
	if (!DisabledInSandbox)
		return;
	if (!getenv("APP_SANDBOX_CONTAINER_ID"))
		return;
	if (!IsYosemiteOrAbove())
		return;

	NSTextField *label = [[NSTextField alloc] initWithFrame:self.bounds];
	label.textColor = [NSColor whiteColor];
	label.backgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.75];
	label.font = [NSFont systemFontOfSize:17];
	label.alignment = NSCenterTextAlignment;
	[label setBezeled:NO];
	[label setEditable:NO];
	[label setSelectable:NO];
	label.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSString *appname = [NSBundle mainBundle].localizedInfoDictionary[@"CFBundleDisplayName"];
	if (!appname || !appname.length)
		appname = [NSBundle mainBundle].infoDictionary[@"CFBundleDisplayName"];
	if (!appname || !appname.length)
		appname = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];

	NSString *title = [NSString stringWithFormat:NSLocalizedString(
													 @"\nSetting %@ as the default app", @"App store file format limitation title"),
												 appname];
	NSString *message = [NSString stringWithFormat:NSLocalizedString(
													   @"\n\nTo set %1$@ to be the default application for a file type:\n\n"
													   @"1. Use the \"File -> Get Info\" menu in the Finder on a file of that type.\n"
													   @"2. Use \"Open with...\" to select %1$@.\n"
													   @"3. Click \"Change All...\"",
													   @"App store file format limitation message format"),
												   appname];

	NSMutableParagraphStyle *centeredstyle = [NSMutableParagraphStyle new];
	centeredstyle.firstLineHeadIndent = 32;
	centeredstyle.headIndent = 32;
	centeredstyle.tailIndent = -32;
	centeredstyle.alignment = NSCenterTextAlignment;

	NSMutableParagraphStyle *leftstyle = [NSMutableParagraphStyle new];
	leftstyle.firstLineHeadIndent = 32;
	leftstyle.headIndent = 32;
	leftstyle.tailIndent = -32;
	leftstyle.alignment = NSLeftTextAlignment;

	NSMutableAttributedString *string = [NSMutableAttributedString new];

	[string appendAttributedString:[[NSAttributedString alloc]
									   initWithString:title
										   attributes:@{NSFontAttributeName : [NSFont boldSystemFontOfSize:16],
														NSForegroundColorAttributeName : [NSColor whiteColor],
														NSParagraphStyleAttributeName : centeredstyle}]];

	[string appendAttributedString:[[NSAttributedString alloc]
									   initWithString:message
										   attributes:@{NSFontAttributeName : [NSFont boldSystemFontOfSize:12],
														NSForegroundColorAttributeName : [NSColor whiteColor],
														NSParagraphStyleAttributeName : leftstyle}]];

	label.attributedStringValue = string;

	blockerview = label;
	[self.superview addSubview:blockerview];
}

- (void)viewDidMoveToSuperview
{
	[blockerview removeFromSuperview];
	[self.superview addSubview:blockerview];
}

@end

@implementation CSFileTypeListSource : NSObject

- (instancetype)init
{
	if ((self = [super init])) {
		filetypes = [self readFileTypes];
	}
	return self;
}

- (NSArray *)readFileTypes
{
	NSMutableArray *array = [NSMutableArray array];
	NSArray *types = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
	NSArray *hidden = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CSHiddenDocumentTypes"];
	NSEnumerator *enumerator = [types objectEnumerator];
	NSDictionary *dict;

	while ((dict = [enumerator nextObject])) {
		NSArray *types = dict[@"LSItemContentTypes"];
		if (types && types.count) {
			NSString *description = dict[@"CFBundleTypeName"];
			NSString *extensions = [dict[@"CFBundleTypeExtensions"] componentsJoinedByString:@", "];
			NSString *type = types[0];

			NSString *rank = dict[@"LSHandlerRank"];
			NSNumber *alternate = [NSNumber numberWithBool:(BOOL)(rank != nil && [rank isEqual:@"Alternate"])];

			// Zip UTI kludge
			if (IsLeopardOrAbove() && [type isEqual:@"com.pkware.zip-archive"] && types.count > 1)
				type = types[1];

			if (!hidden || ![hidden containsObject:type])
				[array addObject:@{ @"type" : type,
									@"description" : description,
									@"extensions" : extensions,
									@"alternate" : alternate }];
		}
	}

	return [NSArray arrayWithArray:array];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)table
{
	return filetypes.count;
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSString *ident = column.identifier;

	if ([ident isEqual:@"enabled"]) {
		NSString *self_id = [NSBundle mainBundle].bundleIdentifier;
		NSString *type = filetypes[row][@"type"];
		NSString *handler = (id)CFBridgingRelease(LSCopyDefaultRoleHandlerForContentType((__bridge CFStringRef)type, kLSRolesViewer));

		return [NSNumber numberWithBool:(BOOL)([self_id caseInsensitiveCompare:handler] == 0)];
	} else if ([ident isEqual:@"browse"]) {
		NSString *type = filetypes[row][@"type"];
		NSString *key = [NSString stringWithFormat:@"disableBrowsing.%@", type];
		BOOL disabled = [[NSUserDefaults standardUserDefaults] boolForKey:key];

		return @(!disabled);
	} else {
		return filetypes[row][ident];
	}
}

- (void)tableView:(NSTableView *)table setObjectValue:(id)object forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSString *ident = column.identifier;

	if ([ident isEqual:@"enabled"]) {
		NSString *type = filetypes[row][@"type"];

		if ([object boolValue]) {
			[self claimType:type];
		} else {
			[self surrenderType:type];
		}
	} else if ([ident isEqual:@"browse"]) {
		NSString *type = filetypes[row][@"type"];
		NSString *key = [NSString stringWithFormat:@"disableBrowsing.%@", type];
		[[NSUserDefaults standardUserDefaults] setBool:![object boolValue] forKey:key];
	}
}

- (void)claimAllTypesExceptAlternate
{
	for (NSDictionary *type in filetypes) {
		if ([type[@"alternate"] boolValue]) {
			[self surrenderType:type[@"type"]];
		} else {
			[self claimType:type[@"type"]];
		}
	}
}

- (void)surrenderAllTypes
{
	for (NSDictionary *type in filetypes) {
		[self surrenderType:type[@"type"]];
	}
}

- (void)claimType:(NSString *)type
{
	NSString *self_id = [NSBundle mainBundle].bundleIdentifier;
	NSString *oldhandler = (id)CFBridgingRelease(LSCopyDefaultRoleHandlerForContentType((__bridge CFStringRef)type, kLSRolesViewer));

	if (oldhandler && [oldhandler caseInsensitiveCompare:self_id] != 0 && ![oldhandler isEqual:@"__dummy__"]) {
		NSString *key = [@"oldHandler." stringByAppendingString:type];
		[[NSUserDefaults standardUserDefaults] setObject:oldhandler forKey:key];
	}

	[self setHandler:self_id forType:type];
}

- (void)surrenderType:(NSString *)type
{
	NSString *self_id = [NSBundle mainBundle].bundleIdentifier;
	NSString *key = [@"oldHandler." stringByAppendingString:type];
	NSString *oldhandler = [[NSUserDefaults standardUserDefaults] stringForKey:key];

	if (oldhandler && [oldhandler caseInsensitiveCompare:self_id] != 0) {
		[self setHandler:oldhandler forType:type];
	} else {
		[self removeHandlerForType:type];
	}
}

- (void)setHandler:(NSString *)handler forType:(NSString *)type
{
	LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)type, kLSRolesViewer, (__bridge CFStringRef)handler);
}

- (void)removeHandlerForType:(NSString *)type
{
	NSMutableArray *handlers = [NSMutableArray array];
	NSString *self_id = [NSBundle mainBundle].bundleIdentifier;

	[handlers addObjectsFromArray:(id)CFBridgingRelease(LSCopyAllRoleHandlersForContentType((__bridge CFStringRef)type, kLSRolesViewer))];
	[handlers addObjectsFromArray:(id)CFBridgingRelease(LSCopyAllRoleHandlersForContentType((__bridge CFStringRef)type, kLSRolesEditor))];

	NSString *ext = (id)CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type, kUTTagClassFilenameExtension));
	NSString *filename = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"CSFileTypeList%04x.%@", rand() & 0xffff, ext]];
	NSURL *fileURL = [NSURL fileURLWithPath:filename];

	[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
	NSArray *apps = (NSArray *)CFBridgingRelease(LSCopyApplicationURLsForURL((__bridge CFURLRef)fileURL, kLSRolesAll));

#ifdef IsLegacyVersion
	[[NSFileManager defaultManager] removeFileAtPath:filename
											 handler:nil];
#else
	[[NSFileManager defaultManager] removeItemAtURL:fileURL
											  error:NULL];
#endif

	for (NSURL *url in apps) {
		NSBundle *bundle = [NSBundle bundleWithURL:url];
		if (!bundle)
			continue;
		[handlers addObject:bundle.bundleIdentifier];
	}

	for (;;) {
		NSUInteger index = [handlers indexOfObject:self_id];
		if (index == NSNotFound) {
			index = [handlers indexOfObject:self_id.lowercaseString];
		}
		if (index == NSNotFound) {
			break;
		}
		[handlers removeObjectAtIndex:index];
	}

	if (handlers.count) {
		[self setHandler:handlers[0] forType:type];
	} else {
		[self setHandler:@"__dummy__" forType:type];
	}
}

@end
