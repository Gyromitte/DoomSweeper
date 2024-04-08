import UIKit
import AVFoundation

class GameViewController: UIViewController {
    var audioPlayer: AVAudioPlayer?
    var backgroundMusicPlayer: AVAudioPlayer?
    var timer: Timer?
    var elapsedTime: Int = 0
    var mines: [Mine] = []
    var minesQnty: Int = 0
    var cellsToReveal: Set<Int> = []
    var scoreAcumulator: Int = 0
    var playerName: String?
    
    @IBOutlet weak var score: UIButton!
    @IBOutlet weak var imvBackground: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imvFace: UIImageView!
    @IBOutlet weak var btnTimer: UIButton!
    
    @IBOutlet weak var secretButton: UIButton!
    let mineImages = [UIImage(named: "Tile.jpg"), UIImage(named: "Mine.jpg"), UIImage(named: "Tile_Revealed.jpg"),
                      UIImage(named: "one.jpg"), UIImage(named: "two.jpg"), UIImage(named: "three.jpg"),
                      UIImage(named: "four.jpg"), UIImage(named: "five.jpg"), UIImage(named: "six.jpg"),
                      UIImage(named: "seven.jpg"), UIImage(named: "eight.jpg")]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self

        let nib = UINib(nibName: "MineCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: MineCell.identifier)
        
        let images = [UIImage(named: "Left")!, UIImage(named: "Front")!, UIImage(named: "Right")!]
        imvFace.animationImages = images
        imvFace.animationDuration = 3.0
        imvFace.animationRepeatCount = 0
        imvFace.startAnimating()
        collectionView.reloadData()
        playOSTMusic()
        
        secretButton.addTarget(self, action: #selector(secetButtonPressed(_:)), for: .touchUpInside)
    }
    
    @IBAction func secetButtonPressed(_ sender: UIButton) {
        print("Hola")
        for mine in mines {
            let index = mine.x * 10 + mine.y
            if !(cellsToReveal.contains(index)) {
                if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MineCell {
                    cell.imageCell.image = UIImage(named: "Mine.jpg")
                }
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showPopUp()
    }
    
    func showPopUp() {
        print("Showing pop-up")
        let alertController = UIAlertController(title: "Select difficulty",
                                                message: "Choose between 10 to 20 bombs",
                                                preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Number of bombs"
            textField.keyboardType = .numberPad
        }

        let acceptAction = UIAlertAction(title: "A-ok!", style: .default) { [weak self] (action) in
            if let textField = alertController.textFields?.first,
               let bombasStr = textField.text,
               let numberBombs = Int(bombasStr),
               numberBombs >= 10, numberBombs <= 20 {
                self?.startTimer()
                self?.minesQnty = numberBombs
                print("Bombs selected: \(numberBombs)")
            } else {
                self?.showError()
            }
        }
        alertController.addAction(acceptAction)
        present(alertController, animated: true, completion: nil)
    }

    func showError() {
        let errorAlert = UIAlertController(title: "Error",
                                           message: "U dumb?. That's not between 10 to 20 bombs.",
                                           preferredStyle: .alert)
        let okAction = UIAlertAction(title: "I'm a lil bit slow", style: .default, handler: { (_) in
            self.showPopUp()
        })
        errorAlert.addAction(okAction)
        present(errorAlert, animated: true, completion: nil)
    }
    
    func startTimer() {
        // Remove red overlay
        if let redOverlayView = imvBackground.subviews.first(where: { $0.backgroundColor == UIColor.red.withAlphaComponent(0.5) }) {
            redOverlayView.removeFromSuperview()
        }
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.elapsedTime += 1
            self?.updateTimerButton()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func updateTimerButton() {
        DispatchQueue.main.async { [weak self] in
            guard let time = self?.elapsedTime else { return }
            
            let minutes = time / 60
            let seconds = time % 60
            
            let formattedTime = String(format: "%02d:%02d", minutes, seconds)
            self?.btnTimer.setTitle("\(formattedTime)", for: .normal)
        }
    }
    
    @objc func botonCeldaPresionado(_ sender: UIButton) {
        imvBackground.image = UIImage(named: "BGShoot")
        reproducirSonido("pistol")
        
        guard let cell = sender.superview?.superview as? MineCell,
              let indexPath = collectionView.indexPath(for: cell) else {
            print("Error: No se pudo obtener la celda o el indexPath")
            return
        }
        
        if mines.isEmpty {
            placeMines()
            print(mines)
        }
        
        let row = indexPath.row / 10
        let column = indexPath.row % 10
        
        if cellsToReveal.contains(indexPath.row) {
            return // Cell already revealed
        }
        
        if let index = mines.firstIndex(where: { $0.x == row && $0.y == column }) {
            // Selected cell is a mine
            cell.imageCell.image = UIImage(named: "Mine.jpg")
            gameOver()
        } else {
            let numMines = calculateAdjacentMines(row: row, column: column)
            cellsToReveal.insert(indexPath.row)
            cell.imageCell.image = mineImages[numMines + 2]
            
            // Update Score based on adjacent mines
            scoreAcumulator += (numMines + 1) * 10 // Increase score based on adjacent mines
            score.setTitle("\(scoreAcumulator)", for: .normal)
            
            if numMines == 0 {
                // Reveal empty cells recursively
                revealCellsRecursively(row: row, column: column)
            }
            
            // Return background to normal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.imvBackground.image = UIImage(named: "Title Background")
            }
            
            // Check for game win condition
            if cellsToReveal.count == 100 - minesQnty {
                gameWon()
            }
        }
    }

    func revealCellsRecursively(row: Int, column: Int) {
        for r in (row - 1)...(row + 1) {
            for c in (column - 1)...(column + 1) {
                if r >= 0 && r < 10 && c >= 0 && c < 10 {
                    let index = r * 10 + c
                    if !cellsToReveal.contains(index) {
                        cellsToReveal.insert(index)
                        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MineCell {
                            let numMines = calculateAdjacentMines(row: r, column: c)
                            cell.imageCell.image = mineImages[numMines + 2]
                            scoreAcumulator += (numMines + 1) * 10 // Update score for each revealed cell
                            score.setTitle("\(scoreAcumulator)", for: .normal)
                            if numMines == 0 {
                                // Recur for empty cells
                                revealCellsRecursively(row: r, column: c)
                            }
                        }
                    }
                }
            }
        }
    }

    
    func gameOver() {
        // Calculate final score
        let elapsedTimeDouble = Double(elapsedTime)
        let difficultyBooster = Double(minesQnty) * 2
        let scorePenalty = Int(elapsedTimeDouble * 1.5)
        
        // Calculate final score with difficulty bonus
        let finalScore = scoreAcumulator - scorePenalty + Int(difficultyBooster)
        print("Elapsed Time: \(elapsedTime)")
        print("Score Penalty: \(scorePenalty)")
        print("Final Score: \(finalScore)")
        stopTimer()
        // Add red overlay
        let redOverlayView = UIView(frame: imvBackground.bounds)
        redOverlayView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        imvBackground.addSubview(redOverlayView)
        reproducirExplosion("explosion")
        imvFace.stopAnimating()
        imvFace.image = UIImage(named: "Exploded")
        
        // Delay for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.playScoreMusic()
            self?.imvFace.stopAnimating()
            self?.reproducirSonido("death")
            self?.imvFace.image = UIImage(named: "Dead")
            
            // Reveal remaining mines
            for mine in self?.mines ?? [] {
                let index = mine.x * 10 + mine.y
                if !(self?.cellsToReveal.contains(index) ?? false) {
                    if let cell = self?.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MineCell {
                        cell.imageCell.image = UIImage(named: "Mine.jpg")
                    }
                }
            }
            
            // Show Game Over Pop-up
            self?.showGameOverPopup(score: finalScore)
            
            // Save player record
            if let playerName = self?.playerName {
                self?.savePlayerRecord(score: finalScore, playerName: playerName)
            }
        }
    }


    func gameWon() {
        stopTimer()
        playScoreMusic()
        imvFace.stopAnimating()
        imvFace.image = UIImage(named: "Win")
        
        // Calculate final score
        let elapsedTimeDouble = Double(elapsedTime)
        let difficultyBooster = Double(minesQnty) * 2
        let scorePenalty = Int(elapsedTimeDouble * 1.5)
        
        // Calculate final score with difficulty bonus
        let finalScore = scoreAcumulator - scorePenalty + Int(difficultyBooster)
        
        // Show Game Won Pop-up
        showGameWonPopup(score: finalScore)
        
        if let playerName = playerName {
            self.savePlayerRecord(score: finalScore, playerName: playerName)
        }
    }

    func showGameOverPopup(score: Int) {
        let gameOverAlert = UIAlertController(title: "Game Over",
                                              message: "Score: \(score)",
                                              preferredStyle: .alert)
        
        // Add text field for player name
        gameOverAlert.addTextField { (textField) in
            textField.placeholder = "Enter your name"
        }
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] (_) in
            if let playerName = gameOverAlert.textFields?.first?.text {
                self?.playerName = playerName // Set player name
                self?.savePlayerRecord(score: score, playerName: playerName)
            }
            self?.resetGame()
        }
        
        let quitAction = UIAlertAction(title: "Quit", style: .cancel) { [weak self] (_) in
            if let playerName = gameOverAlert.textFields?.first?.text {
                self?.playerName = playerName // Set player name
                self?.savePlayerRecord(score: score, playerName: playerName)
            }
            self?.dismiss(animated: true, completion: nil)
        }
        
        gameOverAlert.addAction(retryAction)
        gameOverAlert.addAction(quitAction)
        
        present(gameOverAlert, animated: true, completion: nil)
    }

