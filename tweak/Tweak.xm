#import <Foundation/Foundation.h>

static NSString *kOldDomain = @"api.7ccccccc.com";
static NSString *kNewDomain = @"api123.hezijun.top";  // 修改为你的服务器

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
