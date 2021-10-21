
import Foundation
import CoreData

extension TextBlock {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextBlock> {
        return NSFetchRequest<TextBlock>(entityName: "TextBlock")
    }

    @NSManaged public var text: String?
    @NSManaged public var title: String?

}
