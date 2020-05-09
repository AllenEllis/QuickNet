//
//  ViewController.swift
//  HelloWorld
//
//  Created by Allen Ellis on 5/7/20.
//  Copyright © 2020 Friendship Creative. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
//    @IBOutlet weak var nameField: NSTextField!
//    @IBOutlet weak var helloLabel: NSTextField!
    
    @IBOutlet weak var ip_input: NSTextField!
    
    @IBOutlet weak var host_network: NSTextField!
    @IBOutlet weak var host_first_host: NSTextFieldCell!
    @IBOutlet weak var host_last_host: NSTextFieldCell!
    @IBOutlet weak var host_broadcast: NSTextFieldCell!
    @IBOutlet weak var host_usable: NSTextField!
    @IBOutlet weak var host_condensed: NSTextFieldCell!
    
    
    @IBOutlet weak var host_row_network: NSGridRow!
    @IBOutlet weak var host_row_broadcast: NSGridRow!
    @IBOutlet weak var host_row_usable: NSGridRow!
    @IBOutlet weak var host_row_condensed: NSGridRow!
    
    @IBOutlet var tableView: NSTableView!
    
    var data: [[String: String]] = [[:]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func enterButtonPressed(_ sender: Any) {
        doCalc()
    }
    @IBAction func goButtonClicked(_ sender: Any) {
        doCalc()
    }
    
    @IBAction func prevButtonClicked(_ sender: Any) {
    }
    
    
    @IBAction func nextButtonClicked(_ sender: Any) {
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
        host_usable.stringValue = ip_obj.host_usable_hosts
        

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
}
