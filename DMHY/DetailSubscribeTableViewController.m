//
//  DetailSubscribeTableViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/17.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "DetailSubscribeTableViewController.h"
#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "DMHYAPI.h"
#import "Ono.h"
#import "JGProgressHUD.h"

#import "TorrentItem.h"
#import "TorrentTableViewCell.h"

#import "DMHYTool.h"

@interface DetailSubscribeTableViewController ()

@property (nonatomic, strong) NSMutableArray *torrents;

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSDateFormatter *dateFormater;

@property (nonatomic, strong) NSURL *downloadURL;
@property (nonatomic, getter=isShare) BOOL share;

@end

@implementation DetailSubscribeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.torrents = nil;
}

- (void)setupData {
    self.navigationItem.title = @"加载中...";
    NSURLRequest *request = [NSURLRequest requestWithURL:self.pageURL];
    NSLog(@"URL -> %@",self.pageURL);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    }
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
        
        [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            
            TorrentItem *item = [[TorrentItem alloc] init];
            NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
            item.pubDate = [self formatedDateStringFromDMHYDateString:dateString];
            item.title = [[element firstChildWithTag:@"title"] stringValue];
            item.link = [[element firstChildWithTag:@"link"] stringValue];
            item.author = [[element firstChildWithTag:@"author"] stringValue];
            NSString *magStr = [[element firstChildWithXPath:@"//enclosure/@url"] stringValue];
            item.magnet = magStr;
            [self.torrents addObject:item];
            self.navigationItem.title = @"加载完毕";
        }];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        NSLog(@"Error %@",[error localizedDescription]);
        self.navigationItem.title = @"傲娇了";
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}

#pragma mark - Table view data source

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

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

- (NSString *)formatedDateStringFromDMHYDateString:(NSString *)dateString {
    //    NSLog(@"dateFormater %@",self.dateFormater);
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate = [self.dateFormater dateFromString:dateString];
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:longDate];
    
}

- (NSMutableArray *)torrents {
    if (!_torrents) {
        _torrents = [[NSMutableArray alloc] init];
    }
    return _torrents;
}

- (NSDateFormatter *)dateFormater {
    if (!_dateFormater) {
        _dateFormater = [[NSDateFormatter alloc] init];
    }
    return _dateFormater;
}

@end
