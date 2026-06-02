#import <Foundation/Foundation.h>

static NSDictionary *kDomainMapping = @{
    @"api1.7ccccccc.com": @"api123.hezijun.top",
    @"api2.7ccccccc.com": @"api123.hezijun.top",
    @"api3.7ccccccc.com": @"api123.hezijun.top",
    @"1437378358.cn": @"api123.hezijun.top"
};

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *newURLString = URLString;
    
    for (NSString *oldDomain in kDomainMapping) {
        if ([URLString containsString:oldDomain]) {
            NSString *newDomain = kDomainMapping[oldDomain];
            newURLString = [newURLString stringByReplacingOccurrencesOfString:oldDomain 
                                                                    withString:newDomain];
        }
    }
    
    if (![newURLString isEqualToString:URLString]) {
        NSLog(@"[DomainRedirect] %@ -> %@", URLString, newURLString);
        return %orig(newURLString);
    }
    return %orig(URLString);
}

%end

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
