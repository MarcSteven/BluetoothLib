//
//  GlobalFunction.swift
//  BluetoothLib
//
//  Created by marc zhao on 2022/5/13.
//

import Foundation


public func print(_ object:Any...) {
    #if DEBUG
    for item in object {
        Swift.print(item)
    }
    #endif
}

public func print(_ object:Any) {
    #if DEBUG
        Swift.print(object)
 
    
    #endif
}


public func saveLogIntoFile(_ logStr:String) {

        let  paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
       let documentsDirectory = paths[0]
       let formatter = DateFormatter()
       formatter.dateFormat = "dd-MM-yyyy"
       let dateString = formatter.string(from: Date())
       let fileName = "\(dateString).log"
       let logFilePath = (documentsDirectory as NSString).appendingPathComponent(fileName)
       var dump = ""

       if FileManager.default.fileExists(atPath: logFilePath) {
           dump =  try! String(contentsOfFile: logFilePath, encoding: String.Encoding.utf8)
       }

       do {
           // Write to the file
           try  "\(dump)\n\(Date()):\(logStr)".write(toFile: logFilePath, atomically: true, encoding: String.Encoding.utf8)
           #if DEBUG
           print("\(logStr))  is writing  to \(logFilePath)")
           
           #endif

       } catch let error as NSError {


           print("Failed writing to log file: \(logFilePath), Error: " + error.localizedDescription)
       }
     }
