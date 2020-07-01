//
//  QuickNet.swift
//  QuickNet
//
//  Created by Allen Ellis on 5/8/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UInt128

// comment so that Colab does not interpret `#if ...` as a comment
//#if canImport(PythonKit)
//    import PythonKit
//#else
//    import Python
//#endif

    // MARK: Class: ip_view

class ip_view {
    
    var ip_input: String
    var ip_addr_str: String
    var network_size: Int
    
    var ipv_type: String
    
    var host_network: String
    var host_first_host: String
    var host_last_host: String
    var host_broadcast: String
    var host_usable_hosts: Int
    var host_condensed: String
    var host_integer: String    // It's not an int because it could be a 128-bit integer. Maybe convert to 128 bit int at some point but I don't know that I need to
    
    var cidr_notation: String
    var netmask: String
    var wildcard_mask: String
    var netbox_status: String
    var netbox_link: String
    
    var next_network: String
    var prev_network: String
    
    var subnet_data: [[String: String]] = [[:]]
    
    public init(ip_input: String)
    {
        self.ip_input = ip_input
        self.ip_addr_str = "0.0.0.0"
        self.network_size = 0
        
        self.host_network = "0.0.0.0"
        self.host_first_host = "0.0.0.0"
        self.host_last_host = "0.0.0.0"
        self.host_broadcast = "0.0.0.0"
        self.host_usable_hosts = 0
        self.host_condensed = "0.0.0.0"
        self.ipv_type = "0"
        self.subnet_data = []
        self.host_integer = "0"
        
        self.cidr_notation = "/0"
        self.netmask = "0.0.0.0"
        self.wildcard_mask = "0.0.0.0"
        self.netbox_status = "Unknown"
        self.netbox_link = ""
        
        self.next_network = "0.0.0.0"
        self.prev_network = "0.0.0.0"
        
        self.calculate()
        
        
    }
    
    func calculate() {
        
        self.ipv_type = self.detect_ipv_type()
        
        if(self.ipv_type == "0")
        {
            // return "nil" // todo - error handling how exactly?
        }
        if(self.ipv_type == "4")
        {
            // old: variables based on the old clas
//            let ip4_obj = ip4_old(ip_input: self.ip_input)
//            self.host_network = ip4_obj.host_network
//            self.host_first_host = ip4_obj.host_first_host
//            self.host_last_host = ip4_obj.host_last_host
//            self.host_broadcast = ip4_obj.host_broadcast
//            self.host_usable_hosts = ip4_obj.host_usable_hosts
//            self.host_condensed = ip4_obj.host_condensed
            
            // variables based on my new class
            
            // separate the mask from the address
            let ip_components = ip_input.components(separatedBy: "/")
            self.ip_addr_str = ip_components[0]
        
            // If they supplied a network size, use it. If not, default to 32.
            if(ip_components.count == 2)
            {
                self.network_size = Int(ip_components[1]) ?? 32
            }
            else
            {
                self.network_size = 32
            }
            
            let ip4 = SubnetCalculator4(ip_address: self.ip_addr_str, network_size: network_size)
            
            self.host_network = ip4.getNetworkPortion()
            self.host_first_host = ip4.getMinHost()
            self.host_last_host = ip4.getMaxHost()
            self.host_broadcast = ip4.getBroadcastAddress()
            self.host_usable_hosts = ip4.getNumberAddressableHosts()
            
            self.cidr_notation = "/" + String(ip4.getNetworkSize())
            self.netmask = ip4.getSubnetMask()
            self.wildcard_mask = ip4.getSubnetMask()
//            self.netbox_status = getNetboxStatus()
//            self.netbox_status = getHostHeaderFromHttpBin()
            self.netbox_status = "hello world"
            self.next_network = ip4.getNextNetwork()
            self.prev_network = ip4.getPrevNetwork()
            self.host_integer = String(ip4.getIPAddressInteger())
            
            self.getNetboxStatus()
            self.subnet_data = populate_table4()
            
        }
        
        if(self.ipv_type == "6")
        {
            
            // separate the mask from the address
            let ip_components = ip_input.components(separatedBy: "/")
            self.ip_addr_str = ip_components[0]
        
            // If they supplied a network size, use it. If not, default to 128.
            if(ip_components.count == 2)
            {
                self.network_size = Int(ip_components[1]) ?? 128
            }
            else
            {
                self.network_size = 128
            }
            
            let ip6 = IP6(ip_address_mixed: self.ip_addr_str, network_size: self.network_size)
            
            self.host_first_host = ip6.first_host
            self.host_last_host = ip6.last_host
            self.host_condensed = ip6.ip_short_string
            self.host_integer = ip6.ip_long_string
            
            self.cidr_notation = "/" + String(ip6.network_size)
            
//            let ip6 = SubnetCalc6(ip_address: self.ip_addr_str, network_size: network_size)
//            self.host_first_host = "tbd"
//            self.host_last_host = ip6.getIPAddressStringShort()
//            self.host_condensed = ip6.getIPAddressStringLong()
//            self.host_integer = String(ip6.getIPAddressInt())
//
//            self.cidr_notation = "/" + String(ip6.getNetworkSize())
            self.subnet_data = populate_table6()
        }

    }
    
    func detect_ipv_type() -> String {
        NSLog("Checking the format of "+self.ip_input)
        
        let ipv4test = self.ip_input.range(of: #"^(?:\d{1,3}\.){3}\d{1,3}(/\d{1,2}$)?(/(?:\d{1,3}\.){3}\d{1,3}$)?$"#,
                         options: .regularExpression) != nil // true

        if(ipv4test) {
            NSLog("Result: VALID IPv4")
            return "4"
        }

        let ipv6test = self.ip_input.range(of: #"^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(/\d{1,3})?$"#,
                         options: .regularExpression) != nil // true
        if(ipv6test) {
            NSLog("Result: VALID IPv6")
            return "6"
        }
        
        NSLog("Result: Was not valid")
        return "0"
  
    }
    
