//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import <Foundation/Foundation.h>

/// A binary block defining some piecewise reduction of a collection.
///
/// \param into The result of the previous step of the reduction.
/// \param each The object being reduced at this step of the reduction.
///
/// \return The result of this step of the reduction, which will become the value of \c into passed to the next step of the reduction.
typedef id(^REDReducingBlock)(id into, id each);


/// A piecewise-reducible collection.
@protocol REDReducible <NSObject>

/// Produce a piecewise reduction of the receiver.
///
/// \param initial The initial result of the reduction. This should be some identity element of the operation, i.e. 0 for addition, 1 for multiplication, or an empty collection or string for appending.
/// \param block The block used to reduce the receiver.
///
/// \return The result of applying the block to each eleemnt of the receiver, with \c initial used as the first result, and the result of the each successive step applied as the \c into parameter of the next step.
-(id)red_reduce:(id)initial usingBlock:(REDReducingBlock)block;

@end


#pragma mark Categories

/// \c NSArray conforms to \c REDReducible
@interface NSArray (REDReducible) <REDReducible>
@end


/// \c NSSet conforms to \c REDReducible
@interface NSSet (REDReducible) <REDReducible>
@end