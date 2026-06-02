#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSDictionary *kDomainMapping = @{
    @"api1.7ccccccc.com": @"api123.hezijun.top",
    @"api2.7ccccccc.com": @"api123.hezijun.top",
    @"api3.7ccccccc.com": @"api123.hezijun.top",
    @"1437378358.cn": @"api123.hezijun.top"
};

// 替换字符串的核心函数
static NSString* replaceDomain(NSString *urlString) {
    if (!urlString) return nil;
    NSString *newURL = urlString;
    for (NSString *oldDomain in kDomainMapping) {
        if ([urlString containsString:oldDomain]) {
            newURL = [newURL stringByReplacingOccurrencesOfString:oldDomain 
                                                       withString:kDomainMapping[oldDomain]];
        }
    }
    if (![newURL isEqualToString:urlString]) {
        NSLog(@"[DomainRedirect] ✅ SUCCESS! Old: %@ -> New: %@", urlString, newURL);
    }
    return newURL;
}

// 使用 %ctor 在加载时执行
%ctor {
    NSLog(@"[DomainRedirect] 🎯 Tweak loaded! Ready to redirect domains.");
}

// Hook 1: NSURL URLWithString:
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *newURLString = replaceDomain(URLString);
    return %orig(newURLString);
}

+ (instancetype)URLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
    NSString *newURLString = replaceDomain(URLString);
    NSURL *newBaseURL = baseURL;
    if (baseURL && baseURL.absoluteString) {
        NSString *newBaseString = replaceDomain(baseURL.absoluteString);
        newBaseURL = [NSURL URLWithString:newBaseString];
    }
    return %orig(newURLString, newBaseURL);
}

%end

// Hook 2: NSURLComponents (很多应用用它来拼 URL)
%hook NSURLComponents

- (void)setURL:(NSURL *)URL {
    NSString *newURLString = replaceDomain(URL.absoluteString);
    %orig([NSURL URLWithString:newURLString]);
}

- (NSURL *)URL {
    NSURL *originalURL = %orig;
    NSString *newURLString = replaceDomain(originalURL.absoluteString);
    return [NSURL URLWithString:newURLString];
}

%end

// Hook 3: NSString 的请求相关方法
%hook NSString

- (BOOL)isEqualToString:(NSString *)aString {
    for (NSString *oldDomain in kDomainMapping) {
        if ([aString isEqualToString:oldDomain]) {
            return %orig(kDomainMapping[oldDomain]);
        }
        if ([self isEqualToString:oldDomain]) {
            return [kDomainMapping[oldDomain] isEqualToString:aString];
        }
    }
    return %orig(aString);
}

%end