    func showGameWonPopup(score: Int) {
        let gameWonAlert = UIAlertController(title: "Congratulations!",
                                             message: "Score: \(score)",
                                             preferredStyle: .alert)
        
        // Add text field for player name
        gameWonAlert.addTextField { (textField) in
            textField.placeholder = "Enter your name"
        }
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] (_) in
            if let playerName = gameWonAlert.textFields?.first?.text {
                self?.playerName = playerName // Set player name
                self?.savePlayerRecord(score: score, playerName: playerName)
            }
            self?.resetGame()
        }
        
        let quitAction = UIAlertAction(title: "Quit", style: .cancel) { [weak self] (_) in
            if let playerName = gameWonAlert.textFields?.first?.text {
                self?.playerName = playerName // Set player name
                self?.savePlayerRecord(score: score, playerName: playerName)
            }
            self?.dismiss(animated: true, completion: nil)
        }
        
        gameWonAlert.addAction(retryAction)
        gameWonAlert.addAction(quitAction)
        
        present(gameWonAlert, animated: true, completion: nil)
    }


    func resetGame() {
        // Reset game variables
        elapsedTime = 0
        mines = []
        minesQnty = 0
        cellsToReveal = []
        scoreAcumulator = 0
        score.setTitle("0", for: .normal)
        btnTimer.setTitle("00:00", for: .normal)
        
        // Reset UI
        for cell in collectionView.visibleCells {
            if let mineCell = cell as? MineCell {
                mineCell.imageCell.image = UIImage(named: "Tile.jpg")
            }
        }
        
        // Reset background and face images
        imvBackground.image = UIImage(named: "Title Background")
        imvFace.image = UIImage(named: "Front")
        
        // Restart music
        playOSTMusic()
        
        // Show difficulty selection
        showPopUp()
        
        
    }


    func revealEmptyCells(row: Int, column: Int) {
        for r in (row - 1)...(row + 1) {
            for c in (column - 1)...(column + 1) {
                if r >= 0 && r < 10 && c >= 0 && c < 10 {
                    let index = r * 10 + c
                    if !cellsToReveal.contains(index) {
                        cellsToReveal.insert(index)
                        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MineCell {
                            let numMines = calculateAdjacentMines(row: r, column: c)
                            cell.imageCell.image = mineImages[numMines + 2]
                            if numMines == 0 {
                                revealEmptyCells(row: r, column: c)
                            }
                        }
                    }
                }
            }
        }
    }

    func reproducirSonido(_ nombre: String) {
        guard let path = Bundle.main.path(forResource: nombre, ofType: "mp3") else {
            print("Sound file not found")
            return
        }

        do {
            let url = URL(fileURLWithPath: path)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
    }
    
    func reproducirExplosion(_ nombre: String) {
        guard let path = Bundle.main.path(forResource: nombre, ofType: "wav") else {
            print("Sound file not found")
            return
        }

        do {
            let url = URL(fileURLWithPath: path)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
    }
}

extension GameViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MineCell", for: indexPath) as? MineCell else {
            return UICollectionViewCell()
        }
        
        cell.btnCell.tag = indexPath.row
        cell.btnCell.addTarget(self, action: #selector(botonCeldaPresionado(_:)), for: .touchUpInside)
        
        return cell
    }
}

