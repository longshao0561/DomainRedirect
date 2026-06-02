#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSDictionary *kDomainMapping = @{
    @"api1.7ccccccc.com": @"api123.hezijun.top",
    @"api2.7ccccccc.com": @"api123.hezijun.top",
    @"api3.7ccccccc.com": @"api123.hezijun.top",
    @"1437378358.cn": @"api123.hezijun.top"
};

// 保存原始方法实现
static IMP original_dataTaskIMP = NULL;

// 替换后的方法实现
static id replaced_dataTaskWithRequest_CompletionHandler(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    // 替换 URL
    NSURL *originalURL = request.URL;
    NSString *urlString = originalURL.absoluteString;
    NSString *newURLString = urlString;
    
    for (NSString *oldDomain in kDomainMapping) {
        if ([urlString containsString:oldDomain]) {
            newURLString = [newURLString stringByReplacingOccurrencesOfString:oldDomain 
                                                                   withString:kDomainMapping[oldDomain]];
        }
    }
    
    if (![newURLString isEqualToString:urlString]) {
        NSURL *newURL = [NSURL URLWithString:newURLString];
        NSMutableURLRequest *newRequest = [request mutableCopy];
        newRequest.URL = newURL;
        request = newRequest;
        NSLog(@"[DomainRedirect] 🌐 Redirect: %@ -> %@", urlString, newURLString);
    }
    
    // 调用原始方法
    if (original_dataTaskIMP) {
        return ((id (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))original_dataTaskIMP)(self, _cmd, request, completionHandler);
    }
    
    // fallback
    return nil;
}

// 在加载时执行
%ctor {
    NSLog(@"[DomainRedirect] ✅ Loaded - Swizzling NSURLSession");
    
    Class NSURLSessionClass = NSClassFromString(@"NSURLSession");
    SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
    Method originalMethod = class_getInstanceMethod(NSURLSessionClass, originalSelector);
    
    if (originalMethod) {
        original_dataTaskIMP = method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, (IMP)replaced_dataTaskWithRequest_CompletionHandler);
        NSLog(@"[DomainRedirect] ✅ Swizzled dataTaskWithRequest:completionHandler:");
    } else {
        NSLog(@"[DomainRedirect] ❌ Failed to find method");
    }
}
