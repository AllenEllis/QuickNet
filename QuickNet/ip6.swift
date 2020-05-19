//
//  ip6.swift
//  QuickNet
//
//  Created by Allen Ellis on 5/19/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UInt128


/**
 Provided an IPv6 address and network size, it has public methods for calculating:
  - First host
  - Last host
  - Expanded notation
  - Shortened notation
 
- Parameters:
  - ip_mixed_string: An IP address that is not necessarily fully expanded nor contracted
  - ip_long_string: An IP address that has been expanded
  - ip_short_string: An IP address that has been compacted
  - network_size: The CIDR prefix
  - first_host: The first IP address in the network
  - last_host: The last ip_address in the network
 */

class ip6 {

    var ip_mixed_string: String
    var ip_long_string: String
    var ip_short_string: String
    var network_size: Int
    var first_host: String
    var last_host: String
    
    public init(ip_address_mixed: String, network_size: Int) {
        self.ip_mixed_string = ip_address_mixed
        self.ip_long_string = ""
        self.ip_short_string = ""
        self.network_size = network_size
        self.first_host = ""
        self.last_host = ""
        
        self.populate()
    }
    
    private func populate() {
        self.ip_long_string = self.getIPLongFromShort(ip_short_string: self.ip_mixed_string)
        self.ip_short_string = self.getIPShortFromLong(ip_long_string: self.ip_long_string)
        self.calculateFirstLastHosts()
    }
    
    private func calculateFirstLastHosts(){
            // todo
    }
    
    
    /**
     * Takes a short IP address string and converts it to a long IP address string.
     *
     * `2001:db8::` -> `2001:0db8:0000:0000:0000:0000:0000:0000`
     */
    public func getIPLongFromShort(ip_short_string: String) -> String {
        let ip_short_array = self.convertToIPShortArray(ip_string: ip_short_string)
        let ip_long_array = self.convertToIPLongArray(ip_short_array: ip_short_array)
        let ip_long_string = self.convertToIPLongString(ip_long_array: ip_long_array)
        
        return ip_long_string
    }
    
    /**
     Takes an IP long array and reformats it as a long string
     */
    private func convertToIPLongString(ip_long_array: [[String:String]]) -> String {
            var string = ""
            for (index, ip) in ip_long_array.enumerated() {
                string.append(ip["hex_long"]!)
                
                // If we aren't on the last entry
                if (index != ip_long_array.count - 1) {
                    string.append(":")
                }
            }
        return string
        }
    
    
    /**
     * Takes an IP address string and returns an array with some hextets populated
     */
    private func convertToIPShortArray(ip_string: String) -> [Hextet] {
        var ip_array: [Hextet] = []
        let temp_array = ip_string.components(separatedBy: ":")
        
        for hextet_str in temp_array {
            ip_array.append(self.calculateHextetVars(hextet_str: hextet_str))
        }
        return ip_array
    }
    
    
    /**
     * Takes a short IP array and expands it into a long IP array by populating the void and adding leading zeroes
     */
    private func convertToIPLongArray(ip_short_array: [[String:String]]) -> [[String:String]] {
        // todo
    }
    
    /**
     Analyses a shortened array to see how many hextets is represented by the void character (`::`)
     */
    private func calculateVoidSize(ip_short_array: [[String:String]]) -> Int
    {
        // determine if there is even a void
        var void = "false";
        var void_count = 0;
        for ip in ip_short_array {
            if (ip["void"] == "true") {
                void = "true";
                void_count += 1;
            }
        }
        if (void == "false") {
            return 0;
        }

        let void_size = 8 - ip_short_array.count + void_count; // add back in any array entries that were the void
        return void_size;
    }
    
    /**
     * Takes a hextet and replaces it with an array contaning various interpretations of that value
     */
    private func calculateHextetVars(hextet_str: String) -> Hextet
    {
        
//        var hextet: [String: Any] = [
//            "int": 0,
//            "hex": 0,
//            "hex_long": "0000",
//            "void": false
//        ]
        var hextet = Hextet()
        
        if (hextet_str == "") {
            hextet.void = true;
        }

        hextet.int = Int(hextet_str)!
        hextet.hex = String(format:"%x",hextet_str)
        hextet.hex_long = String(format:"%04x", hextet_str)
        return hextet;
    }
    
    /**
     Contains additional properties for each hextet
     */
    
