//
//  BluetoothManager.swift
//  BluetoothLib
//
//  Created by marc zhao on 2022/5/10.
//

import Foundation
import CoreBluetooth


/** 蓝牙管理者*/


@objcMembers public  class BluetoothManager : NSObject, CBPeripheralDelegate,CBCentralManagerDelegate {
    
    var _manager : CBCentralManager?
    var delegate : BluetoothDelegate?
    private(set) var connected = false
    var state: CBManagerState? {
        guard _manager != nil else {
            return nil
        }
        return CBManagerState(rawValue: (_manager?.state.rawValue)!)
        
    }
    private(set) open var isScanning = false
    private(set) open var connectedDevice:BluetoothDevice?
    private(set) open var foundDevices:[BluetoothDevice]!
    private lazy var dispatchQueue:DispatchQueue = DispatchQueue(label: BluetoothConstants.dispatchQueueLabel,attributes: [])
    public var isBluetoothOn:Bool? {
        guard _manager != nil else {
            return nil
        }
        return _manager?.state == .poweredOn
        
    }
    public var isConnected:Bool? {
        guard _manager != nil else {
            return false
        }
        return _manager != nil
    }
    public var isBluetoothStateUpdateImminent: Bool {
        
        guard _manager != nil else {
            return false
        }
        return _manager?.state == .unknown || _manager?.state == .resetting
        
       }
    public var isBluetoothOff:Bool? {
        guard _manager != nil else {
            return nil
        }
        return _manager?.state == .poweredOff
    }
    public var isAvailableBluetooth:Bool? {
        guard _manager != nil else {
            return nil
        }
        return _manager?.state == .unsupported
    }
   public var isBluetoothPermissionGranted: Bool {
        if #available(iOS 13.1, *) {
            return CBCentralManager.authorization == .allowedAlways
        } else if #available(iOS 13.0, *) {
            return CBCentralManager().authorization == .allowedAlways
        }
        
        // Before iOS 13, Bluetooth permissions are not required
        return true
    }
    private var timeoutMonitor : Timer? /// Timeout monitor of connect to peripheral
    private var interrogateMonitor : Timer? /// Timeout monitor of interrogate the peripheral
    private let notifCenter = NotificationCenter.default
    private var isConnecting = false
    var logs = [String]()
    private(set) var connectedPeripheral : CBPeripheral?
    private(set) var connectedServices : [CBService]?
    private(set) var connectiongPeripheral:CBPeripheral?
    private(set) var isDisconnection:Bool = false
    private(set) var shouldAutoconnection:Bool = true
    
    
    
    public static let shared = BluetoothManager()
    
    private override init() {
        super.init()
        initCBCentralManager()
        
    }
    public init(background:Bool = false ) {
        super.init()
        let options :[String:String]? = background ? [CBCentralManagerOptionRestoreIdentifierKey:BluetoothConstants.restoreIdentifier] : nil
        foundDevices = []
        _manager = CBCentralManager(delegate: self, queue: dispatchQueue,options: options)
    }
    convenience init(centralManager:CBCentralManager) {
        self.init(background: false)
        centralManager.delegate = self
        _manager = centralManager
    }
    fileprivate var storedConnectedUUID:String? {
        return UserDefaults.standard.object(forKey: BluetoothConstants.UUIDStoreKey) as? String
    }
    
    
    // MARK: Custom functions
    /**
    Initialize CBCentralManager instance
    */
    func initCBCentralManager() {
        var dic : [String : Any] = Dictionary()
        dic[CBCentralManagerOptionShowPowerAlertKey] = false
        _manager = CBCentralManager(delegate: self, queue: nil, options: dic)
        
    }
    

    
    /**
     The method provides for starting scan near by peripheral
     */
    public func startScanPeripheral(advertisingWithServices services:[String]? = nil) {
       if isScanning == true {
           return
       }
       isScanning = true
       foundDevices.removeAll()
       
        _manager?.scanForPeripherals(withServices: services?.cbUuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    /**
     The method provides for stopping scan near by peripheral
     */
     public func stopScanPeripheral() {
         isScanning = false 
        _manager?.stopScan()
    }
    public func reconnectPeripheral(_ identifiers:[UUID],
                             services:[CBUUID]) {
        if let peripherals  = _manager?.retrievePeripherals(withIdentifiers: identifiers) {
            for peripheral in peripherals {
                self.connectedPeripheral = peripheral
                self._manager?.connect(peripheral, options: nil)
            }
           
        }
        if let peripherals = _manager?.retrieveConnectedPeripherals(withServices: services) {
        for peripheral in peripherals {
            self.connectedPeripheral = peripheral
            self._manager?.connect(peripheral, options: nil)
        }

    }
    }
    /**
     The method provides for connecting the special peripheral
     
     - parameter peripher: The peripheral you want to connect
     */
   public func connectPeripheral(_ peripheral: CBPeripheral) {
        if !isConnecting {
            isConnecting = true
            
            /** store the device*/
            _manager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
            timeoutMonitor = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.connectTimeout(_:)), userInfo: peripheral, repeats: false)
        }
    }
    private func store(connectedUDID udid:String?) {
        let userDefault = UserDefaults.standard
        userDefault.object(forKey: BluetoothConstants.UUIDStoreKey)
    
        userDefault.synchronize()
        
        
        
    }
    
    @objc public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
        print("willRestoreState: \(String(describing: dict[CBCentralManagerRestoredStatePeripheralsKey]))")
        #if DEBUG
        saveLogIntoFile("willRestoreState: \(String(describing: dict[CBCentralManagerRestoredStatePeripheralsKey]))")
        
        #endif
        
    }
    
    /**
     The method provides for disconnecting with the peripheral which has connected
     */
    public func disconnectPeripheral() {
        store(connectedUDID: nil)
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        if peripheral.state != .connected {
            connectedDevice = nil
        } else {
            isDisconnection = true
        }
        
            _manager?.cancelPeripheralConnection(peripheral)
       
    }
    
    /**
     The method provides for the user who want to obtain the descriptor
     
     - parameter characteristic: The character which user want to obtain descriptor
     */
    public func discoverDescriptor(_ characteristic: CBCharacteristic) {
        
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        
        
        if connectedPeripheral != nil  {
            print("Characteristic:\(characteristic)")
            #if DEBUG
            saveLogIntoFile("Characteristic: \(characteristic)")
            #endif
            connectedPeripheral?.discoverDescriptors(for: characteristic)
            
        }
    }
    
    /**
     The method is invoked when connect peripheral is timeout
     
     - parameter timer: The timer touch off this selector
     */
    @objc func connectTimeout(_ timer : Timer) {
        if isConnecting {
            isConnecting = false
            connectPeripheral(timer.userInfo as! CBPeripheral)
            timeoutMonitor = nil
        }
    }
    
    /**
     This method is invoked when interrogate peripheral is timeout
     
     - parameter timer: The timer touch off this selector
     */
    @objc func integrrogateTimeout(_ timer: Timer) {
        disconnectPeripheral()
        delegate?.didFailedToInterrogate?((timer.userInfo as! CBPeripheral))
    }
    
    /**
     This method provides for discovering the characteristics.
     */
    public func discoverCharacteristics() {
        if connectedPeripheral == nil {
            return
        }
        let services = connectedPeripheral!.services
        
        print("found the services:\(String(describing: services))")
        #if DEBUG
        saveLogIntoFile("Found the services:\(String(describing: services))")
        
        #endif
        if services == nil || services!.count < 1 { // Validate service array
            return
        }
        for service in services! {
            connectedPeripheral!.discoverCharacteristics(nil, for: service)
        }
    }
    public func readRssi() throws{
        Dispatch.dispatchPrecondition(condition: .onQueue(.main))
      
        if connectedPeripheral == nil {
            return
        }
        connectedPeripheral?.readRSSI()
        
    }
    
    

    
    
    /**
     Read characteristic value from the peripheral
     
     - parameter characteristic: The characteristic which user should
     */
   public  func readValueForCharacteristic(characteristic: CBCharacteristic) {
        if connectedPeripheral == nil {
            return
        }
        connectedPeripheral?.readValue(for: characteristic)
        print("read value for Characteristic :\(characteristic)")
       #if DEBUG
       
       saveLogIntoFile("read value for characteristic: \(characteristic)")
       #endif
    }
    
    /**
     Start or stop listening for the value update action
     
     - parameter enable:         If you want to start listening, the value is true, others is false
     - parameter characteristic: The characteristic which provides notifications
     */
    public func setNotification(enable: Bool, forCharacteristic characteristic: CBCharacteristic){
        if connectedDevice == nil {
            return
        }
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        if connectedPeripheral == nil {
            return
        }
       // guard let characteristic = characteritics(, serviceUDID: <#T##String#>)
      
        connectedPeripheral?.setNotifyValue(enable, for: characteristic)
        print("object is \(enable) for \(characteristic)")
        #if DEBUG
        saveLogIntoFile("Object is \(enable) for \(characteristic)")
        #endif
    }
    fileprivate func service( _ serviceUDID:String) ->CBService? {
        guard let services = connectedPeripheral?.services else {
            return nil
        }
        return services.filter{$0.uuid.uuidString == serviceUDID}.first
    }
    fileprivate func characteritics(_ characteristicUDID:String, serviceUDID:String) ->CBCharacteristic? {
        guard let service = service(serviceUDID) else {
            return nil
        }
        guard let characteristics = service.characteristics else {
            return nil
        }
        return characteristics.filter {$0.uuid.uuidString == characteristicUDID}.first
    }
    /**
     Write value to the peripheral which is connected
     
     - parameter data:           The data which will be written to peripheral
     - parameter characteristic: The characteristic information
     - parameter type:           The write of the operation
     */
    public func writeValue(data: Data, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
       
        if connectedPeripheral == nil {
            return
        }
        connectedPeripheral?.writeValue(data, for: characteristic, type: type)
    }
    
    // MARK: Delegate
    /**
    Invoked whenever the central manager's state has been updated.
     */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("State : Powered Off")
            #if DEBUG
            saveLogIntoFile("State:Powered off")
            #endif
        case .poweredOn:
            print("State : Powered On")
            #if DEBUG
            saveLogIntoFile("State: Powered on ")
            #endif
        case .resetting:
            #if DEBUG
            
            saveLogIntoFile("State: Resetting")
            #endif
            print("State : Resetting")
        case .unauthorized:
            #if DEBUG
            saveLogIntoFile("State: Unauthorized")
            #endif
            print("State : Unauthorized")
        case .unknown:
            #if DEBUG
            saveLogIntoFile("State: Unknown")
            #endif
            print("State : Unknown")
        case .unsupported:
            #if DEBUG
                saveLogIntoFile("State: Unsupported")
            #endif
            print("State : Unsupported")
        @unknown default:
            fatalError()
        }
        if let state = self.state {
            delegate?.didUpdateState?(state)
        }
    }
    
    /**
     This method is invoked while scanning, upon the discovery of peripheral by central
     
     - parameter central:           The central manager providing this update.
     - parameter peripheral:        The discovered peripheral.
     - parameter advertisementData: A dictionary containing any advertisement and scan response data.
     - parameter RSSI:              The current RSSI of peripheral, in dBm. A value of 127 is reserved and indicates the RSSI
     *                                was not available.
     */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
     
        print("Bluetooth Manager --> didDiscoverPeripheral, RSSI:\(RSSI) data:\(advertisementData)-- peripheral:\(peripheral)")
        
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didDiscoverPeripheral, RSSI:\(RSSI) data:\(advertisementData)-- peripheral:\(peripheral)")
        #endif
        delegate?.didDiscoverPeripheral?(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    /**
     This method is invoked when a connection succeeded
     
     - parameter central:    The central manager providing this information.
     - parameter peripheral: The peripheral that has connected.
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       
        
        print("Bluetooth Manager --> didConnectPeripheral")
        #if DEBUG
        
        saveLogIntoFile("Bluetooth Manager --> didConnectPeripheral")
        #endif
        isConnecting = false
        if timeoutMonitor != nil {
            timeoutMonitor!.invalidate()
            timeoutMonitor = nil
        }
        connected = true
        connectedPeripheral = peripheral
        delegate?.didConnectedPeripheral?(peripheral)
        stopScanPeripheral()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        interrogateMonitor = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.integrrogateTimeout(_:)), userInfo: peripheral, repeats: false)
    }
    
    /**
     This method is invoked where a connection failed.
     
     - parameter central:    The central manager providing this information.
     - parameter peripheral: The peripheral that you tried to connect.
     - parameter error:      The error infomation about connecting failed.
     */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Bluetooth Manager --> didFailToConnectPeripheral")
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didFailToConnectPeripheral")
        #endif
        isConnecting = false
        if timeoutMonitor != nil {
            timeoutMonitor!.invalidate()
            timeoutMonitor = nil
        }
        connected = false
        delegate?.failToConnectPeripheral?(peripheral, error: error!)
    }
    
    /**
     The method is invoked where services were discovered.
     
     - parameter peripheral: The peripheral with service informations.
     - parameter error:      Errot message when discovered services.
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Bluetooth Manager --> didDiscoverServices")
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didDiscoverServices")
        #endif
        connectedPeripheral = peripheral
        if error != nil {
            #if DEBUG
            saveLogIntoFile("Bluetooth Manager --> Discover Services Error, error:\(error?.localizedDescription ?? "")")
            #endif
            print("Bluetooth Manager --> Discover Services Error, error:\(error?.localizedDescription ?? "")")
            return 
        }
        
        // If discover services, then invalidate the timeout monitor
        if interrogateMonitor != nil {
            interrogateMonitor?.invalidate()
            interrogateMonitor = nil
        }
        
        self.delegate?.didDiscoverServices?(peripheral)
    }
    
    /**
     The method is invoked where characteristics were discovered.
     
     - parameter peripheral: The peripheral provide this information
     - parameter service:    The service included the characteristics.
     - parameter error:      If an error occurred, the cause of the failure.
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Bluetooth Manager --> didDiscoverCharacteristicsForService")
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didDiscoverCharacteristicsForService")
        
        #endif
        if error != nil {
            print("Bluetooth Manager --> Fail to discover characteristics! Error: \(error?.localizedDescription ?? "")")
            delegate?.didFailToDiscoverCharacteritics?(error!)
            return
        }
        delegate?.didDiscoverCharacteritics?(service)
    }
    
    /**
     This method is invoked when the peripheral has found the descriptor for the characteristic
     
     - parameter peripheral:     The peripheral providing this information
     - parameter characteristic: The characteristic which has the descriptor
     - parameter error:          The error message
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didDiscoverDescriptorsForCharacteristic")
        #endif
        print("Bluetooth Manager --> didDiscoverDescriptorsForCharacteristic")
        if error != nil {
            print("Bluetooth Manager --> Fail to discover descriptor for characteristic Error:\(error?.localizedDescription ?? "")")
            #if DEBUG
            
            saveLogIntoFile("Bluetooth Manager --> Fail to discover descriptor for characteristic Error:\(error?.localizedDescription ?? "")")
            #endif
            delegate?.didFailToDiscoverDescriptors?(error!)
            return
        }
        delegate?.didDiscoverDescriptors?(characteristic)
    }
    open func connect(with device:BluetoothDevice) {
        if connectedDevice != nil || isDisconnection {
            return
        }
        connectedDevice = device
        
        
    }
    fileprivate func connectToDevice() {
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        store(connectedUDID: peripheral.identifier.uuidString)
        guard peripheral.state == .disconnected else {
            return
        }
        _manager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey:NSNumber(value: true)])
        
    }
    /**
     This method is invoked when the peripheral has been disconnected.
     
     - parameter central:    The central manager providing this information
     - parameter peripheral: The disconnected peripheral
     - parameter error:      The error message
     */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Bluetooth Manager --> didDisconnectPeripheral")
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager -> didDisconnectPeripheral")
        #endif
        connected = false
        self.delegate?.didDisconnectPeripheral?(peripheral)
        notifCenter.post(name: NSNotification.Name(rawValue: PeripheralNotificationKeys.DisconnectNotif.rawValue), object: self)
    }
    
    /**
     Thie method is invoked when the user call the peripheral.readValueForCharacteristic
     
     - parameter peripheral:     The periphreal which call the method
     - parameter characteristic: The characteristic with the new value
     - parameter error:          The error message
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        #if DEBUG
        saveLogIntoFile("Bluetooth Manager --> didUpdateValueForCharacteristic")
        #endif
        print("Bluetooth Manager --> didUpdateValueForCharacteristic")
        if error != nil {
            print("Bluetooth Manager --> Failed to read value for the characteristic. Error:\(error!.localizedDescription)")
            #if DEBUG
            saveLogIntoFile("Bluetooth Manager --> Failed to read value for the characteristic. Error:\(error!.localizedDescription)")
            #endif
            delegate?.didFailToReadValueForCharacteristic?(error!)
            return
        }
        delegate?.didReadValueForCharacteristic?(characteristic)
        
    }
  
}


