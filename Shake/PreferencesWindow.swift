//
//  PreferencesWindow.swift
//  Shake
//
//  Created by David Allie on 15/1/19.
//  Copyright © 2019 Dave Allie. All rights reserved.
//

import Cocoa
import Foundation

class PreferencesWindow: NSWindowController {
    
    @IBOutlet var versionLabel: NSTextField!
    @IBOutlet var adbPathField: NSTextField!
    @IBOutlet var adbDelaySlider: NSSlider!
    @IBOutlet var adbDelayLabel: NSTextField!
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        UserDefaults.standard.setValue(adbPathField.stringValue, forKey: "adbpath")
        UserDefaults.standard.setValue(adbDelaySlider.intValue, forKey: "adbdelay")
        self.window?.close()
    }
    
    @IBAction func abdDelaySliderChanged(_ sender: NSSlider) {
        adbDelayLabel.stringValue = "\(sender.intValue)"
    }
    
    override var windowNibName: String! {
        return "PreferencesWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        versionLabel.stringValue = getVersionString()
        window?.level = .floating
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        adbPathField.stringValue = UserDefaults.standard.string(forKey: "adbpath") ?? ""
        let delay = UserDefaults.standard.integer(forKey: "adbdelay")
        let adjustedDelay = delay >= 10 ? delay : 300
        adbDelaySlider.integerValue = adjustedDelay
        adbDelayLabel.stringValue = "\(adjustedDelay)"
    }
    
    private func getVersionString() -> String {
        if let infoDict = Bundle.main.infoDictionary {
            var versionString = infoDict["CFBundleName"] as? String ?? "Unknown"
            versionString += " v\(infoDict["CFBundleShortVersionString"] as? String ?? "unknown")"
            
            let buildNumber = infoDict["CFBundleVersion"] as? String
            if buildNumber != nil {
                versionString += " (Build \(buildNumber!))"
            }
            
            return versionString
        }
        
        return "Unknown";
    }
    
}

