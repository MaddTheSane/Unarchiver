#import <Cocoa/Cocoa.h>
#import <XADMaster/XADString.h>

@interface TUEncodingPopUp:NSPopUpButton
{
}

-(instancetype)initWithFrame:(NSRect)frame;
-(instancetype)initWithCoder:(NSCoder *)coder;

-(void)buildEncodingList;
-(void)buildEncodingListWithAutoDetect;
-(void)buildEncodingListWithDefaultEncoding;
-(void)buildEncodingListMatchingXADString:(id <XADString>)string;

@property (class, readonly, copy) NSArray<NSDictionary<NSString*,id>*> *encodings;
+(CGFloat)maximumEncodingNameWidthWithAttributes:(NSDictionary *)attrs;

@end
