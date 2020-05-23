//
//  IP6.swift
//  QuickNet
//
//  Created by Allen Ellis on 5/19/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UInt128
import Cocoa


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

class IP6 {

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
        let addr_given_str = self.ip_long_string
        let prefixlen = self.network_size

        // Remove the `:` symbols from the IP address
        let addr_given_hex = addr_given_str.replacingOccurrences(of: ":", with: "")

        // Calculate the number of 'flexible' bits
        var flexbits = 128 - prefixlen

        // Build the hexadecimal strings of the first and last addresses
        var addr_hex_first = addr_given_hex
        var addr_hex_last = addr_given_hex

        // We start at the end of the string (which is always 32 characters long)
        var pos = 31
        while (flexbits > 0) {
          // Get the character at this position
            let orig_char  = addr_hex_first.substring(with:(pos)..<(pos+1))
            let orig_first = orig_char
            let orig_last = orig_char

          // Convert it to an integer
            let origval_first = Int(UInt(orig_first, radix: 16)!)
            let origval_last = Int(UInt(orig_last, radix: 16)!)

          // First address: calculate the subnet mask. min() prevents the comparison from being negative
            let mask = 0xf << (min(4, flexbits))

          // AND the original against its mask
            let new_val_first = origval_first & mask

          // Last address: OR it with (2^flexbits)-1, with flexbits limited to 4 at a time
            let base = Double(2)
            let exp = Double(min(4, flexbits))
            let new_val_last = origval_last | Int(pow(base,exp)-1)

          // Convert them back to hexadecimal characters
            let new_first = Character(String(format: "%x", new_val_first))
            let new_last = Character(String(format: "%x", new_val_last))

          // And put those character back in their strings
            addr_hex_first = strReplace(myString: addr_hex_first, pos, new_first)
            addr_hex_last  = strReplace(myString: addr_hex_last,  pos, new_last)
//          addr_hex_first = substr_replace(addr_hex_first, new_first, pos, 1)
//          addr_hex_last = substr_replace(addr_hex_last, new_last, pos, 1)

          // We processed one nibble, move to previous position
          flexbits -= 4
          pos -= 1
        }

        // Report to user
        self.first_host = self.convertLongAddrHexToIPString(addr_hex: addr_hex_first)
        self.last_host = self.convertLongAddrHexToIPString(addr_hex: addr_hex_last)
        