    struct Hextet {
        var int: Int = 0
        var hex: String = "0"
        var hex_long: String = "0000"
        var void: Bool = false
    }
    
    /**
     * Takes a long IP address string and converts it to a short IP address string.
     *
     * `2001:0db8:0000:0000:0000:0000:0000:0000` -> `2001:db8::`
     */
    public func getIPShortFromLong(ip_long_string: String) -> String
    {
        // First make sure the user actually gave us a fully expanded long string
        // To do this, we will pretend it's a short string, and convert it to a long string

        let ip_long_string_2 = self.getIPLongFromShort(ip_short_string: ip_long_string)


        // They did, proceed
        let ip_long_array = self.convertToIPShortArray(ip_string: ip_long_string_2)
        let ip_short_array = self.convertIPLongArrayToIPShortArray(ip_long_array: ip_long_array)
        let ip_short_string = self.convertToIPShortString(ip_short_array: ip_short_array)

        return ip_short_string
    }
    
    
    
    /**
     * Takes an IP address array and returns it as a string, separated by colons.
     *
     * @param $ip_array
     * @return string
     */
    private func convertToIPShortString(ip_array: [[String:String]]) -> String
    {
        var string: String
        var piece = ""

        for (index, hextet) in ip_array.enumerated() {
            if(hextet["void"] == "false") {
                piece = hextet["hex"]!
            } else {
                piece = ""
            }
            string.append(piece + ":")
        }

        // remove the last ":" from the end
        string.removeLast()

        return string
    }


    /**
     * Converts a short IP address string into a long IP address string

     */
    private func convertIPShortStringToLongString(ip_short_string: String) -> String
    {
        return self.convertToIPLongString(ip_long_array:
            self.convertToIPLongArray(ip_short_array:
                self.convertToIPShortArray(ip_string:
                    ip_short_string
                )
            )
        );
    }

    
    /**
     * Takes an array of IP hextets, and removes leading zeroes, and removes the void
     */

    private func convertIPLongArrayToIPShortArray(ip_long_array: [Hextet]) -> [Hextet]
    {
        var ip_short_array = [[String:Any]]()
        var void_start = 0
        var void_end = 0
        var void_started = "false"

        var void = self.calculateVoid(ip_array:ip_long_array)

        if (void == "true") {
            void_start = Int(void["beginning"])
            void_end = Int(void_start + void["size"])
        }

        for (index, ip) in ip_long_array.enumerated() {
            if (index >= void_start && index < void_end) {
                if (void_started == "false") {
                    // we are in the start of void
                    ip_short_array.append(self.calculateHextetVars(hextet_str: ""))
                    void_started = "true"
                } else {
                    continue; // we are still in the void, skip until we are no longer in the void
                }
            } else {
                // We are not in the void. Remove leading zeroes and save
                var ip_hex = String(format: "%x", String(ip["hex_long"]!))
                var ip_short = String(format: "%d", ip_hex)
                ip_short_array[index] = self.calculateHextetVars(hextet_str: ip_short)
            }
        }

        return ip_short_array
    }

    
    
    private func calculateVoid(ip_array: [[String:String]]) -> [[String:String]]
    {
        var void_candidates = [[String:String]]()
        var void_beginning = 0 // null
        var void_size = 0 // null
        var in_void = "false"

        for (index, ip) in ip_array.enumerated() {
            if (String(ip["hex_long"]!) != "0000") {
                if (in_void == "true") {
                    // We were already in a void previously? If so, close it
                    void_candidates.append([
                        "beginning": void_beginning,
                        "size": void_size
                        ])
                }
                in_void = "false";
                void_beginning = 0 // null
                void_size = 0 // null
                continue
            } else {
                if (in_void == "false") {
                    // start a new void candidate
                    in_void = "true";
                    void_beginning = index;
                    void_size = 1;
                } else {
                    // we already had a void candidate going, so extend it
                    void_size += 1
                }
            }
        }

        // If the last hextet was a void candidate, close it
        if (in_void == "true") {
            void_candidates.append([
                "beginning": void_beginning,
                "size": void_size
                ])
        }

        var best_size = 0
        var best_candidate = [[String:String]]()

        for (index, candidate) in void_candidates.enumerated() {
            if (Int(candidate["size"]) >= best_size) {
                let best_candidate = candidate
                let best_size = candidate["size"];
            }
        }

        return best_candidate
    }
    
}