    func populate_table4() -> [[String: String]]  {
        
        
        var data = [[String: String]]()
        
        var i = 32
        
        while (i >= 0) {
            
            let i_ip_obj = SubnetCalculator4(ip_address: self.ip_addr_str, network_size: i)
            
            
            let diff = i - self.network_size
            let count = Int(pow(Double(2),Double(diff)))
            
            var example = ""
            
            switch (i) {
                
            case 24:
                example = "LAN"
            case 30:
                example = "Peer to Peer link"
            case 32:
                example = "Host"
                
            default:
                example = ""
            }
            
            data.append( [
                "subnet" : i_ip_obj.getNetworkPortion(),
                "prefix" : "/\(i)",
                "count" : String(count),
                "example" : example
            ])
            i -= 1
        }
        

            
        return(data)
        
    }
    
    
    func populate_table6() -> [[String: String]] {

      
              var data = [[String: String]]()
              
              var i = 128
              
              while (i >= 0) {
                  
                let i_ip_obj = IP6(ip_address_mixed: self.ip_addr_str, network_size: i)
                  
                  
                  let diff = i - self.network_size
                let count = floor(pow(Double(2),Double(diff)))
                let formatter = NumberFormatter()

                if(count > 100000000) {

                    formatter.usesSignificantDigits = true
                    formatter.maximumSignificantDigits = 1
                    formatter.numberStyle = .spellOut
                }
                else
                {
                    formatter.numberStyle = .decimal
                    formatter.usesSignificantDigits = false
                    
                }
                
                formatter.maximumFractionDigits = 0
                formatter.locale = Locale.current
                let displayValue: String = formatter.string(from: NSNumber(value: count))!
                  
                  var example = ""
                  
                  switch (i) {
                  case 12:
                      example = "RIR"
                  case 24: 
                      example = "Large ISP"
                  case 32:
                      example = "Cloud Provider"
                  case 36:
                      example = "Small ISP"
                  case 48:
                      example = "Large Business (Site)"
                  case 52:
                      example = ""
                  case 56:
                      example = "Small Business"
                    case 60:
                        example = "Residential"
                  case 64:
                      example = "LAN"
                  case 127:
                      example = "Peer to peer link"
                  case 128:
                      example = "Host"
                  default:
                      example = ""
                }
                  
                  data.append( [
                      "subnet" : i_ip_obj.first_host,
                      "prefix" : "/\(i)",
                      "count" : displayValue,
                      "example" : example
                  ])
                  i -= 4
              }
 
              return(data)
    }
    
        
    /**
     Queries the user's Netbox API to see if this prefix exists
     */
    
    public func getNetboxStatus() {
        
        let netbox_uri = "https://netbox.allenell.is"
        let netbox_query = "/api/ipam/prefixes/?q=\(self.ip_addr_str)/\(self.network_size)"
        let netbox_token = "5af68f02619c52ba4d172d993b822cb289e5983f"
        let loginString = "Token " + netbox_token
        
        let headers: HTTPHeaders = [
            "Authorization": loginString
        ]

        AF.request(netbox_uri + netbox_query, headers: headers).responseJSON { response in
            debugPrint(response)
            
            switch response.result {
            case .success:
                print("Validation Successful)")

                if let json = response.data {
                    do{
                        let data = try JSON(data: json)
                        
                        var description = ""
                        for (index, element) in data["results"] {
                            let this_description = element["description"]
//                            var description = "\(description) / \(this_description)"
                            if(Int(index) ?? 0 > 0 ) {
                                description.append(" / ")
                            }
                            description.append("\(this_description)")
                            let id = data["results"][0]["id"]
                            let urlid = "\(netbox_uri)/ipam/prefixes/\(id)"
                            let returnval = "\(description) \(urlid)"
                            print("DATA PARSED: \(returnval)")
                            self.netbox_link = urlid // todo - this doesn't do anything
                        }
                        
                        self.netbox_status = "\(description)"

                    }
                    catch{
                    print("JSON Error")
                    }

                }
                
            case .failure(let error):
                print(error)
            }


        }
        

        
//        let json = try? JSONSerialization.responseJSON(with: data, options: [])

        
        
//        var request = URLRequest(url: url!)
//        request.httpMethod = "GET"
//        request.setValue("Token \(netbox_token)", forHTTPHeaderField: "Authorization")

        
        // create the request
//        var request = URLRequest(url: url!)
//        request.httpMethod = "GET"
//        request.setValue("Token \(netbox_token)", forHTTPHeaderField: "Authorization")
//
//        //making the request
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("\(String(describing: error))")
//                return
//            }
//
//            if let httpStatus = response as? HTTPURLResponse {
//                // check status code returned by the http server
//                print("status code = \(httpStatus.statusCode)")
//        // process result
//            }
//
//            print(data)
//        }
//
//        task.resume()
//
////        let urlConnection = NSURLConnection(request: request, delegate: self)
//
//
//        do {
//            if let url = url {
//                let ipAddress = try String(contentsOf: url)
//                print("My public IP address is: " + ipAddress)
//            }
//        } catch let error {
//            print(error)
//        }
        

        
    }
}



// MARK: Class: SubnetCalculator4


class SubnetCalculator4
{
    
    /** IP address as dotted quads: xxx.xxx.xxx.xxx */
    var ip_address: String
    
    /** CIDR network size */
    var network_size: Int
    
    /** Array of four elements containing the four quads of the IP address */
    var quads = [Int]()
    
    /** Subnet mask in format used for subnet calculations */
    var subnet_mask: Int
    
    /** Subnet report in blob format */
    var report: String
    
    let FORMAT_QUADS  = "%d";
    let FORMAT_HEX    = "%02X";
    let FORMAT_BINARY = "%08b";
    
    
    /**
     Constructor -- Takes IP address and network size, validates inputs, and assigns class attributes.
     
     For example: 192.168.1.120/24 would be `ip` = `192.168.1.120` and `network_size` = `24`
     
     - Parameters:
       - ip_address: IP address in dotted quad notation
       - network_size: CIDR network size
       - report: Subnet report in blob format
     */
    
    public init(ip_address: String, network_size: Int, report: String = "") {
        
        
        self.ip_address = ip_address
        self.network_size = network_size
        self.quads = ip_address.components(separatedBy: ".").map { Int($0)!}
        self.report = "todo"
        self.subnet_mask = 0
        
        self.validateInputs(ip_address: ip_address, network_size: network_size)
        self.subnet_mask = self.calculateSubnetMask(network_size: network_size)

//        self.report = report ?: SubnetReport()
    }
    
    
    // MARK: Public functions
    
    /**
     Get IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getIPAddress() -> String
    {
        return self.ip_address
    }
    
    /**
     Get IP address as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getIPAddressQuads() -> [Int]
    {
        return self.quads
    }
    
    /**
     Get IP address as hexadecimal
     */
    public func getIPAddressHex() -> String
    {
        return self.ipAddressCalculation(format: self.FORMAT_HEX)
    }

    /**
     Get IP address as binary
     */
    public func getIPAddressBinary() -> String
    {
        return self.ipAddressCalculation(format: self.FORMAT_BINARY)
    }
    
    public func getIPAddressInteger() -> Int
    {
        let ipString = self.getIPAddress()
        return ip2long(ip_address: ipString)
    }
    
    /**
     Get network size
     */
    public func getNetworkSize() -> Int
    {
        return self.network_size
    }
    
