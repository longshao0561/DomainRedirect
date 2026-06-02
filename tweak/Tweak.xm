#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSDictionary *kDomainMapping = @{
    @"api1.7ccccccc.com": @"api123.hezijun.top",
    @"api2.7ccccccc.com": @"api123.hezijun.top",
    @"api3.7ccccccc.com": @"api123.hezijun.top",
    @"1437378358.cn": @"api123.hezijun.top"
};

static NSArray *kOldDomains = @[
    @"api1.7ccccccc.com",
    @"api2.7ccccccc.com", 
    @"api3.7ccccccc.com",
    @"1437378358.cn"
];

static BOOL isReplacing = NO;

// 替换字符串中的域名
static NSString* replaceDomainInString(NSString *str) {
    if (!str || isReplacing) return str;
    
    NSString *result = str;
    for (NSString *oldDomain in kOldDomains) {
        if ([result containsString:oldDomain]) {
            result = [result stringByReplacingOccurrencesOfString:oldDomain 
                                                       withString:kDomainMapping[oldDomain]];
        }
    }
    return result;
}

// Hook 1: NSString isEqualToString:
%hook NSString

- (BOOL)isEqualToString:(NSString *)aString {
    if (!isReplacing && aString) {
        for (NSString *oldDomain in kOldDomains) {
            if ([aString isEqualToString:oldDomain]) {
                isReplacing = YES;
                BOOL ret = %orig(kDomainMapping[oldDomain]);
                isReplacing = NO;
                NSLog(@"[DomainRedirect] isEqual: %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], ret);
                return ret;
            }
            if ([self isEqualToString:oldDomain]) {
                isReplacing = YES;
                BOOL ret = [kDomainMapping[oldDomain] isEqualToString:aString];
                isReplacing = NO;
                NSLog(@"[DomainRedirect] isEqual: %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], ret);
                return ret;
            }
        }
    }
    return %orig(aString);
}

- (BOOL)containsString:(NSString *)aString {
    if (!isReplacing && aString) {
        for (NSString *oldDomain in kOldDomains) {
            if ([aString isEqualToString:oldDomain]) {
                isReplacing = YES;
                BOOL ret = %orig(kDomainMapping[oldDomain]);
                isReplacing = NO;
                return ret;
            }
        }
    }
    return %orig(aString);
}

%end

// Hook 2: NSURL
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *newString = replaceDomainInString(URLString);
    if (newString != URLString) {
        NSLog(@"[DomainRedirect] URLWithString: %@ -> %@", URLString, newString);
    }
    return %orig(newString);
}

- (NSString *)absoluteString {
    NSString *orig = %orig;
    NSString *newString = replaceDomainInString(orig);
    if (newString != orig) {
        // 注意：这里不能直接修改，只是记录
        NSLog(@"[DomainRedirect] absoluteString: %@ -> %@", orig, newString);
    }
    return orig;  // 返回原始值，避免递归
}

%end

// Hook 3: NSURLRequest
%hook NSURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    NSString *urlString = URL.absoluteString;
    NSString *newString = replaceDomainInString(urlString);
    if (newString != urlString) {
        NSURL *newURL = [NSURL URLWithString:newString];
        NSLog(@"[DomainRedirect] requestWithURL: %@ -> %@", urlString, newString);
        return %orig(newURL);
    }
    return %orig(URL);
}

%end

// Hook 4: NSURLSession (原二进制的方法)
static IMP original_dataTaskIMP = NULL;

static id replaced_dataTaskWithRequest_CompletionHandler(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    NSString *newString = replaceDomainInString(urlString);
    
    if (newString != urlString) {
        NSMutableURLRequest *newRequest = [request mutableCopy];
        newRequest.URL = [NSURL URLWithString:newString];
        request = newRequest;
        NSLog(@"[DomainRedirect] dataTask: %@ -> %@", urlString, newString);
    }
    
    if (original_dataTaskIMP) {
        return ((id (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))original_dataTaskIMP)(self, _cmd, request, completionHandler);
    }
    return nil;
}

%ctor {
    NSLog(@"[DomainRedirect] ========== LOADED ==========");
    NSLog(@"[DomainRedirect] Target domains: %@", kOldDomains);
    NSLog(@"[DomainRedirect] New domain: api123.hezijun.top");
    
    // Hook NSURLSession
    Class sessionClass = NSClassFromString(@"NSURLSession");
    if (sessionClass) {
        SEL sel = @selector(dataTaskWithRequest:completionHandler:);
        Method m = class_getInstanceMethod(sessionClass, sel);
        if (m) {
            original_dataTaskIMP = method_getImplementation(m);
            method_setImplementation(m, (IMP)replaced_dataTaskWithRequest_CompletionHandler);
            NSLog(@"[DomainRedirect] NSURLSession hooked");
        } else {
            NSLog(@"[DomainRedirect] Failed to find NSURLSession method");
        }
    }
}
