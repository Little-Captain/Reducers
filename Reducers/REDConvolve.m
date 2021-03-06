//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import "REDAppendable.h"
#import "REDConvolve.h"
#import "REDIterable.h"
#import "REDLogic.h"
#import "REDMap.h"

#pragma mark Convolve

@interface REDConvolver : NSObject <REDReducible, REDIterable>

+(instancetype)convolverWithReducibles:(id<REDIterable, REDReducible>)reducibles convolution:(REDConvolutionBlock)convolution;

@end

id<REDIterable, REDReducible> REDConvolve(id<REDIterable, REDReducible> reducibles, REDConvolutionBlock convolution) {
	return [REDConvolver convolverWithReducibles:reducibles convolution:convolution];
}


#pragma mark Convolution

@implementation REDConvolver {
	id<REDIterable, REDReducible> _reducibles;
	REDConvolutionBlock _convolution;
}

+(instancetype)convolverWithReducibles:(id<REDIterable, REDReducible>)reducibles convolution:(REDConvolutionBlock)convolution {
	return [[self alloc] initWithReducibles:reducibles convolution:convolution];
}

-(instancetype)initWithReducibles:(id<REDIterable, REDReducible>)reducibles convolution:(REDConvolutionBlock)convolution {
	if ((self = [super init])) {
		_reducibles = reducibles;
		_convolution = [convolution copy];
	}
	return self;
}


#pragma mark REDIterable

-(REDIteratingBlock)red_iterator {
	NSArray *iterators = [NSArray red_byAppending:REDMap(_reducibles, ^id (id<REDIterable> each) {
		return each.red_iterator;
	})];
	NSUInteger count = iterators.count;
	
	return ^{
		id __strong objects[count];
		__block id __strong *next = objects;
		
		return REDAnd(REDMap(iterators, ^(REDIteratingBlock each) { return (*next++ = each())? @YES : nil; }))?
			obstr_block_apply(_convolution, count, objects)
		:	nil;
	};
}

l3_test(@selector(red_iterator)) {
	REDIteratingBlock iterator = REDConvolve(@[ @"one", @"two", @"three" ], ^(NSString *a, NSString *b, NSString *c) {
		return [[a stringByAppendingString:b] stringByAppendingString:c];
	}).red_iterator;
	__block NSString *joined = @"";
	REDEnumerate(iterator, ^(NSString *each, bool *_) {
		joined = [joined stringByAppendingString:each];
	});
	l3_expect(joined).to.equal(@"ottnwheor");
}


#pragma mark REDReducible

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	__block id into = initial;
	REDEnumerate(self.red_iterator, ^(id each, bool *stop) {
		into = block(into, each);
		*stop = into != [into self];
	});
	return [into self];
}

l3_test(@selector(red_reduce:usingBlock:)) {
	REDReducingBlock append = ^(NSString *a, NSString *b) {
		return [a stringByAppendingString:b];
	};
	NSArray *convolution = [NSArray red_byAppending:REDConvolve(@[ @"fish", @"face" ], append)];
	l3_expect(convolution).to.equal(@[ @"ff", @"ia", @"sc", @"he" ]);
	
	convolution = [NSArray red_byAppending:REDConvolve(@[ REDMap(@"fish", ^(NSString *each) { return [each stringByAppendingString:each]; }), @"face" ], append)];
	l3_expect(convolution).to.equal(@[ @"fff", @"iia", @"ssc", @"hhe" ]);
}

@end