    /**
     Get the number of IP addresses in the network
     */
    public func getNumberIPAddresses() -> Int
    {
        return intPow(base: 2, exp: (32 - self.network_size))
    }
    
    
    /**
     Get the number of addressable hosts in the network
     */
    
    public func getNumberAddressableHosts() -> Int
    {
        if(self.network_size == 32) {
            return 1
        }
        if(self.network_size == 31) {
            return 2
        }
        
        return (self.getNumberIPAddresses() - 2)
    }
    
    
    /**
     Get range of IP addresses in the network
     - Returns: Array containing start and end of IP address range. IP addresses are in dotted quad notation.
     */
    public func getIPAddressRange() -> [String]
    {
        return [self.getMinHost(),self.getMaxHost()]
    }
    
    
    /**
     Calculate network portion for formatting
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    
    private func networkCalculation(format: String, separator: String = "") -> String
    {
        let network_quads = [
            String(format: format, self.quads[0] & (self.subnet_mask >> 24)),
            String(format: format, self.quads[1] & (self.subnet_mask >> 16)),
            String(format: format, self.quads[2] & (self.subnet_mask >> 8)),
            String(format: format, self.quads[3] & (self.subnet_mask >> 0)),
        ];
        return network_quads.joined(separator: separator)
    }
    
    
    
    
    /**
     Calculate the broadcast IP address
     
     - Returns: IP address as dotted quads
     */
    
    public func getBroadcastAddress() -> String
    {
        let network_quads       = self.getNetworkPortionQuads()
        let number_ip_addresses = self.getNumberIPAddresses()
        
        let network_range_quads = [
            String(format: self.FORMAT_QUADS, (network_quads[0] & (self.subnet_mask >> 24))+(((number_ip_addresses - 1) >> 24) & 0xFF)),
            String(format: self.FORMAT_QUADS, (network_quads[1] & (self.subnet_mask >> 16))+(((number_ip_addresses - 1) >> 16) & 0xFF)),
            String(format: self.FORMAT_QUADS, (network_quads[2] & (self.subnet_mask >> 8))+(((number_ip_addresses - 1) >> 8) & 0xFF)),
            String(format: self.FORMAT_QUADS, (network_quads[3] & (self.subnet_mask >> 0))+(((number_ip_addresses - 1) >> 0) & 0xFF)),
        ];
        return network_range_quads.joined(separator: ".")
    }
    
    
    /**
     Calculate the network address for the next network
        The exact same code as calculating broadcast address, except I'm no longer subtracting one from each quad
          - Returns: IP address as dotted quads
     */
    public func nextNetworkCalculation(format: String, separator: String = "") -> String
    {
//        let network_quads       = self.getNetworkPortionQuads()
//        let number_ip_addresses = self.getNumberIPAddresses()
//
//        let network_range_quads = [
//            String(format: self.FORMAT_QUADS, (network_quads[0] & (self.subnet_mask >> 24))+(((number_ip_addresses) >> 24) & 0xFF)),
//            String(format: self.FORMAT_QUADS, (network_quads[1] & (self.subnet_mask >> 16))+(((number_ip_addresses) >> 16) & 0xFF)),
//            String(format: self.FORMAT_QUADS, (network_quads[2] & (self.subnet_mask >> 8))+(((number_ip_addresses) >> 8) & 0xFF)),
//            String(format: self.FORMAT_QUADS, (network_quads[3] & (self.subnet_mask >> 0))+(((number_ip_addresses) >> 0) & 0xFF)),
//        ];
//        return network_range_quads.joined(separator: ".")
        let broadcast_addr = self.getBroadcastAddress()
        let broadcast_addr_int = ip2long(ip_address: broadcast_addr)
        var next_network_int = broadcast_addr_int + 1
        
        if(next_network_int > 4294967295){
            next_network_int = 4294967295 // the highest possible IPv4 address
        }
        
        let next_network_string = long2ip(long: next_network_int)
        return next_network_string
    }
    
     
    /**
        Calculate the previous network address
     
     The exact same code as calculating network address, except I'm subtracting the number of host addresses too
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    
    private func prevNetworkCalculation(format: String, separator: String = "") -> String
    {
        
        let network_addr = self.getNetworkPortion()
        let network_addr_int = ip2long(ip_address: network_addr)
        var prev_network_int = network_addr_int - self.getNumberIPAddresses()
        
        if(prev_network_int < 0) {
            prev_network_int = 0
        }
        
        let prev_network_string = long2ip(long: prev_network_int)
        return prev_network_string
        
    }

    
    
    /**
     Get minimum host IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getMinHost() -> String {
        if(self.network_size == 32 || self.network_size == 31) {
            return self.ip_address
        }
        return self.minHostCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Get minimum host IP address as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getMinHostQuads() -> [Int]
    {
        if(self.network_size == 32 || self.network_size == 31) {
            return self.quads
        }
        let minHost = self.minHostCalculation(format: "%d", separator: ".")
        return minHost.components(separatedBy: ".").map { Int($0)!}
    }
    
    /**
     Get minimum host IP address as hex
     - Warning: Not yet complete
     */
    public func getMinHostHex() -> String
    {
        if(self.network_size == 32 || self.network_size == 31) {
            return "0" // todo wtf
        }
        return self.minHostCalculation(format: self.FORMAT_HEX)
    }
    
    /**
     Get minimum host IP address as binary
     - Warning: Not yet complete
     */
    public func getMinHostBinary() -> String {
        return "0" // todo
    }
    
    
    /**
     Get maximum host IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getMaxHost() -> String
    {
        if (self.network_size == 32 || self.network_size == 31) {
            return self.ip_address
        }
        return self.maxHostCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Get maximum host IP address as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getMaxHostQuads() -> [Int]
    {
        if (self.network_size == 32 || self.network_size == 31) {
            return self.quads
        }
        let maxHost = self.maxHostCalculation(format: self.FORMAT_QUADS, separator: ".")
        return maxHost.components(separatedBy: ".").map { Int($0)!}
    }
    
    /**
     Get maximum host IP address as hex
     */
    public func getMaxHostHex() -> String
    {
        if (self.network_size == 32 || self.network_size == 31) {
            return "0"
            // todo
        }
        return self.maxHostCalculation(format: self.FORMAT_HEX)
    }
    
    /**
     Get maximum host IP address as binary
     */
    public func getMaxHostBinary() -> String
    {
        if (self.network_size == 32 || self.network_size == 31) {
            return "0"
            // todo
        }
        return self.maxHostCalculation(format: self.FORMAT_BINARY)
    }
    
