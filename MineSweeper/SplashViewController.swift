//
//  SplashViewController.swift
//  MineSweeper
//
//  Created by Federico Mireles on 25/03/24.
//

import UIKit

class SplashViewController: UIViewController {

    @IBOutlet weak var imvSplash: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        let w = 0.8 * view.frame.width

        let h = 0.43 * w

        let x = (view.frame.width - w)/2

        let y = -50.0// Empieza desde abajo de la vista

        imvSplash.frame = CGRect(x: x, y: y, width: w, height: h)

        imvSplash.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool){
        UIView.animate(withDuration: 2, delay: 0.5, options: .curveEaseOut, animations: {

            // Mueve la imagen hacia arriba
            self.imvSplash.frame.origin.y = (self.view.frame.height - self.imvSplash.frame.height)/2

            // Cambia la transparencia para que aparezca
            self.imvSplash.alpha = 1.0

        }, completion: { finished in
            // Animación completada
            // Mueve la imagen a la parte superior
            UIView.animate(withDuration: 0.5) {
                self.imvSplash.frame.origin.y = 100 // Cambia 50 a la posición que desees
            }

            // Podrías agregar más animaciones aquí si lo deseas

            // Una vez completada la segunda animación, realiza la transición
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.performSegue(withIdentifier: "sgSplash", sender: nil)
            }
        })
    }
}
