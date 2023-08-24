//
//  PeripheralNotificationKeys.swift
//  BluetoothLib
//
//  Created by marc zhao on 2022/5/10.
//

import Foundation




public enum PeripheralNotificationKeys : String { // The notification name of peripheral
    case DisconnectNotif = "disconnectNotif" // Disconnect notification name
    case CharacteristicNotif = "characteristicNotif" // Characteristic discover notification name
}
