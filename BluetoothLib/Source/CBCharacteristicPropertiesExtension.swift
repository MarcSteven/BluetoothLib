//
//  CBCharacteristicPropertiesExtension.swift
//  BluetoothLib
//
//  Created by marc zhao on 2022/5/10.
//

import CoreBluetooth


public extension CBCharacteristicProperties {
    
    var name:[String] {
        var resultProperties = [String]()
        if contains(.broadcast) {
            resultProperties.append("Broadcast")
        }
        if contains(.read) {
            resultProperties.append("Read")
        }
        if contains(.write) {
            resultProperties.append("Write")
        }
        if contains(.writeWithoutResponse) {
            resultProperties.append("WriteWithouResponse")
        }
        if contains(.indicate) {
            resultProperties.append("Indicate")
        }
        if contains(.authenticatedSignedWrites) {
            resultProperties.append("AuthenticatedSignedWrites")
        }
        if contains(.extendedProperties) {
            resultProperties.append("ExtendedProperties")
        }
        return resultProperties
    }
}

