//
//  ContentView.swift
//  GetMACAddress
//
//  Created by Spyros Panagiotopoulos on 8/2/20.
//

import SwiftUI
import Network

struct ContentView: View {
    @State private var labelText: String = "MAC Addresses"
    @State private var macAddressLabel : String = ""
    @State private var addressesLabel: String = ""
    @State private var showAddressesToggle: Bool = false
    func GetMACAddress(){
        getIFAddresses()
        let address = getAddress()
        macAddressLabel = GetMACAddressFromIPv6(ip: address ?? "")
    }
    
    func GetMACAddressFromIPv6(ip: String) -> String{
        let IPStruct = IPv6Address(ip)
        if(IPStruct == nil){
            return ""
        }
        let extractedMAC = [
            (IPStruct?.rawValue[8])! ^ 0b00000010,
            IPStruct?.rawValue[9],
            IPStruct?.rawValue[10],
            IPStruct?.rawValue[13],
            IPStruct?.rawValue[14],
            IPStruct?.rawValue[15]
        ]
        return String(format: "%02x:%02x:%02x:%02x:%02x:%02x", extractedMAC[0] ?? 00,
            extractedMAC[1] ?? 00,
            extractedMAC[2] ?? 00,
            extractedMAC[3] ?? 00,
            extractedMAC[4] ?? 00,
            extractedMAC[5] ?? 00)
    }
    
    
    // this function was taken from and is slightly modified: 
    // https://stackoverflow.com/a/30754194/3508517
    
    func getAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET6) {
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name.contains("ipsec") {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    let ipv6addr = IPv6Address(address ?? "::")
                    if(ipv6addr?.isLinkLocal ?? false){
                        return address
                    }
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        addressesLabel = ""
     
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
     
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
     
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
     
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                        addressesLabel += address + "\n"
                    }
                }
            }
        }
     
        freeifaddrs(ifaddr)
        return addresses
    }
        
    var body: some View {
        VStack(alignment: .leading){
            Button(action: GetMACAddress) {
            Text("Get MAC Address")
            }
            Text(macAddressLabel)
            Toggle(isOn: $showAddressesToggle) {
            Text("Show addresses")
            }
            if showAddressesToggle{
                ScrollView {
                    Text(addressesLabel)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

