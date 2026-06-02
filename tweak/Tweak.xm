#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 域名映射表
static NSDictionary *kDomainMapping = @{
    @"api1.7ccccccc.com": @"api123.hezijun.top",
    @"api2.7ccccccc.com": @"api123.hezijun.top", 
    @"api3.7ccccccc.com": @"api123.hezijun.top",
    @"1437378358.cn": @"api123.hezijun.top"
};

// 所有需要拦截的域名列表
static NSArray *kOldDomains = @[
    @"api1.7ccccccc.com",
    @"api2.7ccccccc.com", 
    @"api3.7ccccccc.com",
    @"1437378358.cn"
];

// 用于避免递归的标志
static BOOL isReplacing = NO;

%ctor {
    NSLog(@"[DomainRedirect] ✅ Loaded - Ready to redirect 7ccccccc domains");
}

// Hook NSString 的 isEqualToString: 方法
%hook NSString

- (BOOL)isEqualToString:(NSString *)aString {
    if (!isReplacing && aString && [aString isKindOfClass:[NSString class]]) {
        NSString *str = aString;
        for (NSString *oldDomain in kOldDomains) {
            if ([str isEqualToString:oldDomain]) {
                isReplacing = YES;
                BOOL result = %orig(kDomainMapping[oldDomain]);
                isReplacing = NO;
                NSLog(@"[DomainRedirect] 🎯 isEqualToString: %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], result);
                return result;
            }
        }
    }
    return %orig(aString);
}

// 同时 Hook containsString: 方法
- (BOOL)containsString:(NSString *)aString {
    if (!isReplacing && aString && [aString isKindOfClass:[NSString class]]) {
        NSString *str = aString;
        for (NSString *oldDomain in kOldDomains) {
            if ([str isEqualToString:oldDomain]) {
                isReplacing = YES;
                BOOL result = %orig(kDomainMapping[oldDomain]);
                isReplacing = NO;
                NSLog(@"[DomainRedirect] 🎯 containsString: %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], result);
                return result;
            }
        }
    }
    return %orig(aString);
}

%end

// 也 Hook NSURL 的 URLWithString:
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    if (!isReplacing && URLString) {
        NSString *newURL = URLString;
        BOOL replaced = NO;
        for (NSString *oldDomain in kOldDomains) {
            if ([URLString containsString:oldDomain]) {
                newURL = [newURL stringByReplacingOccurrencesOfString:oldDomain 
                                                           withString:kDomainMapping[oldDomain]];
                replaced = YES;
            }
        }
        if (replaced) {
            isReplacing = YES;
            NSURL *result = %orig(newURL);
            isReplacing = NO;
            NSLog(@"[DomainRedirect] 🌐 URLWithString: %@ -> %@", URLString, newURL);
            return result;
        }
    }
    return %orig(URLString);
}

%end
