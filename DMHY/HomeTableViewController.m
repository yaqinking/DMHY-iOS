//
//  HomeTableViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "HomeTableViewController.h"

#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "DMHYAPI.h"
#import "Ono.h"
#import "JGProgressHUD.h"

#import "TorrentItem.h"
#import "TorrentTableViewCell.h"
#import "AppDelegate.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYCategory+CoreDataProperties.h"

#import "DMHYTool.h"

@interface HomeTableViewController ()

@property (nonatomic, strong) NSString *today;
@property (nonatomic, strong) NSString *yesterday;
@property (nonatomic, strong) NSMutableArray *torrents;

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSDateFormatter *dateFormater;

@property (nonatomic, strong) NSArray *keywordsToday;
@property (nonatomic, strong) NSArray *keywordsYearsToday;

@property (nonatomic, strong) NSArray *keywrodsRecently;

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSURL *downloadURL;
@property (nonatomic, getter=isShare) BOOL share;

@end

@implementation HomeTableViewController

- (void)viewDidLoad {
    // get the weekday of the current date

    [super viewDidLoad];
 
    [self configureDate];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)reloadData {
    self.tableView.userInteractionEnabled = NO;
    self.today = nil;
    self.yesterday = nil;
    self.torrents = nil;
    self.keywordsToday = nil;
    self.keywordsYearsToday = nil;
    [self configureDate];
}

- (void) configureDate {
    NSDate *now = [[NSDate alloc] init];
    
    NSCalendar* cal = [NSCalendar currentCalendar];
    
    NSDateComponents *com = [cal components:NSCalendarUnitWeekday fromDate:now];
    //    NSDateComponents* components = [cal components:NSWeekdayCalendarUnit fromDate:now];
    NSInteger weekdayToday = [com weekday]; // 1 = Sunday, 2 = Monday, etc.
    NSInteger yesterdayCode = weekdayToday - 1;
    if (yesterdayCode == 0) {
        yesterdayCode = 7;
    }
//    self.today = [self cn_weekdayFromWeekdayCode:weekdayToday];
    self.today = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday];
    self.yesterday = [DMHYTool cn_weekdayFromWeekdayCode:yesterdayCode];
    
    [self setupTorrentsData];
}

- (void) addLongPressGestureToCell:(UITableViewCell *)cell {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleShare:)];
    [cell addGestureRecognizer:longPress];
}

- (void) handleShare:(id) sender {
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
//    NSLog(@"Long Press Row %li",indexPath.row);
    self.share = YES;
    UIGestureRecognizerState state = longPress.state;
    switch (state) {
        case UIGestureRecognizerStateBegan:
            [self queryDownloadURLWithIndexPath:indexPath];
            break;
        case UIGestureRecognizerStateEnded:
            break;
        default:
            break;
    }
    
}

- (void) presentShareActivitiesWithItems:(NSArray *)items toSourceView:(UIView *)sourceView {
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    NSArray *excluedActivities = @[UIActivityTypePostToTwitter,
                                   UIActivityTypePostToFacebook,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToTencentWeibo,
                                   UIActivityTypePostToVimeo,
                                   UIActivityTypePostToWeibo,
                                   UIActivityTypePrint,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeOpenInIBooks,
                                   UIActivityTypeMessage,
                                   UIActivityTypeMail,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeAddToReadingList];
    shareController.excludedActivityTypes = excluedActivities;
    shareController.modalPresentationStyle = UIModalPresentationPopover;
    shareController.popoverPresentationController.sourceView = sourceView;
    shareController.popoverPresentationController.sourceRect = sourceView.bounds;
    [self presentViewController:shareController
                       animated:YES
                     completion:nil];

}

- (void) setupTorrentsData {
    for (DMHYKeyword *keyword in self.keywordsToday) {
        [self setupTorrentsWithKeyword:keyword.name];
    };
    for (DMHYKeyword *keyword in self.keywordsYearsToday) {
        [self setupTorrentsWithKeyword:keyword.name];
    };
}

- (void) setupTorrentsWithKeyword:(NSString *)keyword {
    NSString *urlString = [NSString stringWithFormat:DMHYSearchByKeyword,keyword];
    NSURL *url = [DMHYTool convertToURLWithURLString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"URL -> %@",url);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    }
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
        
        [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            if (idx < 4) {
                TorrentItem *item = [[TorrentItem alloc] init];
                NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
                item.pubDate = [self formatedDateStringFromDMHYDateString:dateString];
                item.title = [[element firstChildWithTag:@"title"] stringValue];
                item.link = [[element firstChildWithTag:@"link"] stringValue];
                item.author = [[element firstChildWithTag:@"author"] stringValue];
                NSString *magStr = [[element firstChildWithXPath:@"//enclosure/@url"] stringValue];
                item.magnet = magStr;
                
                [self.torrents addObject:item];
            }
        }];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        self.tableView.userInteractionEnabled = YES;
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        NSLog(@"Error %@",[error localizedDescription]);
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        self.tableView.userInteractionEnabled = YES;
        JGProgressHUD *faiedHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
        faiedHUD.textLabel.text = @"载入失败 >_<";
        faiedHUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
        [faiedHUD showInView:self.view];
        [faiedHUD dismissAfterDelay:3.0];
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}

