#import "TUEncodingPopUp.h"

static BOOL IsSurrogateHighCharacter(unichar c)
{
	return c >= 0xd800 && c <= 0xdbff;
}

static BOOL IsSurrogateLowCharacter(unichar c)
{
	return c >= 0xdc00 && c <= 0xdfff;
}

BOOL TUSanityCheckString(NSString *string)
{
	NSInteger length = string.length;
	for (int i = 0; i < length; i++) {
		unichar c = [string characterAtIndex:i];
		if (IsSurrogateHighCharacter(c)) {
			return NO;
		}
		if (IsSurrogateLowCharacter(c)) {
			i++;
			if (i >= length) {
				return NO;
			}
			unichar c2 = [string characterAtIndex:i];
			if (!IsSurrogateHighCharacter(c2)) {
				return NO;
			}
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
