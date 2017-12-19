//
// GADMAdapterNend.h
//
// Copyright © 2017年 F@N Communications, Inc. All rights reserved.
//

@import GoogleMobileAds;

@interface GADMAdapterNend : NSObject <GADMAdNetworkAdapter>

@end

typedef NS_ENUM(NSInteger, GADMNendInterstitialType) {
    GADMNendInterstitialTypeNormal = 1,
    GADMNendInterstitialTypeVideo = 2,
};

@interface GADMAdapterNendExtras : NSObject <GADAdNetworkExtras>

@property (nonatomic) GADMNendInterstitialType interstitialType;
@property (nonatomic, copy) NSString *userId;

@end
