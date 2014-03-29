//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import "REDReducible.h"

#pragma mark Categories

static inline id REDStrictReduce(id<NSFastEnumeration> collection, id initial, REDReducingBlock block) {
	for (id each in collection) {
		initial = block(initial, each);
	}
	return initial;
}

l3_addTestSubjectTypeWithFunction(REDStrictReduce)
l3_test(&REDStrictReduce) {
	NSArray *collection = @[ @"a", @"b", @"c" ];
	id initial;
	id (^lastObject)(id, id) = ^(id into, id each) { return each; };
	l3_expect(REDStrictReduce(collection, initial, lastObject)).to.equal(collection.lastObject);
}


@implementation NSArray (REDReducible)

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	return REDStrictReduce(self, initial, block);
}

@end


@implementation NSSet (REDReducible)

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	return REDStrictReduce(self, initial, block);
}

@end


@implementation NSDictionary (REDReducible)

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	return REDStrictReduce(self, initial, block);
}

l3_test(@selector(red_reduce:usingBlock:)) {
	NSSet *(^append)(NSSet *, id) = ^(NSSet *into, id each) { return [into setByAddingObject:each]; };
	NSDictionary *dictionary = @{ @"z": @'z', @"x": @'x', @"y": @'y', };
	NSSet *into = [NSSet set];
	l3_expect([dictionary red_reduce:into usingBlock:append]).to.equal([NSSet setWithArray:dictionary.allKeys]);
}

@end


@implementation NSString (REDReducible)

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	__block id result = initial;
	[self enumerateSubstringsInRange:(NSRange){ .length = self.length } options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		result = block(result, substring);
	}];
	return result;
}

l3_test(@selector(red_reduce:usingBlock:)) {
	NSString *(^append)(NSString *, id) = ^(NSString *into, NSString *each) { return [into stringByAppendingString:each]; };
	NSString *original = @"12345∆π¬µ∂🚑👖🐢🎈🔄";
	l3_expect([original red_reduce:@"" usingBlock:append]).to.equal(original);
}

@end


@implementation NSAttributedString (REDReducible)

-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block {
	__block id result = initial;
	[self.string enumerateSubstringsInRange:(NSRange){ .length = self.length } options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		result = block(result, [self attributedSubstringFromRange:substringRange]);
	}];
	return result;
}

l3_test(@selector(red_reduce:usingBlock:)) {
	NSAttributedString *(^append)(NSAttributedString *, NSAttributedString *) = ^(NSAttributedString *into, NSAttributedString *each) {
		NSMutableAttributedString *copy = [into mutableCopy];
		[copy appendAttributedString:each];
		return copy;
	};
	NSAttributedString *original = [[NSAttributedString alloc] initWithString:@"♬🐡😠" attributes:@{ @"key": @"value" }];
	l3_expect([original red_reduce:[NSAttributedString new] usingBlock:append]).to.equal(original);
}

@end