#pragma mark - From Detail Subscribe Table View Controller

#pragma mark > Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.torrents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TorrentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TorrentCell" forIndexPath:indexPath];
    TorrentItem *torrent = self.torrents[indexPath.row];
    cell.torrentInfo.text = [NSString stringWithFormat:@"%@ %@", torrent.pubDate, torrent.title];
    [self addLongPressGestureToCell:cell];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.share = NO;
    [self queryDownloadURLWithIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Download

- (void)queryDownloadURLWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"queryDownloadURL");
    TorrentItem *item = self.torrents[indexPath.row];
    
    NSURL *url = [DMHYTool convertToURLWithURLString:item.link];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer HTMLResponseSerializer];
    }
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *doc ){
        
        dispatch_async(dispatch_queue_create("download queue", nil), ^{
            NSMutableArray *urlArr = [NSMutableArray new];
            for (ONOXMLElement *element in [doc XPath:kTest]) {
                [urlArr addObject:[element stringValue]];
            }
            
            NSString *downloadString = [urlArr firstObject];
            NSLog(@"DL: %@",downloadString);
            NSString *dlURLString = [NSString stringWithFormat:DMHYURLPrefixFormat,downloadString];
            NSLog(@"isShare %i",self.isShare);
            if (self.isShare) {
                NSArray *shareItems = @[[NSURL URLWithString:dlURLString]];
//                NSLog(@"shareItems %@",shareItems);
                dispatch_async(dispatch_get_main_queue(), ^{
                    TorrentTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    [self presentShareActivitiesWithItems:shareItems toSourceView:cell];
                });
            } else {
                [DMHYTool writeToPasteboardWithString:dlURLString];
                NSLog(@"Writed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    JGProgressHUD *copiedHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
                    copiedHUD.textLabel.text = @"已拷贝 DL 链接！";
                    copiedHUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                    [copiedHUD showInView:self.view];
                    [copiedHUD dismissAfterDelay:3.0];
                });
            }
        });
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        NSLog(@"Error %@",[error localizedDescription]);
        JGProgressHUD *faiedHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
        faiedHUD.textLabel.text = @"解析 DL 链接失败 >_<";
        faiedHUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
        [faiedHUD showInView:self.view];
        [faiedHUD dismissAfterDelay:3.0];
    }];
    
    [[NSOperationQueue mainQueue] addOperation:op];
}


#pragma mark - Utils

- (NSString *)formatedDateStringFromDMHYDateString:(NSString *)dateString {
    //    NSLog(@"dateFormater %@",self.dateFormater);
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate = [self.dateFormater dateFromString:dateString];
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:longDate];
    
}

#pragma mark - Initialazation

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

- (NSMutableArray *)torrents {
    if (!_torrents) {
        _torrents = [[NSMutableArray alloc] init];
    }
    return _torrents;
}

- (NSArray *)keywordsToday {
    if (!_keywordsToday) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
        request.predicate = [NSPredicate predicateWithFormat:@"name == %@",self.today];
        NSArray *categories = [self.managedObjectContext executeFetchRequest:request error:NULL];
        
        if (categories.count != 0) {
            DMHYCategory *category = [categories firstObject];
            _keywordsToday = [category.keywords copy];
        } else {
            _keywordsToday = [[NSArray alloc] init];
        }
    }
    return _keywordsToday;
}

- (NSArray *)keywordsYearsToday {
    if (!_keywordsYearsToday) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
        request.predicate = [NSPredicate predicateWithFormat:@"name == %@",self.yesterday];
        NSArray *categories = [self.managedObjectContext executeFetchRequest:request error:NULL];
        
        if (categories.count != 0) {
            DMHYCategory *category = [categories firstObject];
            _keywordsYearsToday = [category.keywords copy];
        } else {
            _keywordsYearsToday = [[NSArray alloc] init];
        }
    }
    return _keywordsYearsToday;
}

- (NSArray *)keywrodsRecently {
    if (!_keywrodsRecently) {
        _keywrodsRecently = [NSArray arrayWithObjects:self.keywordsToday, self.keywordsYearsToday, nil];
    }
    return _keywrodsRecently;
}

- (NSDateFormatter *)dateFormater {
    if (!_dateFormater) {
        _dateFormater = [[NSDateFormatter alloc] init];
    }
    return _dateFormater;
}

@end
