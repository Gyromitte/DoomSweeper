//
//  RecordsViewController.swift
//  MineSweeper
//
//  Created by Ricardo A Gallegos Rodríguez on 05/04/24.
//

import UIKit

class RecordsViewController: UIViewController {

    @IBOutlet weak var recordsLabel: UILabel!
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            
            // Cargar los registros y mostrar los 5 mejores
            let playerRecords = loadPlayerRecords()
            let topRecords = playerRecords.prefix(5)
            
            // Formatear los registros para mostrarlos en el label
            var recordsText = ""
            for (index, record) in topRecords.enumerated() {
                let playerName = record["name"] as? String ?? ""
                let score = record["score"] as? Int ?? 0
                recordsText += "\(index + 1). \(playerName): \(score)\n"
            }
            
            // Asignar el texto al label
            recordsLabel.text = recordsText
        }
        
        // Función para cargar los registros desde PlayerRecords.plist
        func loadPlayerRecords() -> [[String: Any]] {
            if let plistURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("PlayerRecords.plist"),
               let playerRecords = NSArray(contentsOf: plistURL) as? [[String: Any]] {
                return playerRecords
            }
            return []
        }
    }