    /**
     Get next network IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getNextNetwork() -> String
    {
        return self.nextNetworkCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Get next network IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getPrevNetwork() -> String
    {
        return self.prevNetworkCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    
    
    /**
     Get subnet mask as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getSubnetMask() -> String
    {
        return self.subnetCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Get subnet mask as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getSubnetMaskQuads() -> [Int]
    {
        let subnetMask = self.subnetCalculation(format: self.FORMAT_QUADS, separator: ".")
        return subnetMask.components(separatedBy: ".").map { Int($0)!}
    }
    
    /**
     Get subnet mask as binary
     */
    public func getSubnetMaskBinary() -> String
    {
        return self.subnetCalculation(format: self.FORMAT_BINARY)
    }
    
    /**
     Get network portion of IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getNetworkPortion() -> String
    {
        return self.networkCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Gets network portion of IP address as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getNetworkPortionQuads() -> [Int]
    {
        let networkPortion = self.networkCalculation(format: self.FORMAT_QUADS, separator: ".")
        return networkPortion.components(separatedBy: ".").map { Int($0)!}
    }
    
    /**
     Get network portion of IP address as hexadecimal
     */
    public func getNetworkPortionHex() -> String
    {
        return self.networkCalculation(format: self.FORMAT_HEX)
    }
    
    /**
     Get network portion of IP address as binary
     */
    public func getNetworkPortionBinary() -> String
    {
        return self.networkCalculation(format: self.FORMAT_BINARY)
    }
    
    /**
     Get host portion of IP address as dotted quads: xxx.xxx.xxx.xxx
     */
    public func getHostPortion() -> String
    {
        return self.hostCalculation(format: self.FORMAT_QUADS, separator: ".")
    }
    
    /**
     Get host portion as array of quads: [xxx, xxx, xxx, xxx]
     */
    public func getHostPortionQuads() -> [Int]
    {
        let hostPortion = self.hostCalculation(format: self.FORMAT_QUADS, separator: ".")
        return hostPortion.components(separatedBy: ".").map { Int($0)!}
    }
    
    /**
     Get host portion of IP address as hexadecimal
     */
    public func getHostPortionHex() -> String
    {

        return self.hostCalculation(format: self.FORMAT_HEX)
    }
    
    /**
     Get host portion of IP address as binary
     */
    public func getHostPortionBinary() -> String
    {
        return self.hostCalculation(format: self.FORMAT_BINARY)
    }
    
    /**
     Get all host IP addresses.
     
     Removes broadcast and netork address if they exist.
     */
    
    public func getAllIPAddresses() -> [String]
    {
        let start_ip = self.getIPAddressRangeAsInts()[0]
        let end_ip = self.getIPAddressRangeAsInts()[1]
        
        var output = [String]()
        var ip = start_ip
        while ip <= end_ip
        {
            output.append(long2ip(long: ip))
            ip += 1
        }
        return output
    }
    
    /**
     Is the IP address in the subnet?
     */
    public func isIPAddressInSubnet(ip_address_string: String) -> Bool {
        let ip_address = ip2long(ip_address: ip_address_string)
        let start_ip = self.getIPAddressRangeAsInts()[0]
        let end_ip = self.getIPAddressRangeAsInts()[1]
        
        if(ip_address >= start_ip && ip_address <= end_ip)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    
    /**
     Get subnet calculations as an associated array
     */
    public func getSubnetArrayReport() -> String
    {
        return "Todo - subnet array report"
    }
    

    // MARK: Private Functions
    
    /**
     Calculate subnet mask
     */
    private func calculateSubnetMask(network_size: Int) -> Int
    {
        return 0xFFFFFFFF << (32 - network_size)
    }
    
    /**
     Calculate IP address for formatting
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     
     - Returns: Formatted IP address
     */
    private func ipAddressCalculation(format: String, separator: String = "") -> String
    {
        return "0.0.0.0"
    }
    
    
    /**
     Subnet calculation
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    private func subnetCalculation(format: String, separator: String = "") -> String
    {
        let mask_quads = [
            String(format: format, (self.subnet_mask >> 24) & 0xFF),
            String(format: format, (self.subnet_mask >> 16) & 0xFF),
            String(format: format, (self.subnet_mask >> 8) & 0xFF),
            String(format: format, (self.subnet_mask >> 0) & 0xFF)
        ]
        
        return mask_quads.joined(separator: separator)
    }
    
    /**
     Calculate host portion for formatting
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    
    private func hostCalculation(format: String, separator: String = "") -> String
    {
        return "todo - host calculation" // (it's identical to subnet Calc basically)
    }
    
    
    
    /**
     Calculate min portion for formatting
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    
    private func minHostCalculation(format: String, separator: String = "") -> String
    {
        let network_quads = [
            String(format: format, self.quads[0] & (self.subnet_mask >> 24)),
            String(format: format, self.quads[1] & (self.subnet_mask >> 16)),
            String(format: format, self.quads[2] & (self.subnet_mask >> 8)),
            String(format: format, (self.quads[3] & (self.subnet_mask >> 0)) + 1),
        ]
        return network_quads.joined(separator: separator)
    }
    
    
    /**
     Calculate max portion for formatting
     
     - Parameters:
       - format: sprintf format to determine if decimal, hex or binary
       - separator: implode separator for formatting quads vs hex and binary
     */
    
    private func maxHostCalculation(format: String, separator: String = "") -> String
    {
        let network_quads = self.getNetworkPortionQuads()
        let number_ip_addresses = self.getNumberIPAddresses()
        
        let network_range_quads = [
            String(format: format, (network_quads[0] & (self.subnet_mask >> 24)) + (((number_ip_addresses - 1) >> 24) & 0xFF)),
            
            String(format: format, (network_quads[1] & (self.subnet_mask >> 16)) + (((number_ip_addresses - 1) >> 16) & 0xFF)),
            
            String(format: format, (network_quads[2] & (self.subnet_mask >> 8)) + (((number_ip_addresses - 1) >> 8) & 0xFF)),
            
            String(format: format, (network_quads[3] & (self.subnet_mask >> 0)) + (((number_ip_addresses - 1) >> 0) & 0xFE)),

        ]
        return network_range_quads.joined(separator: separator)
    }
    
    
    

    
   
    
    /**
     Validate IP address and network
     
     - Parameters:
       - ip_address: IP address is dotted quads format
       - network_size: Network size
     */
    
    private func validateInputs(ip_address: String, network_size: Int)
    {
        // todo -- throw errors if IPs are not valid
    }
    
    
    /**
     Get the start and end of the IP address range as ints
     
      - Returns: Array [start IP, end IP]
     */

    private func getIPAddressRangeAsInts() -> [Int]
    {
        return [0,1] // todo
    }
       
    
    /**
     The equivalent of `pow()` but it works with integers
     */
    private func intPow(base: Int, exp: Int) -> Int {
        let result = pow(Double(base),Double(exp))
        return Int(result)
    }
    
    
    
    /**
     Converts a string containing an (IPv4) Internet Protocol dotted address into a long integer
     
     Adapted from PHP's function [ip2long()](https://www.php.net/manual/en/function.long2ip.php).
     
     - Parameters:
       - ip_address: IP address in string format
     */
    private func ip2long (ip_address: String) -> Int {

        let quads = ip_address.components(separatedBy: ".").map { Int($0)!}
//        var i = 3
        
        var quad_index = 3
        var exp_index = 0
        
        var long: Int = 0
        while (quad_index >= 0 )
        {
            long += intPow(base:256, exp: exp_index) * quads[quad_index]
            quad_index -= 1
            exp_index += 1
        }
        
        return long
    }
    
    
    
    /**
     Converts an long integer address into a string in (IPv4) Internet standard dotted format.
     
     Adapted from PHP's function [long2ip()](https://www.php.net/manual/en/function.long2ip.php).
     
     - Parameters:
       - long: IP address in integer format
     */
    private func long2ip (long: Int) -> String {
        // valid range: 0.0.0.0 -> 255.255.255.255
        var long = long
        if (long < 0 || long > 4294967295)
        {
            return "Error";
            // todo throw error?
        }
        var ip = ""
        var i = 3
        while (i >= 0 )
        {
            ip += String(long / intPow(base:256, exp: i))
            long -= (long / intPow(base: 256, exp: i)) * intPow(base:256, exp: i)
            if (i > 0)
            {
                ip += "."
            }
            i -= 1
        }
        
        return ip
    }
    
}


// MARK: SubnetCalc6

class SubnetCalc6 {
    /** IP address as compact, human readable format: 2001:db8:: */
    var ip_address: String

