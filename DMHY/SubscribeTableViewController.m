//
//  SubscribeTableViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "SubscribeTableViewController.h"
#import "AppDelegate.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYCategory+CoreDataProperties.h"

#import "DetailSubscribeTableViewController.h"
#import "DMHYAPI.h"

@interface SubscribeTableViewController()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSMutableArray *categories;

@end

@implementation SubscribeTableViewController

- (void)viewDidLoad {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.categories = nil;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Detail Keyword"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        DMHYCategory *category = self.categories[indexPath.section];
        DMHYKeyword *keyword = category.keywords[indexPath.row];
        DetailSubscribeTableViewController *dstvc = segue.destinationViewController;
        NSString *pageURLString = [NSString stringWithFormat:DMHYSearchByKeyword, keyword.name];
        NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
        NSString *escapedString = [pageURLString stringByAddingPercentEncodingWithAllowedCharacters:set];
        dstvc.pageURL = [NSURL URLWithString:escapedString];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.categories.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DMHYCategory *category = self.categories[section];
    return category.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DMHYCategory *category = self.categories[section];
    return category.keywords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KeywordCell" forIndexPath:indexPath];
    DMHYCategory *category = self.categories[indexPath.section];
    DMHYKeyword *keyword = category.keywords[indexPath.row];
    cell.textLabel.text = keyword.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DMHYKeyword *keyword = [self keywordForIndexPath:indexPath];
        [self.managedObjectContext deleteObject:keyword];
        [self saveContext];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView reloadData];
    }
}

- (DMHYKeyword *)keywordForIndexPath:(NSIndexPath *)indexPath {
    DMHYCategory *category = self.categories[indexPath.section];
    return category.keywords[indexPath.row];
}

- (NSMutableArray *)categories {
    if (!_categories) {
        _categories = [[NSMutableArray alloc] init];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
        _categories = [[self.managedObjectContext executeFetchRequest:request error:NULL] mutableCopy];
    }
    return _categories;
}

- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = [[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = self.appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        _managedObjectModel = self.appDelegate.managedObjectModel;
    }
    return _managedObjectModel;
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
}
@end
