//
//  AppDelegate.swift
//  BikeLane
//
//  Created by Yung-Luen Lan on 9/21/15.
//  Copyright © 2015 yllan. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var playerView: AVPlayerView!

    
    var decayDate: NSDate? = nil
    var lastDate: NSDate? = nil
    
    var player: AVPlayer! = nil

    func openDocument(sender: AnyObject?) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mp4", "mov"]
        openPanel.beginSheetModalForWindow(self.window) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let item = AVPlayerItem.init(URL: openPanel.URL!)
                item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.init(rawValue: UInt(0)), context: nil)
                item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmVarispeed
                
                self.player = AVPlayer.init(playerItem: item)
                
                self.playerView.player = self.player
                self.player.play()
                self.player.rate = 0
            }
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        startServer()
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("tick:"), userInfo: nil, repeats: true)

    }
    
    func startServer() {
        let server = HttpServer()
        server["/"] = { request in
            self.cadence()
            return .OK(.JSON(["cadence": "ok"]))
        }
        server.start(9999, error: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let item: AVPlayerItem = object! as! AVPlayerItem
        item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmVarispeed
        if item.status == AVPlayerItemStatus.ReadyToPlay {
            for track in item.tracks {
                if track.assetTrack.mediaType == AVMediaTypeAudio {
                    track.enabled = false
                }
            }
        }
    }
    
    func tick(timer: NSTimer) {
        if let decay = self.decayDate {
            let now = NSDate()
            if now.earlierDate(decay) == decay {
                self.player.rate = Float(max(0, self.player.rate - 0.2))
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func rpm(duration: NSTimeInterval) -> Double {
        return 60.0 / duration;
    }
    
    func cadence() {
        let now = NSDate()

        if let last = lastDate {
            let duration = now.timeIntervalSinceDate(last)
            self.player.rate = Float(min(2.0, rpm(duration) / 70.0))
            self.decayDate = NSDate.init(timeIntervalSinceNow: duration)
        }
        lastDate = now
    }

}