    /** CIDR network size */
    var network_size: Int
    
    let FORMAT_QUADS  = "%d";
    let FORMAT_HEX    = "%02X";
    let FORMAT_BINARY = "%08b";
    
    public init(ip_address: String, network_size: Int) {
        self.ip_address = ip_address
        self.network_size = network_size
    }
    
    /**
     Get network size
     */
    public func getNetworkSize() -> Int
    {
        return self.network_size
    }
    
    /**
     Get IP address as short string: 2001:db8::
     */
    public func getIPAddressStringShort() -> String
    {
        return ipLong2Short(ip_address_long: self.ip_address)
    }
    
    /**
     Get IP address as long string: 2001:0db8:0000:0000:0000:0000:0000:0000
     */
    public func getIPAddressStringLong() -> String
    {
        return ipShort2Long(ip_address_short: self.ip_address)
    }
    
    /**
     Get IP address as 128-bit integer
     */
    public func getIPAddressInt() -> UInt128
    {
        let ip_address_short = self.getIPAddressStringShort()
        return ip2int(ip_address: ip_address_short)
    }
    
    /**
     Converts a short IP address string (2001:db8::) to long string (2001:0db8:0000:0000:0000:0000:0000:0000)
     */
    private func ipShort2Long(ip_address_short: String) -> String {
        var ip_address_long = "Long address gets returned here"
        // do the math
        return ip_address_long
    }
    
    /**
     Converts a short IP address string (2001:db8::) to long string (2001:0db8:0000:0000:0000:0000:0000:0000)
     */
    private func ipLong2Short(ip_address_long: String) -> String {
        var ip_address_short = "Short address gets returned here"
        // do the math
        return ip_address_short
    }
    
    /**
     Converts an IP address string (either long or short) to a 128 bit integer
     */
    private func ip2int(ip_address: String) -> UInt128 {
        var ip_int: UInt128
        ip_int = 0
        let ip_address_long = ipShort2Long(ip_address_short: ip_address)
        // do the math
        return ip_int
    }
    
    /**
     Converts a 128 bit integer to a long IP address string
     */
    private func int2ip(ip_int: UInt128) -> String {
        var ip_address_long: String
        ip_address_long = "0::0"
        // do the math
        return ip_address_long
    }

}


// MARK: SubnetCalculator6

class SubnetCalculator6 {
      /** IP address as compact, human readable format: 2001:db8:: */
        var ip_address: String
        
        /** CIDR network size */
        var network_size: Int
        
        /** Deprecated: Array of four elements containing the four quads of the IP address */
        var quads = [Int]()
        
        /** Deprecated: Subnet mask in format used for subnet calculations */
        var subnet_mask: Int
        
        /** Deprecated: Subnet report in blob format */
        var report: String
        
        let FORMAT_QUADS  = "%d";
        let FORMAT_HEX    = "%02X";
        let FORMAT_BINARY = "%08b";
        
    
    
        
        /**
         Constructor -- Takes IP address and network size, validates inputs, and assigns class attributes.
         
         For example: 2001:db8::/32 would be `ip` = `2001:db8` and `network_size` = `32`
         
         - Parameters:
           - ip_address: IP address in dotted quad notation
           - network_size: CIDR network size
           - report: Deprecated: Subnet report in blob format
         */
        
        public init(ip_address: String, network_size: Int, report: String = "") {
            
            
            self.ip_address = ip_address
            self.network_size = network_size
            self.quads = ip_address.components(separatedBy: ":").map { Int($0)!}
            self.report = "todo"
            self.subnet_mask = 0
            
//            self.validateInputs(ip_address: ip_address, network_size: network_size)
//            self.subnet_mask = self.calculateSubnetMask(network_size: network_size)

    //        self.report = report ?: SubnetReport()
        }
        
        
        // MARK: Public functions
        
        /**
         Get IP address as human readable: 2001:db8::
         */
        public func getIPAddress() -> String
        {
            return self.ip_address
        }
        
        /**
         [Deprecated] Get IP address as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getIPAddressQuads() -> [Int]
        {
            return self.quads
        }
        
        /**
         [Deprecated] Get IP address as hexadecimal
         */
        public func getIPAddressHex() -> String
        {
            return self.ipAddressCalculation(format: self.FORMAT_HEX)
        }

        /**
         [Deprecated] Get IP address as binary
         */
        public func getIPAddressBinary() -> String
        {
            return self.ipAddressCalculation(format: self.FORMAT_BINARY)
        }
        
        public func getIPAddressInteger() -> Int
        {
            let ipString = self.getIPAddress()
            return ip2long(ip_address: ipString)
        }
    
        public func getIPAddressInteger128() -> UInt128
        {
            let ipString = self.getIPAddress()
            return ip2int128(ip_address: ipString)
        }
        
        /**
         Get network size
         */
        public func getNetworkSize() -> Int
        {
            return self.network_size
        }
        