extension GameViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 10
        return CGSize(width: width, height: width)
    }
}

struct Mine {
    let x: Int
    let y: Int
}

extension GameViewController {
    func placeMines() {
        var minesPlaced = 0
        while minesPlaced < minesQnty {
            let randomX = Int.random(in: 0..<10)
            let randomY = Int.random(in: 0..<10)
            let newMine = Mine(x: randomX, y: randomY)
            if !mines.contains(where: { $0.x == randomX && $0.y == randomY }) {
                mines.append(newMine)
                minesPlaced += 1
            }
        }
    }
    
    func calculateAdjacentMines(row: Int, column: Int) -> Int {
        var count = 0
        for r in (row - 1)...(row + 1) {
            for c in (column - 1)...(column + 1) {
                if r >= 0 && r < 10 && c >= 0 && c < 10 {
                    if mines.contains(where: { $0.x == r && $0.y == c }) {
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    func playScoreMusic(){
        if let path = Bundle.main.path(forResource: "Score", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                print("Reproduciendo...")
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1 // -1 For infinite loop
                backgroundMusicPlayer?.prepareToPlay() // Prepare the audio player
                backgroundMusicPlayer?.play()
            } catch {
                print("Couldn't load the file: \(error)") // Print detailed error
            }
        } else {
            print("Sound file does not exist in main bundle")
        }
    }
    
    func playOSTMusic(){
        if let path = Bundle.main.path(forResource: "OST", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                print("Reproduciendo...")
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1 // -1 For infinite loop
                backgroundMusicPlayer?.prepareToPlay() // Prepare the audio player
                backgroundMusicPlayer?.play()
            } catch {
                print("Couldn't load the file: \(error)") // Print detailed error
            }
        } else {
            print("Sound file does not exist in main bundle")
        }
    }
}

// MARK: - Records
extension GameViewController {
    func savePlayerRecord(score: Int, playerName: String) {
        var playerRecords = loadPlayerRecords()
        let newRecord = ["type": "PlayerRecord", "name": playerName, "score": score] as [String: Any]
        playerRecords.append(newRecord)
        
        // Ordenar por puntuación descendente y mantener solo los primeros 5 registros
        playerRecords.sort { ($0["score"] as? Int ?? 0) > ($1["score"] as? Int ?? 0) }
        playerRecords = Array(playerRecords.prefix(5))
        
        // Guardar en PlayerRecords.plist en el directorio de documentos
        if let plistURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("PlayerRecords.plist") {
            (playerRecords as NSArray).write(to: plistURL, atomically: true)
            print("Guardado exitosamente en: \(plistURL)")
        } else {
            print("Error: No se pudo obtener la URL del archivo PlayerRecords.plist")
        }
    }

    func loadPlayerRecords() -> [[String: Any]] {
        // Cargar desde PlayerRecords.plist en el directorio de documentos
        if let plistURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("PlayerRecords.plist"),
           let playerRecords = NSArray(contentsOf: plistURL) as? [[String: Any]] {
            print("Cargado exitosamente desde: \(plistURL)")
            print("Registros cargados:")
            for record in playerRecords {
                if let name = record["name"] as? String, let score = record["score"] as? Int {
                    print("- \(name): \(score)")
                }
            }
            return playerRecords
        }
        print("Error: No se pudo cargar desde PlayerRecords.plist")
        return []
    }

}

struct PlayerRecord: Codable {
    var name: String
    var score: Int
}
