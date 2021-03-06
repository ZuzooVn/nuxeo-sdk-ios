//
//  NUXSession+requests.m
//  NuxeoSDK
//  Created by Arnaud Kervern on 2013-11-18.
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

#import "NUXSession+requests.h"
#import "NUXEntity.h"
#import "NUXJSONSerializer.h"

@implementation NUXSession (requests)

#pragma mark Internal methods

+ (NSString *)segmentForDocumentRef:(NSString *)docRef {
    return [docRef characterAtIndex:0] == '/' ? @"path" : @"id";
}

+ (NSData *)dataFromDocument:(id) document {
    NSData *data;
    // Handle JSON based document and NUXEntity serialized document
    if ([document isKindOfClass:[NUXEntity class]]) {
        data = [NUXJSONSerializer dataWithEntity:document error:nil];
    } else {
        data = [NSJSONSerialization dataWithJSONObject:document options:0 error:nil];
    }
    return data;
}

#pragma mark -
#pragma mark NUXRequest convenience methods

- (NUXRequest *)request {
    return [[NUXRequest alloc] initWithSession:self];
}

- (NUXRequest *)requestDocument:(NSString *)documentRef {
    return [[[[NUXRequest alloc] initWithSession:self] addURLSegment:[NUXSession segmentForDocumentRef:documentRef]] addURLSegment:documentRef];
}

- (NUXRequest *)requestUpdateDocument:(id)document {
    NUXRequest *request = [self request];
    request.method = @"put";
    [request.postData appendData:[NUXSession dataFromDocument:document]];
    [[request addURLSegment:@"id"] addURLSegment:[document valueForKey:@"uid"]];

    return request;
}

- (NUXRequest *)requestCreateDocument:(id)document withParent:(NSString *)documentRef {
    NUXRequest *request = [self requestDocument:documentRef];
    request.method = @"post";
    [request.postData appendData:[NUXSession dataFromDocument:document]];
    return request;
}

- (NUXRequest *)requestDeleteDocument:(NSString *)documentRef {
    NUXRequest *request = [self requestDocument:documentRef];
    request.method = @"delete";
    return request;
}

- (NUXRequest *)requestChildren:(NSString *)documentRef {
    return [[self requestDocument:documentRef] addAdaptor:@"children"];
}

- (NUXRequest *)requestQuery:(NSString *)query {
    NUXRequest *request = [[self request] addAdaptor:@"search"];
    [request addParameterValue:query forKey:@"query"];

    return request;
}

- (NUXRequest *)requestDownloadBlobFrom:(NSString *)documentRef inMetadata:(NSString *)metadata {
    NUXRequest *request = [self requestDocument:documentRef];
    [request addAdaptor:@"blob" withValue:metadata];
    
    return request;
}

#pragma mark -
#pragma mark NUXAutomationRequest convenience methods

- (NUXAutomationRequest *)requestOperation:(NSString *)operationId {
    NUXAutomationRequest *request = [[NUXAutomationRequest alloc] initWithSession:self];
    [[request addURLSegment:@"automation"] addURLSegment:operationId];
    return request;
}

- (NUXAutomationRequest *)requestImportFile:(NSString *)file withParent:(NSString *)documentRef {
    NUXAutomationRequest *request = [self requestOperation:@"FileManager.Import"];
    
    [request addContextValue:documentRef forKey:@"currentDocument"];
    [request setInputFile:file];
    
    return request;
}

- (NUXAutomationRequest *)requestParent:(NSString *)documentRef {
    NUXAutomationRequest *nuxRequest = [self requestOperation:@"Document.GetParent"] ;
    [nuxRequest setInput:documentRef];
    return nuxRequest;
}

- (NUXAutomationRequest *)move:(NSString *)documentSrc toTargetDocument:(NSString *)targetDocument {
    NUXAutomationRequest *nuxRequest = [self requestOperation:@"Document.Move"] ;
    [nuxRequest setInput:documentSrc];
    [nuxRequest addParameterValue:targetDocument forKey:@"target"];
    return nuxRequest;
}

- (NUXRequest *)requestACL:(NSString *)documentRef {
    return [[self requestDocument:documentRef] addAdaptor:@"acl"];
}

@end
