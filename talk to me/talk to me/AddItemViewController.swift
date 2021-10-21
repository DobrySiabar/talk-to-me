
import UIKit
import CoreData

enum fileAtrribute {
    case fileName
    case fileExtension
}

class AddItemViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Put your text files along this path:")
        print(documentsDirectoryURL())
        tableView.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        tableView.separatorStyle = .none
        tableView.bounces = false
        navigationItem.largeTitleDisplayMode = .never
        filesList = try! FileManager.default.contentsOfDirectory(atPath: documentsDirectoryURL().path)
    }

    var managedContext: NSManagedObjectContext!
    var filesList = [String]()
    var segueAllowed: [Bool] = []
    var attributedText: NSAttributedString = NSMutableAttributedString(string: "")

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        segueAllowed.append(false)
        let labelText = cell.textLabel
        let text = filesList[indexPath.row]
        let file = fileSeparation(for: text)
        let nameOfFile = file[.fileName]!
        let fileExtension = file[.fileExtension]!
        var attributedString = NSMutableAttributedString(string: nameOfFile)
        if fileExtension != "txt" && fileExtension !=  "rtf" {
            segueAllowed.removeLast()
            segueAllowed.append(true)
            let italicStyle = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 17)]
            attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttributes(italicStyle, range: NSMakeRange(0, text.count))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, text.count))
        }
        labelText?.attributedText = attributedString
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segueAllowed[indexPath.row] == false {
            let cell = tableView.cellForRow(at: indexPath)
            
            guard let textTitle = cell?.textLabel?.text else { return }
            let value = readTheFile(fileName: filesList[indexPath.row]).string
            
            let entity = NSEntityDescription.entity(forEntityName: "TextBlock", in: managedContext)!
            
            let text = NSManagedObject(entity: entity, insertInto: managedContext)
            
            text.setValue(textTitle, forKeyPath: "title")
            text.setValue(value, forKeyPath: "text")
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func documentsDirectoryURL() -> URL
    {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func readTheFile(fileName: String) -> NSMutableAttributedString {
        var attributedStringWithRtf = NSMutableAttributedString(string: "")
        let file = fileSeparation(for: fileName)
        var inString = ""
        let nameOfFile = file[.fileName]!
        let fileExtension = file[.fileExtension]!
        let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if let fileURL = dir?.appendingPathComponent(nameOfFile).appendingPathExtension(fileExtension) {
            do {
                if fileExtension == "rtf" {
                    attributedStringWithRtf = try NSMutableAttributedString(url: fileURL, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
                } else if fileExtension == "txt" {
                    inString = try String(contentsOf: fileURL)
                    attributedStringWithRtf = NSMutableAttributedString(string: inString)
                }
            } catch {
                print("Failed reading from URL someFile: \(fileURL), Error: " + error.localizedDescription)
            }
        }
        return attributedStringWithRtf
    }
    
    func fileSeparation(for fileName: String) -> [fileAtrribute: String] {
        var nameOfFile = ""
        var fileExtension = ""
        var components = fileName.components(separatedBy: ".")
        if components.count > 1 {
            fileExtension = components.removeLast()
            nameOfFile = components.joined(separator: ".")
        } else {
            fileExtension = fileName
        }
        let key: [fileAtrribute: String] = [
            .fileName : nameOfFile,
            .fileExtension : fileExtension
        ]
        return key
    }
}
