//
//  Extensions.swift
//  BluetoothLib
//
//  Created by Marc Steven on 2022/6/8.
//

import Foundation
import CoreBluetooth



extension Collection where Iterator.Element == String {
    var cbUuids:[CBUUID] {
        return self.map { CBUUID(string: $0) }
    }
}

extension Array where Element:BluetoothDevice {
    fileprivate func create(from peripheral: CBPeripheral) -> BluetoothDevice {
        return self.filter { $0.peripheral.identifier == peripheral.identifier }.first ?? BluetoothDevice(peripheral: peripheral)
    }

    fileprivate func has(peripheral: CBPeripheral) -> Bool {
        return (self.filter { $0.peripheral.identifier == peripheral.identifier }).count > 0
    }
}