        return

    }
    
    /**
     Takes a long hexadecimal string and inserts `:` symbols to make it appear like an IP address.
     
     This function requires a full 32 character string as an input
     */
    private func convertLongAddrHexToIPString(addr_hex: String) -> String {
        if(addr_hex.count != 32) {
//            showAlert(messageText: "Error code 101", informativeText: "Sorry, there wasn an error.\n\nFunction convertLongAddrHexToIPString requires an input that is 32 characters long, but this one is \(addr_hex.count). The string was:\n\n\(addr_hex)")
            return "" // todo - throw error
        }
        var pos = 0
        var ip_string = ""
        while (pos < 32) {
            let orig_chars  = addr_hex.substring(with:(pos)..<(pos+4))
            ip_string.append(String(orig_chars))
            
            // If we're not on the last hextet
            if(pos < 28) {
                ip_string.append(":")
            }
            pos = pos + 4
        }
        
        
        return ip_string
    }
    
    
    /**
     Replace characters in a string based on their index
        https://stackoverflow.com/a/24789950/7560156
     */
    private func strReplace(myString: String, _ index: Int, _ newChar: Character) -> String {
        var chars = Array(myString)     // gets an array of characters
        chars[index] = newChar
        let modifiedString = String(chars)
        return modifiedString
    }

    
    
    /**
     * Takes a short IP address string and converts it to a long IP address string.
     *
     * `2001:db8::` -> `2001:0db8:0000:0000:0000:0000:0000:0000`
     */
    public func getIPLongFromShort(ip_short_string: String) -> String {
        let ip_short_array = self.convertToIPShortArray(ip_string: ip_short_string)
        let ip_long_array = self.convertToIPLongArray(_ip_short_array: ip_short_array)
        let ip_long_string = self.convertToIPLongString(ip_long_array: ip_long_array)
        
        return ip_long_string
    }
    
    /**
     Takes an IP long array and reformats it as a long string
     */
    private func convertToIPLongString(ip_long_array: [Hextet]) -> String {
            var string = ""
            for (index, hextet) in ip_long_array.enumerated() {
                string.append(hextet.hex_long)
                
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
            ip_array.append(self.calculateHextetVars(hex_str: hextet_str))
        }
        return ip_array
    }
    
    
    /**
     * Takes a short IP array and expands it into a long IP array by populating the void and adding leading zeroes
     */
    private func convertToIPLongArray(_ip_short_array: [Hextet]) -> [Hextet] {
        var ip_short_array = _ip_short_array // have to do this so we can modify the value
        var ip_long_array = [Hextet]()
        var void_inserted = false
        var void_array = [String]()
        let void_size = self.calculateVoidSize(ip_short_array: ip_short_array)
       
        
        for _ in 0 ..< void_size {
            void_array.append("0000")
        }

        // Insert the void
        for (index, hextet) in ip_short_array.enumerated() {
            if (hextet.void == true) {
                if (void_inserted == true) {
                    // If the :: is at the start or end, two voids will be in the array. So only proceed if we haven't inserted a void yet
                    ip_short_array.remove(at: index)
                } else {
                    // Insert the void
                    for _ in void_array {
                        ip_long_array.append(Hextet(
                            int: 0,
                            hex: "0",
                            hex_long: "0000",
                            void: false
                        ))
                    }
                    void_inserted = true
                }
            } else {
                ip_long_array.append(hextet)
            }
        }

        if (ip_long_array.count != 8) {
            // todo - handle error
            print("Error - long array ended up with not exactly 8 hextets")
        }

        return ip_long_array
    }
    
    /**
     Analyses a shortened array to see how many hextets is represented by the void character (`::`)
     */
    private func calculateVoidSize(ip_short_array: [Hextet]) -> Int
    {
        // determine if there is even a void
        var void = false
        var void_count = 0
        for hextet in ip_short_array {
            if (hextet.void == true) {
                void = true
                void_count += 1
            }
        }
        if (void == false) {
            return 0
        }

        let void_size = 8 - ip_short_array.count + void_count // add back in any array entries that were the void
        return void_size
    }
    
    /**
     * Takes a hextet (hexadimal number between `0` and `FFFF`) and replaces it with an array contaning various interpretations of that value
     */
    private func calculateHextetVars(hex_str: String) -> Hextet
    {
        
//        var hextet: [String: Any] = [
//            "int": 0,
//            "hex": 0,
//            "hex_long": "0000",
//            "void": false
//        ]
        var hextet = Hextet()
        var _hex_str = hex_str
        
        if (hex_str == "") {
            hextet.void = true
            _hex_str = "0"
        }

        hextet.int = Int(UInt(_hex_str, radix: 16)!) // stack overflow said I needed to use `UInt` https://stackoverflow.com/a/46094575/7560156
        hextet.hex = String(format:"%x", hextet.int)
        hextet.hex_long = String(format:"%04x", hextet.int)
        return hextet
    }
    
    /**
     A hextet is a group of four characters in an IPv6 address. This contains properties for each hextet.
     
     - Parameters:
        - int: The integer value of this sequence (valid values 0 - 65,536)
        - hex: The hex value of this sequence (valid values "0" - "FFFF")
        - hex_long: The hex value of this sequence with leading zeroes (valid values "0000" - "FFFF")
        - void: Indicates whether this section is empty (represented as `::` in the original string). There should only be one void per address string.
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
        let ip_short_string = self.convertToIPShortString(ip_array: ip_short_array)

        return ip_short_string
    }
    
    
    
    /**
     * Takes an IP address array and returns it as a string, separated by colons.
     */
    private func convertToIPShortString(ip_array: [Hextet]) -> String
    {
        var string = ""
        var piece = ""

        for hextet in ip_array {
            if(hextet.void == false) {
                piece = hextet.hex
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
            self.convertToIPLongArray(_ip_short_array:
                self.convertToIPShortArray(ip_string:
                    ip_short_string
                )
            )
        )
    }

    
    /**
     * Takes an array of IP hextets, and removes leading zeroes, and removes the void
     */

    private func convertIPLongArrayToIPShortArray(ip_long_array: [Hextet]) -> [Hextet]
    {
        var ip_short_array = [Hextet]()
        var void_start = 0
        var void_end = 0
        var void_started = false

        let void = self.calculateVoid(ip_array:ip_long_array)

        if (void.beginning >= 0) {
            // just to prevent us operating if the default `-1` value was stored here
            void_start = void.beginning
            void_end = void.beginning + void.size
        }

        for (index, ip) in ip_long_array.enumerated() {
            if (index >= void_start && index < void_end) {
                if (void_started == false) {
                    // we are in the start of void
                    ip_short_array.append(self.calculateHextetVars(hex_str: ""))
                    
                    // if this was the first  hextet, add one more (so we get a double `::`)
                    if (index == 0 || index == 7) {
                        ip_short_array.append(self.calculateHextetVars(hex_str: ""))
                    }
                    void_started = true
                } else {
                    // if this was the last hextet, add one more (so we get a double `::`)
                    if (index == 7) {
                        ip_short_array.append(self.calculateHextetVars(hex_str: ""))
                    }
                    continue // we are still in the void, skip until we are no longer in the void
                }
            } else {
                // We are not in the void. Remove leading zeroes and save
                let ip_hex = String(format: "%x", ip.int)
                ip_short_array.append(self.calculateHextetVars(hex_str: ip_hex)) // , at: index
            }
        }

        return ip_short_array
    }

    
    
    private func calculateVoid(ip_array: [Hextet]) -> VoidCandidate
    {
        var void_candidates = [VoidCandidate]()
        var void_beginning = 0 // null
        var void_size = 0 // null
        var in_void = false

        for (index, hextet) in ip_array.enumerated() {
            if (hextet.hex_long != "0000") {
                if (in_void == true) {
                    // We were already in a void previously? If so, close it
                    void_candidates.append(VoidCandidate(beginning: void_beginning, size: void_size))
                }
                in_void = false
                void_beginning = 0 // null
                void_size = 0 // null
                continue
            } else {
                if (in_void == false) {
                    // start a new void candidate
                    in_void = true
                    void_beginning = index
                    void_size = 1
                } else {
                    // we already had a void candidate going, so extend it
                    void_size += 1
                }
            }
        }

        // If the last hextet was a void candidate, close it
        if (in_void == true) {
            void_candidates.append(VoidCandidate(beginning: void_beginning, size: void_size))
        }

        let best_size = 0
        var best_candidate = VoidCandidate(beginning: -1, size: 0) // establishing a default value

        // Now, analyze all candidates to determine which one should become designated as the void
        for candidate in void_candidates {
            if (candidate.size >= best_size) {
                best_candidate = candidate
            }
        }

        return best_candidate
    }
    
    /**
     A helper structure. When analyzing a long IPv6 address with multiple hextets that are zero, we indicate each one as a candidate to be "the void"
    - Parameters:
    - beginning: The index that this hextet can be found in for the IPv6 address that it belongs to
    - size: The number of hextets this void occupies. (The largest void will ultimately be selected to be "the void")
     */
    struct VoidCandidate {
        var beginning: Int
        var size: Int
    }
    
}


extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    
}
