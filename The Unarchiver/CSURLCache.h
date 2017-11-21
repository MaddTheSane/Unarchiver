#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CSURLCacheProvider;

@interface CSURLCache:NSObject
{
	NSMutableArray *providers;
	NSMutableDictionary<NSString*,NSURL*> *cachedurls;
	NSMutableDictionary<NSString*,NSData*> *cachedbookmarks;
}

@property (class, readonly, strong, nullable) CSURLCache *defaultCache;

-(void)addURLProvider:(NSObject <CSURLCacheProvider> *)provider;
-(void)cacheSecurityScopedURL:(NSURL *)url;

-(nullable NSURL *)securityScopedURLAllowingAccessToURL:(NSURL *)url;
-(nullable NSURL *)securityScopedURLAllowingAccessToPath:(NSString *)path;

@end

@protocol CSURLCacheProvider

-(NSArray<NSString*> *)availablePaths;
-(nullable NSURL *)securityScopedURLForPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