        /**
         Get the number of IP addresses in the network
         */
        public func getNumberIPAddresses() -> Int
        {
            return intPow(base: 2, exp: (32 - self.network_size))
        }
        
        
        /**
         Get the number of addressable hosts in the network
         */
        
        public func getNumberAddressableHosts() -> Int
        {
            if(self.network_size == 32) {
                return 1
            }
            if(self.network_size == 31) {
                return 2
            }
            
            return (self.getNumberIPAddresses() - 2)
        }
        
        
        /**
         Get range of IP addresses in the network
         - Returns: Array containing start and end of IP address range. IP addresses are in dotted quad notation.
         */
        public func getIPAddressRange() -> [String]
        {
            return [self.getMinHost(),self.getMaxHost()]
        }
        
        
        /**
         Calculate network portion for formatting
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        
        private func networkCalculation(format: String, separator: String = "") -> String
        {
            let network_quads = [
                String(format: format, self.quads[0] & (self.subnet_mask >> 24)),
                String(format: format, self.quads[1] & (self.subnet_mask >> 16)),
                String(format: format, self.quads[2] & (self.subnet_mask >> 8)),
                String(format: format, self.quads[3] & (self.subnet_mask >> 0)),
            ];
            return network_quads.joined(separator: separator)
        }
        
        
        
        
        /**
         Calculate the broadcast IP address
         
         - Returns: IP address as dotted quads
         */
        
        public func getBroadcastAddress() -> String
        {
            let network_quads       = self.getNetworkPortionQuads()
            let number_ip_addresses = self.getNumberIPAddresses()
            
            let network_range_quads = [
                String(format: self.FORMAT_QUADS, (network_quads[0] & (self.subnet_mask >> 24))+(((number_ip_addresses - 1) >> 24) & 0xFF)),
                String(format: self.FORMAT_QUADS, (network_quads[1] & (self.subnet_mask >> 16))+(((number_ip_addresses - 1) >> 16) & 0xFF)),
                String(format: self.FORMAT_QUADS, (network_quads[2] & (self.subnet_mask >> 8))+(((number_ip_addresses - 1) >> 8) & 0xFF)),
                String(format: self.FORMAT_QUADS, (network_quads[3] & (self.subnet_mask >> 0))+(((number_ip_addresses - 1) >> 0) & 0xFF)),
            ];
            return network_range_quads.joined(separator: ".")
        }
        
        
        /**
         Calculate the network address for the next network
            The exact same code as calculating broadcast address, except I'm no longer subtracting one from each quad
              - Returns: IP address as dotted quads
         */
        public func nextNetworkCalculation(format: String, separator: String = "") -> String
        {
    //        let network_quads       = self.getNetworkPortionQuads()
    //        let number_ip_addresses = self.getNumberIPAddresses()
    //
    //        let network_range_quads = [
    //            String(format: self.FORMAT_QUADS, (network_quads[0] & (self.subnet_mask >> 24))+(((number_ip_addresses) >> 24) & 0xFF)),
    //            String(format: self.FORMAT_QUADS, (network_quads[1] & (self.subnet_mask >> 16))+(((number_ip_addresses) >> 16) & 0xFF)),
    //            String(format: self.FORMAT_QUADS, (network_quads[2] & (self.subnet_mask >> 8))+(((number_ip_addresses) >> 8) & 0xFF)),
    //            String(format: self.FORMAT_QUADS, (network_quads[3] & (self.subnet_mask >> 0))+(((number_ip_addresses) >> 0) & 0xFF)),
    //        ];
    //        return network_range_quads.joined(separator: ".")
            let broadcast_addr = self.getBroadcastAddress()
            let broadcast_addr_int = ip2long(ip_address: broadcast_addr)
            var next_network_int = broadcast_addr_int + 1
            
            if(next_network_int > 4294967295){
                next_network_int = 4294967295 // the highest possible IPv4 address
            }
            
            let next_network_string = long2ip(long: next_network_int)
            return next_network_string
        }
        
         
        /**
            Calculate the previous network address
         
         The exact same code as calculating network address, except I'm subtracting the number of host addresses too
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        
        private func prevNetworkCalculation(format: String, separator: String = "") -> String
        {
            
            let network_addr = self.getNetworkPortion()
            let network_addr_int = ip2long(ip_address: network_addr)
            var prev_network_int = network_addr_int - self.getNumberIPAddresses()
            
            if(prev_network_int < 0) {
                prev_network_int = 0
            }
            
            let prev_network_string = long2ip(long: prev_network_int)
            return prev_network_string
            
        }

        
        
        /**
         Get minimum host IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getMinHost() -> String {
            if(self.network_size == 32 || self.network_size == 31) {
                return self.ip_address
            }
            return self.minHostCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Get minimum host IP address as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getMinHostQuads() -> [Int]
        {
            if(self.network_size == 32 || self.network_size == 31) {
                return self.quads
            }
            let minHost = self.minHostCalculation(format: "%d", separator: ".")
            return minHost.components(separatedBy: ".").map { Int($0)!}
        }
        
        /**
         Get minimum host IP address as hex
         - Warning: Not yet complete
         */
        public func getMinHostHex() -> String
        {
            if(self.network_size == 32 || self.network_size == 31) {
                return "0" // todo wtf
            }
            return self.minHostCalculation(format: self.FORMAT_HEX)
        }
        
        /**
         Get minimum host IP address as binary
         - Warning: Not yet complete
         */
        public func getMinHostBinary() -> String {
            return "0" // todo
        }
        
        
        /**
         Get maximum host IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getMaxHost() -> String
        {
            if (self.network_size == 32 || self.network_size == 31) {
                return self.ip_address
            }
            return self.maxHostCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Get maximum host IP address as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getMaxHostQuads() -> [Int]
        {
            if (self.network_size == 32 || self.network_size == 31) {
                return self.quads
            }
            let maxHost = self.maxHostCalculation(format: self.FORMAT_QUADS, separator: ".")
            return maxHost.components(separatedBy: ".").map { Int($0)!}
        }
        
        /**
         Get maximum host IP address as hex
         */
        public func getMaxHostHex() -> String
        {
            if (self.network_size == 32 || self.network_size == 31) {
                return "0"
                // todo
            }
            return self.maxHostCalculation(format: self.FORMAT_HEX)
        }
        
        /**
         Get maximum host IP address as binary
         */
        public func getMaxHostBinary() -> String
        {
            if (self.network_size == 32 || self.network_size == 31) {
                return "0"
                // todo
            }
            return self.maxHostCalculation(format: self.FORMAT_BINARY)
        }
        
