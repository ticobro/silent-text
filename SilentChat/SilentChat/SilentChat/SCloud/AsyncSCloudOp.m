/*
Copyright © 2012-2013, Silent Circle, LLC.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Any redistribution, use, or modification is done solely for personal 
      benefit and not for any commercial purpose or for monetary gain
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name Silent Circle nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SILENT CIRCLE, LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//
//  AsyncSCloudOp.m
//  SilentText
//

#import "AsyncSCloudOp.h"
#import "SCloudObject.h"


@interface AsyncSCloudOp ()
{
    
    BOOL           isExecuting;
    BOOL           isFinished;
   
}
@property (nonatomic)       BOOL uploading;

@property (nonatomic)       size_t bytesExpectedToWrite;
@property (nonatomic)       size_t bytesWritten;

@property (nonatomic)        NSUInteger segmentsExpectedToRead;
@property (nonatomic)        NSUInteger segmentsRead;

@property (nonatomic,  readwrite)       SCloudObject* scloud;
@property (nonatomic, assign) id        userObject;
@property (nonatomic,  readwrite)       NSMutableDictionary* results;


@end

@implementation AsyncSCloudOp

- (id)initWithDelegate: (id)aDelegate
                scloud:(SCloudObject*) scloud
segmentsExpectedToRead:(NSUInteger)segmentsExpectedToRead
                object:(id)anObject
{
    self = [super init];
    if (self)
    {
        _uploading = NO;
        _delegate   = aDelegate;
        _scloud     = scloud;
        _segmentsExpectedToRead = segmentsExpectedToRead;
        _segmentsRead = 0;
        _userObject = anObject;
        isExecuting = NO;
        isFinished  = NO;
    }
    
    return self;

}

- (id)initWithDelegate: (id)aDelegate
                scloud:(SCloudObject*) scloud
   bytesExpectedToWrite:(size_t)bytesExpectedToWrite
                object:(id)anObject;
{
    self = [super init];
    if (self)
    {
        _uploading = YES;
        _delegate   = aDelegate;
        _scloud = scloud;
        _userObject = anObject;
        _bytesExpectedToWrite = bytesExpectedToWrite;
        _bytesWritten = 0;
        _results =  NSMutableDictionary.alloc.init;
        isExecuting = NO;
        isFinished  = NO;
    }
    
    return self;
}



-(void)dealloc
{
    _delegate     = NULL;
    _results    = NULL;
}


-(void)segmentDownload
{
    if(!_uploading)
    {
        _segmentsRead++;
        
        if(self.delegate )
        {
            [self.delegate AsyncSCloudOp:self uploadProgress: (float)_segmentsRead / (float)_segmentsExpectedToRead ];
        }
    }
    
   
}

-(void)updateProgress:(NSNumber *)bytesWritten ;
{
  
    if(_uploading)
    {
        _bytesWritten += [bytesWritten longValue];
        
        if(self.delegate )
        {
            [self.delegate AsyncSCloudOp:self uploadProgress: (float)_bytesWritten / (float)_bytesExpectedToWrite ];
        }
     }
     
}

-(void) didCompleteWithError:(NSError *)error  locatorString:(NSString*)locatorString
{
    if(error)
        [_results setObject: error forKey:locatorString];
    
}


#pragma mark - Overwriding NSOperation Methods

-(void)start
{
    // Makes sure that start method always runs on the main thread.
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
     
    [self performSelectorOnMainThread:@selector(didComplete) withObject:nil  waitUntilDone:NO];
    
    [self finish];

}

-(BOOL)isConcurrent
{
    return YES;
}

-(BOOL)isExecuting
{
    return isExecuting;
}

-(BOOL)isFinished
{
    return isFinished;
}

#pragma mark - Helper Methods

-(void)finish
{
     
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished  = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}




-(void)didComplete
{
    if(self.delegate)
    {
        NSError *error =  NULL;
        
        if(_uploading && [_results count])
        {
            
            NSString* key = [[_results allKeys] objectAtIndex:0];  
            error  = [_results objectForKey:key];
         }
        
        [self.delegate AsyncSCloudOp:self opDidCompleteWithError:error];
    }

}

@end

