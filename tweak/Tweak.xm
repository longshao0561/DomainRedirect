// DomainRedirect.m - 纯 ObjC 实现，不依赖 Substrate
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

static IMP original_URLWithString = NULL;

// 替换 NSURL URLWithString:
static id new_URLWithString(id self, SEL _cmd, NSString *urlString) {
    NSString *newString = urlString;
    for (NSString *oldDomain in kOldDomains) {
        if ([urlString containsString:oldDomain]) {
            newString = [newString stringByReplacingOccurrencesOfString:oldDomain 
                                                             withString:kDomainMapping[oldDomain]];
        }
    }
    if (newString != urlString) {
        NSLog(@"[DomainRedirect] URLWithString: %@ -> %@", urlString, newString);
    }
    return ((id (*)(id, SEL, NSString *))original_URLWithString)(self, _cmd, newString);
}

// 替换 NSString isEqualToString:
static IMP original_isEqualToString = NULL;
static BOOL new_isEqualToString(id self, SEL _cmd, NSString *aString) {
    for (NSString *oldDomain in kOldDomains) {
        if ([aString isEqualToString:oldDomain]) {
            BOOL ret = ((BOOL (*)(id, SEL, NSString *))original_isEqualToString)(self, _cmd, kDomainMapping[oldDomain]);
            NSLog(@"[DomainRedirect] isEqual: %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], ret);
            return ret;
        }
        NSString *selfStr = (NSString *)self;
        if ([selfStr isEqualToString:oldDomain]) {
            BOOL ret = [kDomainMapping[oldDomain] isEqualToString:aString];
            NSLog(@"[DomainRedirect] isEqual(self): %@ -> %@ = %d", oldDomain, kDomainMapping[oldDomain], ret);
            return ret;
        }
    }
    return ((BOOL (*)(id, SEL, NSString *))original_isEqualToString)(self, _cmd, aString);
}

// 构造函数，在 dylib 加载时自动执行
__attribute__((constructor))
static void init() {
    NSLog(@"[DomainRedirect] ========== INITIALIZED ==========");
    
    // Hook NSURL URLWithString:
    Class NSURLClass = objc_getClass("NSURL");
    SEL URLWithStringSel = sel_registerName("URLWithString:");
    Method URLWithStringMethod = class_getClassMethod(NSURLClass, URLWithStringSel);
    if (URLWithStringMethod) {
        original_URLWithString = method_getImplementation(URLWithStringMethod);
        method_setImplementation(URLWithStringMethod, (IMP)new_URLWithString);
        NSLog(@"[DomainRedirect] Hooked NSURL URLWithString:");
    }
    
    // Hook NSString isEqualToString:
    Class NSStringClass = objc_getClass("NSString");
    SEL isEqualSel = sel_registerName("isEqualToString:");
    Method isEqualMethod = class_getInstanceMethod(NSStringClass, isEqualSel);
    if (isEqualMethod) {
        original_isEqualToString = method_getImplementation(isEqualMethod);
        method_setImplementation(isEqualMethod, (IMP)new_isEqualToString);
        NSLog(@"[DomainRedirect] Hooked NSString isEqualToString:");
    }
    
    NSLog(@"[DomainRedirect] Ready to redirect domains: %@", kOldDomains);
}
