//
//  NUXRequest.m
//  NuxeoSDK
//  Created by Arnaud Kervern on 2013-11-14.
//
/* (C) Copyright 2013-2014 Nuxeo SA (http://nuxeo.com/) and contributors.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * Contributors:
 *     Arnaud Kervern
 */

#import "NUXRequest.h"
#import "NUXJSONSerializer.h"
#import <ASIHTTPRequest.h>

@interface NUXRequest ()
@property NUXSession *session;
@property NSMutableDictionary *mutableHeaders;
@property NSMutableDictionary *mutableParameters;
@end

@implementation NUXRequest {
    NUXResponseBlock _completion;
    NUXResponseBlock _failure;
    
    NSData *_responseData;
}

-(id)init {
    self = [super init];
    if (self) {
        _shouldContinueWhenAppEntersBackground = NO;
        
        self.method = @"GET";
        self.contentType = @"application/json";
        
        _adaptors = [NSArray new];
        _categories = [NSArray new];
        _schemas = [NSArray new];
        _postData = [NSMutableData new];
        _mutableHeaders = [NSMutableDictionary new];
        _mutableParameters = [NSMutableDictionary new];
    }
    return self;
}

- (id)initWithSession:(NUXSession *)session {
    self = [self init];
    if (self) {
        self.session = session;
        self.url = [session.url URLByAppendingPathComponent:self.session.apiPrefix];
    }
    return self;
}

- (void)dealloc {
    _downloadDestinationPath = nil;
    _adaptors = Nil;
    _categories = Nil;
    _schemas = Nil;
    _responseMessage = Nil;
    _responseData = Nil;
    _contentType = Nil;
    self.url = Nil;
    self.method = Nil;
    self.repository = Nil;
    self.postData = Nil;
    self.mutableHeaders = nil;
    self.mutableParameters = nil;
    self.username = nil;
    self.password = nil;
}

- (NUXRequest *)addURLSegment:(NSString *)aSegment {
    if (aSegment != nil)
    {
        self.url = [self.url URLByAppendingPathComponent:aSegment];
    }
    return self;
}

- (NUXRequest *)addAdaptor:(NSString *)adaptor {
    [self addURLSegment:[NSString stringWithFormat:@"@%@", adaptor]];
    _adaptors = [_adaptors arrayByAddingObject:adaptor];
    return self;
}

- (NUXRequest *)addAdaptor:(NSString *)adaptor withValue:(NSString *)value {
    [self addAdaptor:adaptor];
    [self addURLSegment:value];
    return self;
}

- (NUXRequest *)addCategory:(NSString *)category {
    _categories = [_categories arrayByAddingObject:category];
    return self;
}

- (NUXRequest *)addCategories:(NSArray *)categories {
    _categories = [_categories arrayByAddingObjectsFromArray:categories];
    return self;
}

- (NUXRequest *)addSchema:(NSString *)schema {
    _schemas = [_schemas arrayByAddingObject:schema];
    return self;
}

- (NUXRequest *)addSchemas:(NSArray *)schemas {
    _schemas = [_schemas arrayByAddingObjectsFromArray:schemas];
    return self;
}


- (NUXRequest *)addHeaderValue:(NSString *)value forKey:(NSString *)key  {
    [self.mutableHeaders setObject:value forKey:key];
    return self;
}

- (NUXRequest *)addParameterValue:(NSString *)value forKey:(NSString *)key {
    [self.mutableParameters setObject:value forKey:key];
    return self;
}

- (NSDictionary *)headers {
    return [NSDictionary dictionaryWithDictionary:self.mutableHeaders];
}

- (NSDictionary *)parameters {
    return [NSDictionary dictionaryWithDictionary:self.mutableParameters];
}

- (void)setCompletionBlock:(NUXResponseBlock)aCompletionBlock {
    _completion = aCompletionBlock;
}

- (void)setFailureBlock:(NUXResponseBlock)aFailureBlock {
    _failure = aFailureBlock;
}

- (void)start {
    [self.session startRequest:self withCompletionBlock:^{
        if (_completion != nil) {
            _completion(self);
        }
    }             failureBlock:^{
        if (_failure != nil) {
            _failure(self);
        }
    }];
}

- (void)startSynchronous {
    [self.session startRequestSynchronous:self withCompletionBlock:^{
        if (_completion != nil) {
            _completion(self);
        }
    }                        failureBlock:^{
        if (_failure != nil) {
            _failure(self);
        }
    }];
}

- (void)startWithCompletionBlock:(NUXResponseBlock)completion FailureBlock:(NUXResponseBlock)failure {
    [self.session startRequest:self withCompletionBlock:^{
        completion(self);
    }             failureBlock:^{
        failure(self);
    }];
}


- (void)setResponseData:(NSData *)data WithEncoding:(NSStringEncoding)encoding StatusCode:(int)statusCode message:(NSString *)message error:(NSError *)error{
    _responseData = data;
    _responseStatusCode = statusCode;
    _responseMessage = message;
    _error = error;
}

- (NSData *)responseData {
    return _responseData;
}

- (NSString *)responseString {
    return [[NSString alloc] initWithData:[self responseData] encoding:NSUTF8StringEncoding];
}

- (id)responseJSONWithError:(NSError **)error {
    id res = [NSJSONSerialization JSONObjectWithData:[self responseData] options:NSJSONReadingMutableContainers error:error];

    return res;
}

- (id)responseEntityWithError:(NSError **)error {
    return [NUXJSONSerializer entityWithData:self.responseData error:error];
}

-(ASIHTTPRequest *)requestASI {
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:self.url];
    [request appendPostData:self.postData];
    
    if (self.parameters.count > 0) {
        NSMutableArray *parameters = [NSMutableArray new];
        [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *pKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *pValue = [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [parameters addObject:[NSString stringWithFormat:@"%@=%@", pKey, pValue]];
        }];
        request.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", request.url.absoluteString, [parameters componentsJoinedByString:@"&"]]];
    }
    
    return request;
}

@end
