//
//  AppDelegate.swift
//  Shake
//
//  Created by David Allie on 15/1/19.
//  Copyright © 2019 Dave Allie. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: PreferencesWindow!
    var devices: [String] = []
    let menu = NSMenu()
    let devicesMenuItem: NSMenuItem = NSMenuItem(title: "Devices", action: nil, keyEquivalent: "")
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("Image"))
        }
        
        Timer.scheduledTimer(timeInterval: 600.0, target: self, selector: #selector(AppDelegate.refreshDevices), userInfo: nil, repeats: true)

        constructMenu()
        preferencesWindow = PreferencesWindow()
        refreshDevices(nil)
    }
    
    func getAdbPath() -> String? {
        let path = UserDefaults.standard.string(forKey: "adbpath") ?? ""
        if path.count == 0 {
            return nil
        } else {
            return path
        }
    }
    
    func getCommandDelay() -> Int {
        let delay = UserDefaults.standard.integer(forKey: "adbdelay")
        return delay >= 10 ? delay : 300
    }

    func runAdbCommand(_ args: String...) -> (Int32, [String]) {
        let path = getAdbPath()
        if path == nil {
            return (1, [])
        }
        
        var fullCommand = args
        fullCommand.insert(path!, at: 0)
        
        let outpipe = Pipe()
        var output : [String] = []
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.standardOutput = outpipe
        task.arguments = fullCommand
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let exitCode = task.terminationStatus
        return (exitCode, output)
    }
    
    func adbShakeDevice(_ deviceId: String) {
        DispatchQueue.global().async(execute: {
            let _ = self.runAdbCommand("-s", deviceId, "shell", "input", "keyevent", "82")
        })
    }
    
    func adbReloadDevice(_ deviceId: String) {
        let commandDelay = getCommandDelay()
        
        DispatchQueue.global().async(execute: {
            let _ = self.runAdbCommand("-s", deviceId, "shell", "input", "keyevent", "82")
        })
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(commandDelay), execute: {
            let _ = self.runAdbCommand("-s", deviceId, "shell", "input", "keyevent", "19")
        })
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(commandDelay * 2), execute: {
            let _ = self.runAdbCommand("-s", deviceId, "shell", "input", "keyevent", "23")
        })
    }

    func listDevices() -> [String] {
        let output = runAdbCommand("devices")
        
        if output.0 != 0 {
            return []
        }
        
        let deviceLines = output.1.dropFirst()
        return deviceLines.map { $0.components(separatedBy: "\t")[0] }
    }
    
    func buildMenu() {
        let devicesMenu = NSMenu()
        
        if devices.count == 0 {
            devicesMenu.addItem(withTitle: "No Devices", action: nil, keyEquivalent: "")
        } else {
            for device in devices {
                let deviceSubMenu = NSMenu()
                let deviceShakeItem = NSMenuItem(title: "Shake", action: #selector(AppDelegate.shakeSpecificDevice(_:)), keyEquivalent: "")
                deviceShakeItem.representedObject = device
                let deviceReloadItem = NSMenuItem(title: "Reload", action: #selector(AppDelegate.reloadSpecificDevice(_:)), keyEquivalent: "")
                deviceReloadItem.representedObject = device
                deviceSubMenu.addItem(deviceShakeItem)
                deviceSubMenu.addItem(deviceReloadItem)
                
                let deviceItem = NSMenuItem(title: device, action: nil, keyEquivalent: "")
                devicesMenu.addItem(deviceItem)
                devicesMenu.setSubmenu(deviceSubMenu, for: deviceItem)
            }
        }
        
        menu.setSubmenu(devicesMenu, for: devicesMenuItem)
    }
    
    @IBAction func shakeAllDevices(_ sender: Any?) {
        for device in devices {
            adbShakeDevice(device)
        }
    }
    
    @IBAction func shakeSpecificDevice(_ sender: Any?) {
        let menuItem = sender as! NSMenuItem
        adbShakeDevice(menuItem.representedObject as! String)
    }
    
    @IBAction func reloadAllDevices(_ sender: Any?) {
        for device in devices {
            adbReloadDevice(device)
        }
    }
    
    @IBAction func reloadSpecificDevice(_ sender: Any?) {
        let menuItem = sender as! NSMenuItem
        adbReloadDevice(menuItem.representedObject as! String)
    }
    
    @IBAction func preferencesClicked(_ sender: Any?) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func refreshDevices(_ sender: Any?) {
        devices = listDevices()
        buildMenu()
    }
    
    func constructMenu() {
        menu.addItem(withTitle: "Shake All Devices", action: #selector(AppDelegate.shakeAllDevices(_:)), keyEquivalent: "s")
        menu.addItem(withTitle: "Reload All Devices", action: #selector(AppDelegate.reloadAllDevices(_:)), keyEquivalent: "r")
        menu.addItem(devicesMenuItem)
        menu.setSubmenu(nil, for: devicesMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Refresh Device List", action: #selector(AppDelegate.refreshDevices(_:)), keyEquivalent: "R")
        menu.addItem(withTitle: "Preferences", action: #selector(AppDelegate.preferencesClicked(_:)), keyEquivalent: "p")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        statusItem.menu = menu
    }

}

