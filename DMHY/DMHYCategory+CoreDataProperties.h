//
//  DMHYCategory+CoreDataProperties.h
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DMHYCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHYCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *order;
@property (nullable, nonatomic, retain) NSOrderedSet<DMHYKeyword *> *keywords;

@end

@interface DMHYCategory (CoreDataGeneratedAccessors)

- (void)insertObject:(DMHYKeyword *)value inKeywordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromKeywordsAtIndex:(NSUInteger)idx;
- (void)insertKeywords:(NSArray<DMHYKeyword *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeKeywordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInKeywordsAtIndex:(NSUInteger)idx withObject:(DMHYKeyword *)value;
- (void)replaceKeywordsAtIndexes:(NSIndexSet *)indexes withKeywords:(NSArray<DMHYKeyword *> *)values;
- (void)addKeywordsObject:(DMHYKeyword *)value;
- (void)removeKeywordsObject:(DMHYKeyword *)value;
- (void)addKeywords:(NSOrderedSet<DMHYKeyword *> *)values;
- (void)removeKeywords:(NSOrderedSet<DMHYKeyword *> *)values;

@end

NS_ASSUME_NONNULL_END