        /**
         Get next network IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getNextNetwork() -> String
        {
            return self.nextNetworkCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Get next network IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getPrevNetwork() -> String
        {
            return self.prevNetworkCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        
        
        /**
         Get subnet mask as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getSubnetMask() -> String
        {
            return self.subnetCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Get subnet mask as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getSubnetMaskQuads() -> [Int]
        {
            let subnetMask = self.subnetCalculation(format: self.FORMAT_QUADS, separator: ".")
            return subnetMask.components(separatedBy: ".").map { Int($0)!}
        }
        
        /**
         Get subnet mask as binary
         */
        public func getSubnetMaskBinary() -> String
        {
            return self.subnetCalculation(format: self.FORMAT_BINARY)
        }
        
        /**
         Get network portion of IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getNetworkPortion() -> String
        {
            return self.networkCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Gets network portion of IP address as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getNetworkPortionQuads() -> [Int]
        {
            let networkPortion = self.networkCalculation(format: self.FORMAT_QUADS, separator: ".")
            return networkPortion.components(separatedBy: ".").map { Int($0)!}
        }
        
        /**
         Get network portion of IP address as hexadecimal
         */
        public func getNetworkPortionHex() -> String
        {
            return self.networkCalculation(format: self.FORMAT_HEX)
        }
        
        /**
         Get network portion of IP address as binary
         */
        public func getNetworkPortionBinary() -> String
        {
            return self.networkCalculation(format: self.FORMAT_BINARY)
        }
        
        /**
         Get host portion of IP address as dotted quads: xxx.xxx.xxx.xxx
         */
        public func getHostPortion() -> String
        {
            return self.hostCalculation(format: self.FORMAT_QUADS, separator: ".")
        }
        
        /**
         Get host portion as array of quads: [xxx, xxx, xxx, xxx]
         */
        public func getHostPortionQuads() -> [Int]
        {
            let hostPortion = self.hostCalculation(format: self.FORMAT_QUADS, separator: ".")
            return hostPortion.components(separatedBy: ".").map { Int($0)!}
        }
        
        /**
         Get host portion of IP address as hexadecimal
         */
        public func getHostPortionHex() -> String
        {

            return self.hostCalculation(format: self.FORMAT_HEX)
        }
        
        /**
         Get host portion of IP address as binary
         */
        public func getHostPortionBinary() -> String
        {
            return self.hostCalculation(format: self.FORMAT_BINARY)
        }
        
        /**
         Get all host IP addresses.
         
         Removes broadcast and netork address if they exist.
         */
        
        public func getAllIPAddresses() -> [String]
        {
            let start_ip = self.getIPAddressRangeAsInts()[0]
            let end_ip = self.getIPAddressRangeAsInts()[1]
            
            var output = [String]()
            var ip = start_ip
            while ip <= end_ip
            {
                output.append(long2ip(long: ip))
                ip += 1
            }
            return output
        }
        
        /**
         Is the IP address in the subnet?
         */
        public func isIPAddressInSubnet(ip_address_string: String) -> Bool {
            let ip_address = ip2long(ip_address: ip_address_string)
            let start_ip = self.getIPAddressRangeAsInts()[0]
            let end_ip = self.getIPAddressRangeAsInts()[1]
            
            if(ip_address >= start_ip && ip_address <= end_ip)
            {
                return true
            }
            else
            {
                return false
            }
        }
        
        
        /**
         Get subnet calculations as an associated array
         */
        public func getSubnetArrayReport() -> String
        {
            return "Todo - subnet array report"
        }
        

        // MARK: Private Functions
        
        /**
         Calculate subnet mask
         */
        private func calculateSubnetMask(network_size: Int) -> Int
        {
            return 0xFFFFFFFF << (32 - network_size)
        }
        
        /**
         Calculate IP address for formatting
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         
         - Returns: Formatted IP address
         */
        private func ipAddressCalculation(format: String, separator: String = "") -> String
        {
            return "0.0.0.0"
        }
        
        
        /**
         Subnet calculation
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        private func subnetCalculation(format: String, separator: String = "") -> String
        {
            let mask_quads = [
                String(format: format, (self.subnet_mask >> 24) & 0xFF),
                String(format: format, (self.subnet_mask >> 16) & 0xFF),
                String(format: format, (self.subnet_mask >> 8) & 0xFF),
                String(format: format, (self.subnet_mask >> 0) & 0xFF)
            ]
            
            return mask_quads.joined(separator: separator)
        }
        
        /**
         Calculate host portion for formatting
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        
        private func hostCalculation(format: String, separator: String = "") -> String
        {
            return "todo - host calculation" // (it's identical to subnet Calc basically)
        }
        
        
        
        /**
         Calculate min portion for formatting
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        
        private func minHostCalculation(format: String, separator: String = "") -> String
        {
            let network_quads = [
                String(format: format, self.quads[0] & (self.subnet_mask >> 24)),
                String(format: format, self.quads[1] & (self.subnet_mask >> 16)),
                String(format: format, self.quads[2] & (self.subnet_mask >> 8)),
                String(format: format, (self.quads[3] & (self.subnet_mask >> 0)) + 1),
            ]
            return network_quads.joined(separator: separator)
        }
        
        
        /**
         Calculate max portion for formatting
         
         - Parameters:
           - format: sprintf format to determine if decimal, hex or binary
           - separator: implode separator for formatting quads vs hex and binary
         */
        
        private func maxHostCalculation(format: String, separator: String = "") -> String
        {
            let network_quads = self.getNetworkPortionQuads()
            let number_ip_addresses = self.getNumberIPAddresses()
            
            let network_range_quads = [
                String(format: format, (network_quads[0] & (self.subnet_mask >> 24)) + (((number_ip_addresses - 1) >> 24) & 0xFF)),
                
                String(format: format, (network_quads[1] & (self.subnet_mask >> 16)) + (((number_ip_addresses - 1) >> 16) & 0xFF)),
                
                String(format: format, (network_quads[2] & (self.subnet_mask >> 8)) + (((number_ip_addresses - 1) >> 8) & 0xFF)),
                
                String(format: format, (network_quads[3] & (self.subnet_mask >> 0)) + (((number_ip_addresses - 1) >> 0) & 0xFE)),

            ]
            return network_range_quads.joined(separator: separator)
        }
        
        
        

        
       
        
        /**
         Validate IP address and network
         
         - Parameters:
           - ip_address: IP address is dotted quads format
           - network_size: Network size
         */
        
        private func validateInputs(ip_address: String, network_size: Int)
        {
            // todo -- throw errors if IPs are not valid
        }
        
        
        /**
         Get the start and end of the IP address range as ints
         
          - Returns: Array [start IP, end IP]
         */

