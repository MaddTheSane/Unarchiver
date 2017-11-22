#import "TUEncodingPopUp.h"

static BOOL SanityCheckString(NSString *string);

@implementation TUEncodingPopUp

-(instancetype)initWithFrame:(NSRect)frame
{
	if((self=[super initWithFrame:frame]))
	{
		//[self buildEncodingList];
	}
	return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
	if((self=[super initWithCoder:coder]))
	{
		//[self buildEncodingList];
	}
	return self;
}

-(void)buildEncodingList
{
	[self buildEncodingListMatchingXADString:nil];
}

-(void)buildEncodingListWithAutoDetect
{
	[self buildEncodingListMatchingXADString:nil];

	[self.menu addItem:[NSMenuItem separatorItem]];

	NSMenuItem *item=[[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Detect automatically",@"Option in the encoding pop-up to detect the encoding automatically")];
	item.tag = 0;
	[self.menu addItem:item];
}

-(void)buildEncodingListWithDefaultEncoding
{
	[self buildEncodingListMatchingXADString:nil];

	[self.menu insertItem:[NSMenuItem separatorItem] atIndex:0];

	NSMenuItem *item=[[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Default encoding",@"Option in the password encoding pop-up to use the default encoding")];
	item.tag = 0;
	[self.menu insertItem:item atIndex:0];
}

-(void)buildEncodingListMatchingXADString:(id <XADString>)string
{
	[self removeAllItems];

	NSMutableDictionary *normalattrs,*smallattrs;
	if(string)
	{
		normalattrs=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize:[NSFont systemFontSize]],NSFontAttributeName,
		nil];
		smallattrs=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
		nil];

		CGFloat maxwidth=[[self class] maximumEncodingNameWidthWithAttributes:normalattrs];

		NSMutableParagraphStyle *parastyle=[NSMutableParagraphStyle new];
		parastyle.tabStops = @[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxwidth+10]];

		normalattrs[NSParagraphStyleAttributeName] = parastyle;
		smallattrs[NSParagraphStyleAttributeName] = parastyle;
	}

	for(NSDictionary *encdict in [[self class] encodings])
	{
		NSStringEncoding encoding=[encdict[@"Encoding"] longValue];

		if(string && ![string canDecodeWithEncoding:encoding]) continue;

		NSString *encodingname=encdict[@"Name"];
		NSMenuItem *item=[NSMenuItem new];

		if(string)
		{
			NSString *decoded=[string stringWithEncoding:encoding];
			if(!SanityCheckString(decoded)) continue;

			NSMutableAttributedString *attrstr=[[NSMutableAttributedString alloc]
			initWithString:[NSString stringWithFormat:@"%@\t%C %@",encodingname,(unichar)0x27a4,decoded]
			attributes:normalattrs];

			[attrstr setAttributes:smallattrs range:NSMakeRange(encodingname.length,decoded.length+3)];

			item.attributedTitle = attrstr;
		}
		else
		{
			item.title = encodingname;
		}

		item.tag = encoding;
		[self.menu addItem:item];
	}
}


NSComparisonResult encoding_sort(NSDictionary *enc1,NSDictionary *enc2,void *dummy)
{
	NSString *name1=enc1[@"Name"];
	NSString *name2=enc2[@"Name"];
	/*BOOL isunicode1=[name1 hasPrefix:@"Unicode"];
	BOOL isunicode2=[name2 hasPrefix:@"Unicode"];

	if(isunicode1&&!isunicode2) return NSOrderedAscending;
	else if(!isunicode1&&isunicode2) return NSOrderedDescending;
	else*/ return [name1 compare:name2 options:NSCaseInsensitiveSearch|NSNumericSearch];
}

