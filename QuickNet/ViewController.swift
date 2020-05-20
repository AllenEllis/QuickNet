//
//  ViewController.swift
//  QuickNet
//
//  Created by Allen Ellis on 5/7/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Cocoa

class ViewController: NSViewController
{
//    @IBOutlet weak var nameField: NSTextField!
//    @IBOutlet weak var helloLabel: NSTextField!
    
    @IBOutlet weak var ip_input: NSTextField!
    
    @IBOutlet weak var host_network: NSTextField!
    @IBOutlet weak var host_first_host: NSTextFieldCell!
    @IBOutlet weak var host_last_host: NSTextFieldCell!
    @IBOutlet weak var host_broadcast: NSTextFieldCell!
    @IBOutlet weak var host_usable: NSTextField!
    @IBOutlet weak var host_condensed: NSTextFieldCell!
    @IBOutlet weak var host_integer: NSTextFieldCell!
    
    
    @IBOutlet weak var cidr_notation: NSTextFieldCell!
    @IBOutlet weak var netmask: NSTextFieldCell!
    @IBOutlet weak var wildcard_mask: NSTextFieldCell!
    @IBOutlet weak var netbox_status: NSTextFieldCell!
    
    
    
    @IBOutlet weak var host_row_network: NSGridRow!
    @IBOutlet weak var host_row_broadcast: NSGridRow!
    @IBOutlet weak var host_row_usable: NSGridRow!
    @IBOutlet weak var host_row_condensed: NSGridRow!
    
    // Buttons
    @IBOutlet weak var shareButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var prevButton: NSButton!
    
    @IBOutlet var tableView: NSTableView!
    
    var data: [[String: String]] = [[:]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.sendAction(on: .leftMouseDown)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - IBActions - buttons
    
    @IBAction func enterButtonPressed(_ sender: Any) {
        doCalc()
    }
    @IBAction func goButtonClicked(_ sender: Any) {
        doCalc()
    }
    
    @IBAction func prevButtonClicked(_ sender: Any) {
        goToPrevious()
    }
    
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        goToNext()
    }
    
    @IBAction func shrinkButtonClicked(_ sender: Any) {
        decreaseMaskSize()
    }
    
    @IBAction func growButtonClicked(_ sender: Any) {
        increaseMaskSize()
    }
    
    @IBAction func shareButtonClicked(_ sender: NSButton) {
        let text = ip_input.stringValue
        let sharingPicker = NSSharingServicePicker(items: [text])
        
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    func setClipboard(text: String) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.setString(text, forType: .string)
    }

    
    
    // MARK: - IBActions - menus

    @IBAction func IncreaseMaskSizeMenuItemSelected(_ sender: Any) {
      increaseMaskSize()
    }

    @IBAction func DecreaseMaskSizeMenuItemSelected(_ sender: Any) {
      decreaseMaskSize()
    }

    @IBAction func GoToNextMenuItemSelected(_ sender: Any) {
//      goToNext()
        
//        nextButton.sendAction(on: .leftMouseDown)
//        nextButton.
    }
    
    @IBAction func GoToPreviousMenuItemSelected(_ sender: Any) {
//      goToPrevious()
        prevButton.sendAction(on: .leftMouseDown)
    }
    
    func increaseMaskSize() {
        let ip_obj = ip_view(ip_input: ip_input.stringValue)
        
        // determine the next highest prefix size
        var new_size = ip_obj.network_size + 1
        
        if(ip_obj.detect_ipv_type() == "4" && new_size > 32)
        {
            new_size = 32 // don't allow IPv4 to go higher than a /32
        }
        
        let new_ip = ip_obj.ip_addr_str
        
        let new_ip_input = "\(new_ip)/\(new_size)"
        
        ip_input.stringValue = new_ip_input
        
        doCalc()
    }
    
    func decreaseMaskSize() {
        let ip_obj = ip_view(ip_input: ip_input.stringValue)

        // determine the next lowest prefix size
        var new_size = ip_obj.network_size - 1
        
        if(new_size < 0)
        {
            new_size = 0 // don't allow any address to go lower than a /0
        }
        
        let new_ip = ip_obj.ip_addr_str
        
        let new_ip_input = "\(new_ip)/\(new_size)"
        
        ip_input.stringValue = new_ip_input
        
        doCalc()
    }
    
    func goToNext() {
        let ip_obj = ip_view(ip_input: ip_input.stringValue)
        
        // determine the next network input
        let new_ip = ip_obj.next_network
        let new_size = ip_obj.network_size
        let new_ip_input = "\(new_ip)/\(new_size)"

        ip_input.stringValue = new_ip_input
        
        doCalc()
    }
    
    func goToPrevious() {
        let ip_obj = ip_view(ip_input: ip_input.stringValue)
        
        // determine the next network input
        let new_ip = ip_obj.prev_network
        let new_size = ip_obj.network_size
        let new_ip_input = "\(new_ip)/\(new_size)"

        ip_input.stringValue = new_ip_input
        
        doCalc()
    }
    