        private func getIPAddressRangeAsInts() -> [Int]
        {
            return [0,1] // todo
        }
           
        
        /**
         The equivalent of `pow()` but it works with integers
         */
        private func intPow(base: Int, exp: Int) -> Int {
            let result = pow(Double(base),Double(exp))
            return Int(result)
        }
        
        
        
        /**
         Converts a string containing an (IPv4) Internet Protocol dotted address into a long integer
         
         Adapted from PHP's function [ip2long()](https://www.php.net/manual/en/function.long2ip.php).
         
         - Parameters:
           - ip_address: IP address in string format
         */
        private func ip2long (ip_address: String) -> Int {

            let quads = ip_address.components(separatedBy: ".").map { Int($0)!}
    //        var i = 3
            
            var quad_index = 3
            var exp_index = 0
            
            var long: Int = 0
            while (quad_index >= 0 )
            {
                long += intPow(base:256, exp: exp_index) * quads[quad_index]
                quad_index -= 1
                exp_index += 1
            }
            
            return long
        }
    
    
        
        /**
         Converts a string containing an (IPv6) Internet Protocol dotted address into a 128-bit integer
         
         Adapted from PHP's function [ip2long()](https://www.php.net/manual/en/function.long2ip.php).
         
         - Parameters:
           - ip_address: IP address in string format
         */
        private func ip2int128 (ip_address: String) -> UInt128 {

            let quads = ip_address.components(separatedBy: ".").map { Int($0)!}
    //        var i = 3
            
            var quad_index = 3
            var exp_index = 0
            
            var long: UInt128 = 0
            while (quad_index >= 0 )
            {
//                long += intPow(base:256, exp: exp_index) * quads[quad_index]
                quad_index -= 1
                exp_index += 1
            }
            
            return long
        }
        
        
        
        /**
         Converts an long integer address into a string in (IPv4) Internet standard dotted format.
         
         Adapted from PHP's function [long2ip()](https://www.php.net/manual/en/function.long2ip.php).
         
         - Parameters:
           - long: IP address in integer format
         */
        private func long2ip (long: Int) -> String {
            // valid range: 0.0.0.0 -> 255.255.255.255
            var long = long
            if (long < 0 || long > 4294967295)
            {
                return "Error";
                // todo throw error?
            }
            var ip = ""
            var i = 3
            while (i >= 0 )
            {
                ip += String(long / intPow(base:256, exp: i))
                long -= (long / intPow(base: 256, exp: i)) * intPow(base:256, exp: i)
                if (i > 0)
                {
                    ip += "."
                }
                i -= 1
            }
            
            return ip
        }
        
}



 // MARK: Allen's first class (depricated)


/**
 Classes for interacting with IPv4 addresses
 
 - Warning: This class is deprecated
 */

class ip4_old: ip_view {

    var dec_mask: Int = -1
    var dec_ip: Int = -1
    
    var str_mask: String = ""
    var str_ip: String = ""
    
    override func calculate() {
        let ip_addr_split = self.ip_input.components(separatedBy: "/")
        self.str_ip = ip_addr_split[0]
        if(ip_addr_split.indices.contains(1))
        {
            str_mask = ip_addr_split[1]
        }
        

        
        NSLog("IP addr is " + str_ip + " and mask is "+str_mask)
        
        self.dec_mask = decMask(mask: str_mask)
        self.dec_ip = str_ip_to_dec(str_ip: self.str_ip)
        
        NSLog("Decimal mask is " + String(dec_mask))
//
//        calc_network()
//
        self.host_last_host = "2.2.2.2"
        self.host_broadcast = "2.2.2.2"
        self.host_usable_hosts = 0
        self.host_condensed = "2.2.2.2"
    }
    
    
    /**
        Calculates the network address for this object
        
     */
//    func calc_network() -> String {
//
//    }
    
    
    func decMask(mask: String) -> Int
    {
        var decMask = 0;
        let intMask = Int(mask) ?? -1
        
        if(intMask >= 0 && intMask <= 32) {
            // it was CIDR
//            NSLog("CIDR Mask detected")
            decMask = allenPow(base: 2,exp: intMask) // WRONG - this tells you the number of subnets
        }
        
        if(is_str_ip(str_ip: mask)) {
            decMask = str_ip_to_dec(str_ip: mask, reverse: true)
        }

        return decMask
    }
    
    /**
        Determines whether a string IP is a valid IP address
        - Parameters:
            - str_ip: An IP address as a string (e.g., `10.10.0.1`)
        - Returns: True or False
     */
    func is_str_ip(str_ip: String) -> Bool
    {
        let result = str_ip.range(of: #"^(?:\d{1,3}\.){3}\d{1,3}$"#,
                         options: .regularExpression) != nil // true

        return result
    }
    
    // Converts a string IP (255.0.0.0) to a decimal (4278190080)
    func str_ip_to_dec(str_ip: String, reverse: Bool = false) -> Int
    {
        if(!is_str_ip(str_ip: str_ip))
        {
            return -1
        }
        
        var decIP: Int = 0
     
        var ip_addr_split = str_ip.components(separatedBy: ".")
            
        if(reverse) {
            ip_addr_split.reverse()
        }
        
        for (index, element) in ip_addr_split.enumerated() {
            let element = Int(element) ?? 0
            decIP = decIP + allenPow(base: 256,exp: index) * element
//          NSLog("Item \(index): \(element)")
        }
        
        return decIP
    }
    
    func allenPow(base: Int, exp: Int) -> Int {
        return Int(pow(Double(base),Double(exp)))
    }
   
    
    /*
    func IPToInt(ip: String) -> Int {
        let octets: [Int] = ip.split(separator: ".").map({Int($0)!})
        var numValue: Int = 0
        for (i, n) in octets.enumerated() {
            let p: Int = NSDecimalNumber(decimal: pow(256, (3-i))).intValue
            numValue += n * p
        }
        return numValue
    }
    
    func IntToIP(int: Int) -> String {
        var octet: [Int] = []
        var total = 0
        for i in stride(from: 3, to: 0, by: -1) {
            var tmp: Int
            if i < 3 {
                tmp = Int((int-total) / Int(pow(Float(256), Float(i))))
            } else {
                tmp = Int((int) / Int(pow(Float(256), Float(i))))
            }
            total += tmp * Int(pow(Float(256), Float(i)))
            octet.append(tmp)
        }
        
        octet.append(int % 256)
        return octet.map({String($0)}).joined(separator: ".")
    }
    
    func explodeRange(lower: String, upper: String) -> [String] {
        var ips: [String] = []
        for i in stride(from:IPToInt(ip: lower), through: IPToInt(ip:upper), by: 1) {
            ips.append(IntToIP(int: i))
        }
        return ips
    }*/
    
}


