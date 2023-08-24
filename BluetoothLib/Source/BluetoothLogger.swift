//
//  BluetoothLogger.swift
//  ARIUIKit
//
//  Created by marc zhao on 2022/4/13.
//

import Foundation

public protocol BluetoothLoggerProtocol {
    func logMessage(_ message: String)
}

public class BluetoothLogger {
    public static let shared = BluetoothLogger()
    public static let LOG_LEVEL_ALL   = 0xFF
    public static let LOG_LEVEL_ERROR = 0x01
    public static let LOG_LEVEL_TRACE = 0x02
    public static let LOG_LEVEL_HEX   = 0x04
    
    fileprivate var logger: BluetoothLoggerProtocol?
    fileprivate var queue = DispatchQueue(label: "BleLoggerQueue")
    fileprivate var logLevel = 0
    
    public static func setLogLevel(_ level: Int){
        shared.queue.sync(execute: {
            shared.logLevel = level
        })
    }
    
    public static func setLogger(_ logger: BluetoothLoggerProtocol?){
        shared.queue.sync(execute: {
            shared.logger = logger
        })
    }
    
    public static func trace(_ strings: String...){
        shared.queue.async(execute: {
            if( shared.logger != nil && (shared.logLevel & BluetoothLogger.LOG_LEVEL_TRACE) != 0 ){
                let fullLog = "[BLE] " + strings.joined(separator: " ")
                shared.logger?.logMessage(fullLog)
            }
        })
    }
    
    public static func error(_ strings: String...){
        shared.queue.async(execute: {
            if( shared.logger != nil && (shared.logLevel & BluetoothLogger.LOG_LEVEL_ERROR) != 0 ){
                let fullLog = "[BLE][ERROR] " + strings.joined(separator: " ")
                shared.logger?.logMessage(fullLog)
            }
        })
    }
    
    public static func trace_if_error(_ message: String, error: Error?){
        if error != nil {
            shared.queue.async(execute: {
                if( shared.logger != nil && (shared.logLevel & BluetoothLogger.LOG_LEVEL_ERROR) != 0 ){
                    shared.logger?.logMessage("[BLE][ERROR] " + message + " err: " + (error?.localizedDescription)!)
                }
            })
        }
    }

    public static func trace_hex(_ message: String, data: Data) {
        shared.queue.async(execute: {
            if( shared.logger != nil && (shared.logLevel & BluetoothLogger.LOG_LEVEL_HEX) != 0 ){
                let logStr = (message + " HEX " + data.compactMap { (byte) -> String in
                    return String(format: "%02X", byte)
                }.joined(separator: " "))
                shared.logger?.logMessage(logStr)
            }
        })
    }
    
    public static func trace_hex(_ message: String, data: [UInt8]) {
        shared.queue.async(execute: {
            if( shared.logger != nil && (shared.logLevel & BluetoothLogger.LOG_LEVEL_HEX) != 0 ){
                let logStr = (message + " HEX " + data.compactMap { (byte) -> String in
                   return String(format: "%02X", byte)
               }.joined(separator: " "))
               shared.logger?.logMessage(logStr)
            }
        })
    }
}



