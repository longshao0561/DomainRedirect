#import <Foundation/Foundation.h>

static NSString *kOldDomain = @"api1.7ccccccc.com";
static NSString *kNewDomain = @"api123.hezijun.top";  // 改成你的服务器

// 目标 Bundle ID 列表（用于日志过滤）
static NSArray *kTargetBundleIDs = @[
    @"me.ele.lpd.talaris.store",
    @"me.ele.ios.LPDCrowdsourceAppStore"
];

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    if ([URLString containsString:kOldDomain]) {
        NSString *newURLString = [URLString stringByReplacingOccurrencesOfString:kOldDomain 
                                                                       withString:kNewDomain];
        NSLog(@"[DomainRedirect] %@ -> %@", URLString, newURLString);
        return %orig(newURLString);
    }
    return %orig(URLString);
}

+ (instancetype)URLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
    if ([URLString containsString:kOldDomain]) {
        NSString *newURLString = [URLString stringByReplacingOccurrencesOfString:kOldDomain 
                                                                       withString:kNewDomain];
        return %orig(newURLString, baseURL);
    }
    return %orig(URLString, baseURL);
}

%end

%hook NSString

- (BOOL)isEqualToString:(NSString *)aString {
    if ([aString isEqualToString:kOldDomain]) {
        return %orig(kNewDomain);
    }
    if ([self isEqualToString:kOldDomain]) {
        return [kNewDomain isEqualToString:aString];
    }
    return %orig(aString);
}

- (BOOL)containsString:(NSString *)aString {
    if ([aString isEqualToString:kOldDomain]) {
        return %orig(kNewDomain);
    }
    return %orig(aString);
}

%end

%hook NSURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    if ([URL.absoluteString containsString:kOldDomain]) {
        NSString *newURLString = [URL.absoluteString stringByReplacingOccurrencesOfString:kOldDomain 
                                                                                 withString:kNewDomain];
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return %orig(newURL);
    }
    return %orig(URL);
}

%end