    func doCalc() {
        let ip_obj = ip_view(ip_input: ip_input.stringValue)
        
        if(ip_obj.ipv_type == "0")
        {
            showAlert(messageText: "Please enter a valid query", informativeText: "Examples include:\n10.0.0.1\n10.0.0.1/8\n10.0.0.1/255.0.0.0\n10.0.0.1/255.255.255.0\n\nIPv6:\n2001:db8::\n2001:db8::/32")
            return
            // todo: fail for user with error message
        }
        
        if(ip_obj.ipv_type == "4")
        {
            process4(ip_obj: ip_obj)
        }
        
        if(ip_obj.ipv_type == "6")
        {
            process6(ip_obj: ip_obj)
        }
        
        process(ip_obj: ip_obj)
    }
    
    func showAlert(messageText: String="Invalid IP address", informativeText: String="Something was invalid") {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!) { (response) in
        }
    }
    
    func process4(ip_obj: ip_view) {
        // hide the v6 cells
        host_row_network.isHidden = false
        host_row_broadcast.isHidden = false
        host_row_usable.isHidden = false
        host_row_condensed.isHidden = true
        
        // drop in the new text data
        host_network.stringValue = ip_obj.host_network
        host_first_host.stringValue = ip_obj.host_first_host
        host_last_host.stringValue = ip_obj.host_last_host
        host_broadcast.stringValue = ip_obj.host_broadcast
        host_usable.stringValue = String(ip_obj.host_usable_hosts)
        host_integer.stringValue = String(ip_obj.host_integer)
        
        cidr_notation.stringValue = ip_obj.cidr_notation
        netmask.stringValue = ip_obj.netmask
        
        netbox_status.stringValue = "Processing..."
        ip_obj.getNetboxStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.netbox_status.stringValue = ip_obj.netbox_status
//            self.netbox_status.attr
//                = ip_obj.netbox_status
        })
        

//        wildcard_mask.stringValue = ip_obj.wildcard_mask
        
        
        

    }
    
    func process6(ip_obj: ip_view) {
        // hide the v6 cells
        host_row_network.isHidden = true
        host_row_broadcast.isHidden = true
        host_row_usable.isHidden = true
        host_row_condensed.isHidden = false
        
        // drop in the new text data
        host_first_host.stringValue = ip_obj.host_first_host
        host_last_host.stringValue = ip_obj.host_last_host
        host_condensed.stringValue = ip_obj.host_condensed

        host_integer.stringValue = String(ip_obj.host_integer)
        cidr_notation.stringValue = ip_obj.cidr_notation

        
        tableView.reloadData()
        
 
    }
    
    func process(ip_obj: ip_view) {
//        data = [
//         [
//          "subnet" : "2620:13d::",
//          "prefix" : "/32",
//          "count" : "1",
//          "example" : "Service Provider",
//         ],
//         [
//           "subnet" : "2620:13d:f000::",
//           "prefix" : "/36",
//           "count" : "16",
//           "example" : "Data Center",
//          ],
//         [
//           "subnet" : "2620:13d:ff00::",
//           "prefix" : "/40",
//           "count" : "256",
//           "example" : "Region",
//          ],
//         [
//           "subnet" : "2620:13d:ff00::",
//           "prefix" : "/44",
//           "count" : "4096",
//           "example" : "Campus",
//          ]
//        ]
        data = ip_obj.subnet_data
        tableView.reloadData()
    }
    
//    @IBAction func sayButtonClicked(_ sender: Any) {
//        var name = nameField.stringValue
//        if name.isEmpty {
//            name = "World"
//        }
//        let greeting = "Hello \(name)!"
//        helloLabel.stringValue = greeting
//    }
    


    
}



// MARK: Other Functions
extension ViewController: NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: NSImage.Name("copy")) else {
            return proposedServices
        }
        
        var share = proposedServices
        let customService = NSSharingService(title: "Copy Text", image: image, alternateImage: image, handler: {
            if let text = items.first as? String {
                self.setClipboard(text: text)
            }
        })
        share.insert(customService, at: 0)
        
        return share
    }
}


extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (data.count)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let person = data[row]

        guard let cell = tableView.makeView(
            withIdentifier: tableColumn!.identifier,
            owner: self)
            as? NSTableCellView else
        {
                return nil
                
        }
        if(person[tableColumn!.identifier.rawValue] == nil) {
            NSLog("It was nill")
            cell.textField?.stringValue = ""
        }
        else
        {
            cell.textField?.stringValue = person[tableColumn!.identifier.rawValue]!
        }
        
//

        return cell
    }
    
    
//    // Code that was supposed to allow copy & paste in table views. Didn't throw any errors but also didn't work
//    // https://stackoverflow.com/a/44989449/7560156
//
//    func tableView(_ tableView: NSTableView, canPerformAction action:
//    Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
//        if (action.description == "copy:") {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    func tableView(_ tableView: NSTableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
//        if (action.description == "copy:") {
//            //...
//        }
//    }
//
//    func tableView(_ tableView: NSTableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//
}


