//
//  GifMaker.swift
//  Wind
//
//  Created by Егор on 5/9/17.
//  Copyright © 2017 Yegor's Mac. All rights reserved.
//

import AppKit
import Foundation
import ImageIO

class GifMaker {
    private var images: [CGImage]!
    private var quality: Float
    private var scale: Float
    private var fps: Float
    private var path: NSURL
    private var processingQueue: DispatchQueue!
    private var dispatchGroup: DispatchGroup!
    private var destinationGIF: CGImageDestination!
    typealias SuccessBlock = (Bool) -> Void

    let fileProperties: CFDictionary
    var frameProperties: CFDictionary

    init(quality: Float, scale: Float, fps: Float, path: NSURL) {
        self.quality = quality / 100
        self.scale = scale / 100
        self.fps = fps
        self.path = path
        images = [CGImage]()
        processingQueue = DispatchQueue(label: "processingQ",
                                        qos: .background,
                                        attributes: .concurrent,
                                        autoreleaseFrequency: .workItem,
                                        target: processingQueue)
        dispatchGroup = DispatchGroup()
        frameProperties = [
            kCGImagePropertyGIFDictionary as String:
                [(kCGImagePropertyGIFDelayTime as String): 1 / self.fps],
        ] as CFDictionary
        fileProperties = [
            kCGImagePropertyGIFDictionary as String:
                [kCGImagePropertyGIFLoopCount as String: 0],
        ] as CFDictionary
    }

    func addImageIntoGif(image: CGImage) {
        processingQueue.sync {
            let resizedImage: CGImage = image.resizeImage(level: self.quality, scale: self.scale)
            self.images.append(resizedImage)
        }
    }

    func generateGif(success: @escaping SuccessBlock) {
        destinationGIF = CGImageDestinationCreateWithURL(path, kUTTypeGIF, images.count, nil)
        CGImageDestinationSetProperties(destinationGIF, fileProperties)
        processingQueue.async(group: dispatchGroup, qos: .background, flags: .enforceQoS, execute: {
            while self.images.count > 0 {
                CGImageDestinationAddImage(self.destinationGIF, self.images.popLast()!, self.frameProperties)
            }
        })
        dispatchGroup.notify(queue: processingQueue, execute: {
            success(CGImageDestinationFinalize(self.destinationGIF))
            self.destinationGIF = nil
            self.images = nil
        })
        GifProcessingOperation().main()
    }
}
