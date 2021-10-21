
import UIKit
import Speech
import AVFoundation

class PronounciationViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var userText: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var detectedTextView: UITextView!
    
    var numberOfWords: Int = 0
    var wordNumber: Int = 0
    var recognizedWorndNumber = 0
    var split: [String] = [""]
    var wordLenght: Int = 0
    var textCount: Int = 0
    var isRecording = false
    
    let audioEngine = AVAudioEngine()
    var timer: Timer?
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var player: AVAudioPlayer?
    var textFromFile: NSMutableAttributedString = NSMutableAttributedString()
    let synth = AVSpeechSynthesizer()
    var navigationTitle = ""
    
    //MARK: IBActions and Cancel
    @IBAction func pronounce(_ sender: UIButton) {
        synth.stopSpeaking(at: .immediate)
        if isRecording {
            stopRecognition()
        }
        if let range = userText.selectedTextRange,
           userText.text(in: range) != "" {
            let utterance = AVSpeechUtterance(string: userText.text(in: range)!)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            synth.speak(utterance)
        } else {
            let utterance = AVSpeechUtterance(string: necessaryWord(iteration: wordNumber))
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synth.speak(utterance)
        }
    }
    
    @IBAction func skipWord(_ sender: UIButton) {
        nextWord()
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        synth.stopSpeaking(at: .immediate)
        if isRecording == true {
            stopRecognition()
            self.playSound(with: "stopButton")
        } else {
            startRecognition()
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(stopRecognition), userInfo: nil, repeats: false)
        }
    }
    
    @IBAction func done() {
        audioEngine.stop()
        recognitionTask?.cancel()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioSession()
        self.title = navigationTitle
        navigationItem.largeTitleDisplayMode = .never
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute:    {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        })
        
        let systemStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let fileLength = textFromFile.string.utf16.count
        textFromFile.addAttributes(systemStyle, range: NSMakeRange(0, fileLength))
        userText.attributedText = textFromFile
        userText.bounces = false
        
        self.split = textFromFile.string.components(separatedBy: [" "])
        numberOfWords = split.count
        self.requestSpeechAuthorization()
        
        let down = UISwipeGestureRecognizer(target : self, action : #selector(downSwipe))
        down.direction = .down
        self.view.addGestureRecognizer(down)
        
        let up = UISwipeGestureRecognizer(target : self, action : #selector(upSwipe))
        up.direction = .up
        self.view.addGestureRecognizer(up)
        
       // startButton.imageView?.contentMode = .scaleToFill
       // startButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        
        let top = NSMakeRange(1, 1)
        userText.scrollRangeToVisible(top)
    }
    
    // MARK: Recognize Speech
    func startRecognition() {
        isRecording = true
        startButtonColor(with: .red)
        self.playSound(with: "startButton")
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                guard let anyTranscription = result.transcriptions.first?.formattedString else { return }
                
                let replacedText = anyTranscription.replacingOccurrences(of: "'s", with: " is")
                let splittedRecognizedWord = replacedText.split(separator: " ").map { String($0).lowercased() }
                
                let necessaryWord = self.necessaryWord(iteration: self.wordNumber).lowercased()
                let nextWord = self.nextWordInRow(word: necessaryWord)
                
                if splittedRecognizedWord.contains(nextWord) {
                    self.nextWord()
                }
                
                self.detectedTextView.text = anyTranscription
                let bottom = NSMakeRange(self.detectedTextView.text.count - 1, 1)
                self.detectedTextView.scrollRangeToVisible(bottom)
            }
        })
    }
    
    @objc func stopRecognition() {
        if let timer = timer {
            timer.invalidate()
        }
        startButtonColor(with: .black)
        isRecording = false
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionTask?.cancel()
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch _ {
            
        }
    }
    
    func startButtonColor(with color: UIColor) {
        let origImage = UIImage(named: "Micro");
        let tintedImage = origImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        startButton.setImage(tintedImage, for: .normal)
        startButton.tintColor = color
    }
    
    //MARK: Handle next word from document
    func nextWord() {
        let attributedString: NSMutableAttributedString = textFromFile
        if textCount < attributedString.length {
            textCount = textCount + split[wordNumber].utf16.count
            let boldStyle = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
            attributedString.addAttributes(boldStyle, range: NSMakeRange(0, textCount))
            userText.attributedText = attributedString
            if split.last! != split[wordNumber] {
                textCount = textCount + 1
                wordNumber = wordNumber + 1
            }
        }
    }
    
    // MARK: Check Authorization Status
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.startButton.isEnabled = true
                case .denied:
                    self.startButton.isEnabled = false
                    self.detectedTextView.text = "User denied access to speech recognition"
                case .restricted:
                    self.startButton.isEnabled = false
                    self.detectedTextView.text = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.startButton.isEnabled = false
                    self.detectedTextView.text = "Speech recognition not yet authorized"
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
    
    func necessaryWord(iteration: Int) -> String {
        return split[iteration]
    }
    
    // MARK:  Alert
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func playSound(with name: String) {
        let path = Bundle.main.path(forResource: name, ofType : "mp3")!
        let url = URL(fileURLWithPath : path)
        do{
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print ("file could not be loaded or other error!")
        }
    }
    
    func nextWordInRow(word: String) -> String {
        return word.removeCharacters(from: CharacterSet.alphanumerics.inverted)
    }
    
    func documentsDirectoryURL() -> URL
    {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    @objc func upSwipe(){
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func downSwipe(){
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}

extension String {
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
    
    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
}
