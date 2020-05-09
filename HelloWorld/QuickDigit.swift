//
//  QuickDigit.swift
//  HelloWorld
//
//  Created by Allen Ellis on 5/8/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Foundation

// comment so that Colab does not interpret `#if ...` as a comment
#if canImport(PythonKit)
    import PythonKit
#else
    import Python
#endif


class ip_view {
    
    var ip_input: String
    var host_network: String
    var host_first_host: String
    var host_last_host: String
    var host_broadcast: String
    var host_usable_hosts: String
    var host_condensed: String
    var ipv_type: String
    var subnet_data: [[String: String]] = [[:]]
    
    public init(ip_input: String)
    {
        self.ip_input = ip_input
        self.host_network = "0.0.0.0"
        self.host_first_host = "0.0.0.0"
        self.host_last_host = "0.0.0.0"
        self.host_broadcast = "0.0.0.0"
        self.host_usable_hosts = "0.0.0.0"
        self.host_condensed = "0.0.0.0"
        self.ipv_type = "0"
        self.subnet_data = []
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
            let ip4_obj = ip4(ip_input: self.ip_input)
            self.host_network = ip4_obj.host_network
            self.host_first_host = ip4_obj.host_first_host
            self.host_last_host = ip4_obj.host_last_host
            self.host_broadcast = ip4_obj.host_broadcast
            self.host_usable_hosts = ip4_obj.host_usable_hosts
            self.host_condensed = ip4_obj.host_condensed
        }
        
        if(self.ipv_type == "6")
        {
            self.host_first_host = "aaaa"
            self.host_last_host = "ffff"
            self.host_condensed = "af"
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
    
    func populate_table4() {
        
    }
    
    func populate_table6() -> [[String: String]] {
        let data = [
         [
          "subnet" : "2620:13d::",
          "prefix" : "/32",
          "count" : "1",
          "example" : "Service Provider",
         ],
         [
           "subnet" : "2620:13d:f000::",
           "prefix" : "/36",
           "count" : "16",
           "example" : "Data Center",
          ],
         [
           "subnet" : "2620:13d:ff00::",
           "prefix" : "/40",
           "count" : "256",
           "example" : "Region",
          ],
         [
           "subnet" : "2620:13d:ff00::",
           "prefix" : "/44",
           "count" : "4096",
           "example" : "Campus",
          ]
        ]
            
        return(data)
    }
}





/**
 Classes for interacting with IPv4 addresses
 */

class ip4: ip_view {

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
        self.host_usable_hosts = "2.2.2.2"
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
