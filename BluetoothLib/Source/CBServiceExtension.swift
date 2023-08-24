//
//  CBServiceExtension.swift
//  BluetoothLib
//
//  Created by marc zhao on 2022/5/10.
//

import CoreBluetooth


public extension CBService {
    /// Obtain the name of the characteristic according to the UUID, if the UUID is the standard defined in the `Bluetooth Developer Portal` then return the name
     var name : String {
        guard let name = self.uuid.name else {
            return "UUID: " + self.uuid.uuidString
        }
        return name
    }
}
