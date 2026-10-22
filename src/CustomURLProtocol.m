#import "CustomURLProtocol.h"

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface CustomURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation CustomURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *requestURLString = request.URL.absoluteString;
    
    // Check if the request URL contains the exception string
    if ([requestURLString rangeOfString:@"https://search.itunes.apple.com"].location != NSNotFound) {
        return NO;
    }

    // analyzing failed requests in fiddler classic showed this was failing when not on the search.itunes.apple.com domain!
    if ([requestURLString rangeOfString:@"https://itunes.apple.com/WebObjects/MZStore.woa/wa/search"].location != NSNotFound) {
        return YES;
    }
    
    if ([requestURLString rangeOfString:@"dv6-storefront-p6bootstrap.js"].location != NSNotFound) {
        return YES;
    }
    
    if ([requestURLString rangeOfString:@"dv6-storefront-k6bootstrap.js"].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // Create a new request based on the original request
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    NSString *requestURLString = mutableRequest.URL.absoluteString;
    
    // Check if the request URL is the exception URL
    if ([requestURLString isEqualToString:@"https://search.itunes.apple.com/htmlResources/d04b/dv6-storefront-p6bootstrap.js"]) {
        // Allow this specific URL to go through without modification
        [self passThroughRequest:mutableRequest];
        return;
    }
    
    // Replace itunes.apple.com domain with search domain when searching; fixes 503 error
    requestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"https://itunes.apple.com/WebObjects/MZStore.woa/wa/search" withString:@"https://search.itunes.apple.com/WebObjects/MZStore.woa/wa/search"];

    // Replace "dv6-storefront-p6bootstrap.js" with "dv7-storefront-p7bootstrap.js"
    requestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"dv6-storefront-p6bootstrap.js" withString:@"dv7-storefront-p7bootstrap.js"];
    
    // Replace "dv6-storefront-k6bootstrap.js" with "dv7-storefront-k7bootstrap.js"
    requestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"dv6-storefront-k6bootstrap.js" withString:@"dv7-storefront-k7bootstrap.js"];
    
    mutableRequest.URL = [NSURL URLWithString:requestURLString];

    // Prevent infinite loops by marking this request as handled
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableRequest];

    // Create a connection with the modified request
    self.connection = [NSURLConnection connectionWithRequest:mutableRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
}

- (void)passThroughRequest:(NSURLRequest *)request {
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
