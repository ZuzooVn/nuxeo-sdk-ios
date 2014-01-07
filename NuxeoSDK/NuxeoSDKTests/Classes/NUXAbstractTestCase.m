//
//  NUXAbstractTest.m
//  NuxeoSDK
//
//  Created by Arnaud Kervern on 27/11/13.
//  Copyright (c) 2013 Nuxeo. All rights reserved.
//

#import "NUXAbstractTestCase.h"
#import "NUXSQLiteDatabase.h"

#define NUX_XCTEST 1

@implementation NUXAbstractTestCase

-(id)init
{
    self = [super init];
    if (self) {
        self.continueAfterFailure = NO;
    }
    return self;
}

-(NUXDocument *)dummyDocument {
    NUXDocument *doc = [NUXDocument new];
    
    doc.uid = [NSString stringWithFormat:@"%@-%@-%@", @(random()), @(random()), @(random())];
    doc.title = [NSString stringWithFormat:@"Dummy Title %@", @(random())];
    doc.path = [NSString stringWithFormat:@"/%@/%@/%@", @(random()), @(random()), @(random())];
    doc.type = @"File";
    doc.name = [NSString stringWithFormat:@"%@", @(random())];
    doc.properties = [NSMutableDictionary dictionaryWithDictionary:@{@"file:content": @{@"digest": [NSString stringWithFormat:@"dummyDigest%@", @(random())], @"name" : @"dummyFilename.txt"}}];
    
    return doc;
}

- (void)setUp
{
    [super setUp];
    
    NSURL *url = [[NSURL alloc] initWithString:@"http://localhost:8080/nuxeo"];
    session = [[NUXSession alloc] initWithServerURL:url username:@"Administrator" password:@"Administrator"];
    [session addDefaultSchemas:@[@"dublincore"]];
    
    [[NUXSQLiteDatabase shared] deleteDatabase];
}

- (void)tearDown
{
    [super tearDown];
    
    session = Nil;
}

@end
