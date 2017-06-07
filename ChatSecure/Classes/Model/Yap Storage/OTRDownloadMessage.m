//
//  OTRDownloadMessage.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import YapDatabase;
@import OTRAssets;
#import "OTRLog.h"
#import "OTRImages.h"
#import "OTRDownloadMessage.h"
#import "UIActivity+ChatSecure.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTRDownloadMessage

- (instancetype) initWithParentMessage:(id<OTRMessageProtocol>)parentMessage
                                   url:(NSURL*)url {
    NSParameterAssert(parentMessage);
    if (self = [super init]) {
        _parentMessageKey = parentMessage.messageKey;
        _parentMessageCollection = parentMessage.messageCollection;
        _url = url;
        self.text = url.absoluteString;
        self.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:parentMessage.messageSecurity];
        self.date = parentMessage.messageDate;
        self.buddyUniqueId = parentMessage.threadId;
    }
    return self;
}

- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges {
    NSMutableArray *edges = [NSMutableArray arrayWithCapacity:3];
    NSArray *superEdges = [super yapDatabaseRelationshipEdges];
    if (superEdges) {
        [edges addObjectsFromArray:superEdges];
    }
    
    if (self.parentMessageKey) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
        YapDatabaseRelationshipEdge *parentEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                            destinationKey:self.parentMessageKey
                                                                                collection:self.parentMessageCollection
                                                                           nodeDeleteRules:YDB_NotifyIfSourceDeleted | YDB_NotifyIfDestinationDeleted];
        [edges addObject:parentEdge];
    }
    return edges;
}

@end

@implementation UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForDownloadMessage:(OTRDownloadMessage*)downloadMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController {
    NSParameterAssert(downloadMessage);
    NSParameterAssert(sourceView);
    NSParameterAssert(viewController);
    if (!downloadMessage || !sourceView || !viewController) { return @[]; }
    NSMutableArray<UIAlertAction*> *actions = [NSMutableArray new];
    
    NSURL *url = nil;
    // sometimes the scheme is aesgcm, which can't be shared normally
    if ([downloadMessage.url.scheme isEqualToString:@"https"]) {
        url = downloadMessage.url;
    }
    
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:SHARE_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSMutableArray *activityItems = [NSMutableArray new];
        if (url) {
            [activityItems addObject:url];
        }
        // This is sorta janky, but only support fetching images for now
        if (downloadMessage.mediaItemUniqueId.length) {
            UIImage *image = [OTRImages imageWithIdentifier:downloadMessage.mediaItemUniqueId];
            if (image) {
                [activityItems addObject:image];
            }
        }
        NSArray<UIActivity*> *activities = UIActivity.otr_linkActivities;
        UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
        
        share.popoverPresentationController.sourceView = sourceView;
        share.popoverPresentationController.sourceRect = sourceView.bounds;
        [viewController presentViewController:share animated:YES completion:nil];
    }];
    [actions addObject:shareAction];
    
    if (url) {
        UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:COPY_LINK_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard.generalPasteboard.persistent = YES;
            UIPasteboard.generalPasteboard.URL = url;
        }];
        UIAlertAction *openInSafari = [UIAlertAction actionWithTitle:OPEN_IN_SAFARI() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIApplication.sharedApplication openURL:url];
        }];
        [actions addObject:copyLinkAction];
        [actions addObject:openInSafari];
    }
    
    return actions;
}

@end