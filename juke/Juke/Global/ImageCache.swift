//
//  ImageDownloader.swift
//  Juke
//
//  Created by Conner Smith on 9/25/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import AlamofireImage

class ImageCache {
    
    private static let circleUserFilter = CircleFilter()
    private static let roundedCornersFilter = RoundedCornersFilter(radius: 10.0)
    private static let defaultPlaylistImage = RoundedCornersFilter(radius: 10.0).filter(UIImage(named: "juke_icon")!)
    private static let defaultUserIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    private static let downloader = ImageDownloader(
        configuration: ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: .fifo,
        maximumActiveDownloads: 4,
        imageCache: AutoPurgingImageCache()
    )
    
    public static func downloadUserImage(url: String?, callback: @escaping (UIImage?)->Void) {
        if let url = url {
            let urlRequest = URLRequest(url: URL(string: url)!)
            downloader.download(urlRequest, filter: circleUserFilter) { response in
                if let image = response.result.value {
                    callback(image)
                } else {
                    callback(self.defaultUserIcon)
                }
            }
        } else {
            callback(defaultUserIcon)
        }
    }
    
    public static func downloadPlaylistImage(url: String, callback: @escaping (UIImage?)->Void) {
        let urlRequest = URLRequest(url: URL(string: url)!)
        downloader.download(urlRequest, filter: roundedCornersFilter) { response in
            if let image = response.result.value {
                callback(image)
            } else {
                callback(defaultPlaylistImage)
            }
        }
    }
    
    
}
