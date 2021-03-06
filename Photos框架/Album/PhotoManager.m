//
//  PhotoManager.m
//  Photos框架
//
//  Created by 曹旋 on 16/11/8.
//  Copyright © 2016年 CX. All rights reserved.
//

#import "PhotoManager.h"

@interface PhotoManager()<UIAlertViewDelegate>

@end

static PhotoManager *manager;
@implementation PhotoManager
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PhotoManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imageCount = 9;
    }
    return self;
}

- (void)getAlbumArray:(void(^)())success
{
    NSLog(@"获取相册");
    if (manager.albumInfoArray) {
        success();
        NSLog(@"获取相册成功");
        return;
    }
    NSMutableArray * albumInfoArray = [NSMutableArray array];
    NSMutableArray *albumArray = [NSMutableArray array];
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    //遍历自定义相册
    for (PHAssetCollection *assetCollection in assetCollections) {
        [albumArray addObject:assetCollection];
    }
    //相册胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    [albumArray addObject:cameraRoll];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    
    //获取原图
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (PHAssetCollection *assetCollection in albumArray) {
            AlbumInfo *albumInfo = [[AlbumInfo alloc] init];
            albumInfo.assetCollection = assetCollection;
            albumInfo.albumName = [assetCollection.localizedTitle isEqualToString:@"Camera Roll"]?@"相册胶卷" : assetCollection.localizedTitle;
            // 获得某个相簿中的所有PHAsset对象
            PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
            for (PHAsset *asset in assets) {
                CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
                
                // 从asset中获得图片
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    NSLog(@"%@ --%@", result,info);
                    [albumInfo.albumImages addObject:result];
                }];
            }
            [albumInfoArray addObject:albumInfo];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            manager.albumInfoArray = albumInfoArray;
            NSLog(@"获取相册成功");
            success();
        });
        
    });

}

- (void)pushPhotoVC:(UIViewController *)parentVC delegate:(id<AlbumCollectionViewControllerDelegate>)delegate
{
    //权限检测
    PHAuthorizationStatus photoAuthStatus = [PHPhotoLibrary authorizationStatus];
    if (photoAuthStatus == PHAuthorizationStatusNotDetermined) {
            //请求授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    NSLog(@"用户同意授权");
                    [self present:parentVC delegate:delegate];
                }else{
                    NSLog(@"用户拒绝授权");
                }
            }];
    }else if(photoAuthStatus == PHAuthorizationStatusRestricted || photoAuthStatus == PHAuthorizationStatusDenied) {
        NSLog(@"未授权");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"是否打开相册权限" delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [alertView show];
    }else{
        NSLog(@"已授权");
        [self present:parentVC delegate:delegate];
       
    }
}

- (void)present:(UIViewController *)parentVC delegate:(id<AlbumCollectionViewControllerDelegate>)delegate
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    AlbumCollectionViewController *vc = [[AlbumCollectionViewController alloc] initWithCollectionViewLayout:layout];
    vc.delegate = delegate;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [parentVC presentViewController:nav animated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

@end