+(NSArray *)encodings
{
	NSMutableArray *encodingarray=[NSMutableArray array];
	const CFStringEncoding *encodings=CFStringGetListOfAvailableEncodings();

	while(*encodings!=kCFStringEncodingInvalidId)
	{
		CFStringEncoding cfencoding=*encodings++;
		NSString *name=[NSString localizedNameOfStringEncoding:CFStringConvertEncodingToNSStringEncoding(cfencoding)];
		NSStringEncoding encoding=CFStringConvertEncodingToNSStringEncoding(cfencoding);

		if(!name) continue;
		if(encoding==NSUnicodeStringEncoding) continue;

		[encodingarray addObject:@{@"Name": name,
			@"Encoding": @(encoding)}];
	}

	return [encodingarray sortedArrayUsingFunction:encoding_sort context:nil];
}

+(CGFloat)maximumEncodingNameWidthWithAttributes:(NSDictionary *)attrs
{
	CGFloat maxwidth=0;

	for(NSDictionary *encdict in [[self class] encodings])
	{
		NSString *name=encdict[@"Name"];
		CGFloat width=[name sizeWithAttributes:attrs].width;
		if(width>maxwidth) maxwidth=width;
	}
	return maxwidth;
}

@end

static BOOL IsSurrogateHighCharacter(unichar c)
{
    return c>=0xd800 && c<=0xdbff; 
}

static BOOL IsSurrogateLowCharacter(unichar c)
{
    return c>=0xdc00 && c<=0xdfff; 
}

static BOOL SanityCheckString(NSString *string)
{
	NSInteger length=string.length;
	for(int i=0;i<length;i++)
	{
		unichar c=[string characterAtIndex:i];
		if(IsSurrogateHighCharacter(c)) return NO;
		if(IsSurrogateLowCharacter(c))
		{
			i++;
			if(i>=length) return NO;
			unichar c2=[string characterAtIndex:i];
			if(!IsSurrogateHighCharacter(c2)) return NO;
		}
	}
	return YES;
}


/*+(NSDictionary *)encodingDictionary
{
	static NSDictionary *encodingdict=nil;
	if(!encodingdict) encodingdict=[[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:NSASCIIStringEncoding],@"US-ASCII",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)],@"Big5",
		[NSNumber numberWithUnsignedInt:NSJapaneseEUCStringEncoding],@"EUC-JP",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR)],@"EUC-KR",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)],@"GB18030",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_2312_80)],@"GB2312",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingHZ_GB_2312)],@"HZ-GB-2312",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSCyrillic)],@"IBM855",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSRussian)],@"IBM866",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_CN)],@"ISO-2022-CN",
		[NSNumber numberWithUnsignedInt:NSISO2022JPStringEncoding],@"ISO-2022-JP",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_KR)],@"ISO-2022-KR",
		[NSNumber numberWithUnsignedInt:NSISOLatin2StringEncoding],@"ISO-8859-2",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinCyrillic)],@"ISO-8859-5",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinGreek)],@"ISO-8859-7",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew)],@"ISO-8859-8",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew)],@"ISO-8859-8-I", // not sure about this!
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R)],@"KOI8-R",
		[NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding],@"Shift_JIS",
		// TIS-620 - missing
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF16BE)],@"UTF-16BE",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF16LE)],@"UTF-16LE",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE)],@"UTF-32BE",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE)],@"UTF-32LE",
		[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding],@"UTF-8",
		// X-ISO-10646-UCS-4-2143 - missing
		// X-ISO-10646-UCS-4-3412 - missing
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)],@"gb18030",
		[NSNumber numberWithUnsignedInt:NSWindowsCP1250StringEncoding],@"windows-1250",
		[NSNumber numberWithUnsignedInt:NSWindowsCP1251StringEncoding],@"windows-1251",
		[NSNumber numberWithUnsignedInt:NSWindowsCP1252StringEncoding],@"windows-1252",
		[NSNumber numberWithUnsignedInt:NSWindowsCP1253StringEncoding],@"windows-1253",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsHebrew)],@"windows-1255",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_TW)],@"x-euc-tw",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCyrillic)],@"x-mac-cyrillic",
		[NSNumber numberWithUnsignedInt:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacHebrew)],@"x-mac-hebrew",
	nil];
	return encodingdict;
}*/
