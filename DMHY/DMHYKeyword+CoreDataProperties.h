//
//  DMHYKeyword+CoreDataProperties.h
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DMHYKeyword.h"
#import "DMHYCategory+CoreDataProperties.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHYKeyword (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDate *createDate;
@property (nullable, nonatomic, retain) NSSet<DMHYTorrent *> *torrents;
@property (nullable, nonatomic, retain) DMHYCategory *category;

@end

@interface DMHYKeyword (CoreDataGeneratedAccessors)

- (void)addTorrentsObject:(DMHYTorrent *)value;
- (void)removeTorrentsObject:(DMHYTorrent *)value;
- (void)addTorrents:(NSSet<DMHYTorrent *> *)values;
- (void)removeTorrents:(NSSet<DMHYTorrent *> *)values;

@end

NS_ASSUME_NONNULL_END
