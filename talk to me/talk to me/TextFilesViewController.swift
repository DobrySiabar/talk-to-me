
import UIKit
import CoreData

class TextFilesViewController: UIViewController {
    
    lazy var coreDataStack = CoreDataStack(modelName: "Texts")
    var managedContext: NSManagedObjectContext!
    var texts = [TextBlock]()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .none
        tableView.bounces = false

        // tableView.backgroundColor = #colorLiteral(red: 0.109739773, green: 0.1097101346, blue: 0.1181967035, alpha: 1)
        title = "talk to me"

        //tableView.backgroundColor = #colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1)
        view.backgroundColor = .black
        managedContext = coreDataStack.managedContext
        insertSampleData()
    }

    @IBAction func performSegue(_ sender: UIBarButtonItem) {
        let controller = AddItemViewController()
        controller.managedContext = managedContext
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Pronounciation",
           let indexPath = tableView.indexPathForSelectedRow {
            let controller = segue.destination as! PronounciationViewController
            guard let text = texts[indexPath.row].text else { return }
            let attributedText = NSMutableAttributedString(string: text)
            controller.navigationTitle = texts[indexPath.row].title!
            controller.textFromFile = attributedText
        }
        if segue.identifier == "AddItem" {
            let controller = segue.destination as! AddItemViewController
            controller.managedContext = managedContext
        }
    }
    
    // Insert sample data
    func insertSampleData() {
        let fetch: NSFetchRequest<TextBlock> = TextBlock.fetchRequest()
        fetch.predicate = NSPredicate(format: "title != nil")
        
        let itemCount = (try? managedContext.count(for: fetch)) ?? 0
        
        if itemCount > 0 {
            // SampleData.plist data already in Core Data
            return
        }
        
        let path = Bundle.main.path(forResource: "SampleData", ofType: "plist")
        let dataArray = NSArray(contentsOfFile: path!)!
        
        for dict in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "TextBlock", in: managedContext)!
            let text = TextBlock(entity: entity, insertInto: managedContext)
            let btDict = dict as! [String: Any]
            
            text.title = btDict["title"] as? String
            text.text = btDict["text"] as? String
            texts.append(text)
          
        }
        try? managedContext.save()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
      //  configureNavigationBar(largeTitleColor: .white, backgoundColor: .red, tintColor: .white, title: "YourTitle", preferredLargeTitle: true)
        navigationItem.largeTitleDisplayMode = .always
        
        let fetchRequest = NSFetchRequest<TextBlock>(entityName: "TextBlock")
        do {
            texts = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }
    
}

extension TextFilesViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
        cell.textLabel?.text = texts[indexPath.row].title
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "Pronounciation", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let textToRemove = texts[indexPath.row]
        coreDataStack.managedContext.delete(textToRemove)
        coreDataStack.saveContext()
        texts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
}
