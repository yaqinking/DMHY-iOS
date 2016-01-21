//
//  ToolViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "ToolViewController.h"
#import "AppDelegate.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYCategory+CoreDataProperties.h"
#import "JGProgressHUD.h"

@interface ToolViewController()

@property (weak, nonatomic) IBOutlet UITextField *keywordTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *categoryControl;

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@end

@implementation ToolViewController

- (IBAction)addKeyword:(id)sender {
    NSString *keywordString = self.keywordTextField.text;
    NSInteger categoryIndex = self.categoryControl.selectedSegmentIndex;
    NSString *categoryString = [self.categoryControl titleForSegmentAtIndex:categoryIndex];
    NSLog(@"Keyword: %@ Category: %@", keywordString, categoryString);
    DMHYKeyword *keyword = [NSEntityDescription insertNewObjectForEntityForName:@"Keyword" inManagedObjectContext:self.managedObjectContext];
    keyword.name = keywordString;
    keyword.createDate = [NSDate new];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@",categoryString];
    NSArray *fetechCategories = [self.managedObjectContext executeFetchRequest:request
                                                          error:NULL];
//    NSLog(@"fetechCategories Count %i",fetechCategories.count);
    if (fetechCategories.count == 0) {
        DMHYCategory *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
        category.name = categoryString;
        keyword.category = category;
    } else {
        DMHYCategory *category = [fetechCategories firstObject];
        keyword.category = category;
    }
    
    [self saveContext];
    [self.keywordTextField resignFirstResponder];
    JGProgressHUD *copiedHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
    copiedHUD.textLabel.text = @"添加完成！";
    copiedHUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
    [copiedHUD showInView:self.view];
    [copiedHUD dismissAfterDelay:3.0];
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
