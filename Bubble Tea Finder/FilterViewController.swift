/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreData

// protocol for a delegate. The delegate will will implement the methods of the protocol. The methods, once implemented, can be passed some information
protocol FilterViewControllerDelegate: class {
  func filterViewController(
    filter: FilterViewController,
    didSelectPredicate predicate: NSPredicate?,
    sortDescriptor: NSSortDescriptor?)
}

class FilterViewController: UITableViewController {

  @IBOutlet weak var firstPriceCategoryLabel: UILabel!
  @IBOutlet weak var secondPriceCategoryLabel: UILabel!
  @IBOutlet weak var thirdPriceCategoryLabel: UILabel!
  @IBOutlet weak var numDealsLabel: UILabel!

  // MARK: - Price section
  @IBOutlet weak var cheapVenueCell: UITableViewCell!
  @IBOutlet weak var moderateVenueCell: UITableViewCell!
  @IBOutlet weak var expensiveVenueCell: UITableViewCell!

  // MARK: - Most popular section
  @IBOutlet weak var offeringDealCell: UITableViewCell!
  @IBOutlet weak var walkingDistanceCell: UITableViewCell!
  @IBOutlet weak var userTipsCell: UITableViewCell!
  
  // MARK: - Sort section
  @IBOutlet weak var nameAZSortCell: UITableViewCell!
  @IBOutlet weak var nameZASortCell: UITableViewCell!
  @IBOutlet weak var distanceSortCell: UITableViewCell!
  @IBOutlet weak var priceSortCell: UITableViewCell!
  
  // MARK: - Properties
  var coreDataStack: CoreDataStack!
  // we delcare our delegate for this class to be FilterViewController
  weak var delegate: FilterViewControllerDelegate?
  var selectedSortDescriptor: NSSortDescriptor? // hold reference to currently selected descriptor
  var selectedPredicate: NSPredicate? // hold reference to predicate
  
  // lazy predicate (inits when var is called)
  lazy var cheapVenuePredicate: NSPredicate = {
    return NSPredicate(format: "%K == %@", // calculate number of venues in the $ (lowest) prices category
                       #keyPath(Venue.priceInfo.priceCategory), "$")
  }()
  lazy var moderateVenuePredicate: NSPredicate = {
    return NSPredicate(format: "%K == %@", // calculate number of venues with price $$
                       #keyPath(Venue.priceInfo.priceCategory), "$$")
  }()
  lazy var expensiveVenuePredicate: NSPredicate = { // predicate is to return venues with price info of $$$
    return NSPredicate(format: "%K == %@",
                       #keyPath(Venue.priceInfo.priceCategory), "$$$")
  }()
  // predicate to return venues objects with specialCount count greater than 0
  lazy var offeringDealPredicate: NSPredicate = {
    return NSPredicate(format: "%K > 0",
                       #keyPath(Venue.specialCount))
  }()
  lazy var walkingDistancePredicate: NSPredicate = {
    return NSPredicate(format: "%K < 500",
                       #keyPath(Venue.location.distance))
  }()
  lazy var hasUserTipsPredicate: NSPredicate = {
    return NSPredicate(format: "%K > 0",
                       #keyPath(Venue.stats.tipCount))
  }()
  // NSSortDescriptors for sorting
  lazy var nameSortDescriptor: NSSortDescriptor = {
    let compareSelector =
      #selector(NSString.localizedStandardCompare(_:))
    return NSSortDescriptor(key: #keyPath(Venue.name), ascending: true,
                            selector: compareSelector)
  }()
  lazy var distanceSortDescriptor: NSSortDescriptor = {
    return NSSortDescriptor(
      key: #keyPath(Venue.location.distance),
      ascending: true)
  }()
  lazy var priceSortDescriptor: NSSortDescriptor = {
    return NSSortDescriptor(
      key: #keyPath(Venue.priceInfo.priceCategory),
      ascending: true)
  }()

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // populate the total number of each $, $$, $$$ for all the restaurants
    populateCheapVenueCountLabel()
    populateModerateVenueCountLabel()
    populateExpensiveVenueCountLabel()
    // find the totals number of deals from all the restaurants
    populateDealsCountLabel()
  }
}

// MARK: - IBActions
extension FilterViewController {

  // when search is tapped, this method is then told to run
  @IBAction func search(_ sender: UIBarButtonItem) {
    delegate?.filterViewController( // notify our delegate of our selection
      filter: self,
      didSelectPredicate: selectedPredicate, // selectedPredicate choosen based on the cell selected
      sortDescriptor: selectedSortDescriptor) // selectedSortDescriptor set depending on user tapped cell. Passed sort descriptor to delegate that will implement this method
    dismiss(animated: true)
  }
}

// MARK - UITableViewDelegate
extension FilterViewController {

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // when user taps a cell we get the cell at the rows index path
    guard let cell = tableView.cellForRow(at: indexPath) else {
      return
    }
    // Price section
    switch cell { // switch based on cell selected
    case cheapVenueCell: // if cheapVenuecell is selected, we set selectedPredicate as cheap venue one. we know the cell selected from iboutlet reference
      selectedPredicate = cheapVenuePredicate
    // Price Section
    case moderateVenueCell:
      selectedPredicate = moderateVenuePredicate
    case expensiveVenueCell:
      selectedPredicate = expensiveVenuePredicate
      
    // Most Popular section
    case offeringDealCell: // if the cell selected is linked to outlet offeringDealCell, set the corresponding predicate that is offerDealPredicate to the current selectedPredicate
      selectedPredicate = offeringDealPredicate
    case walkingDistanceCell:
      selectedPredicate = walkingDistancePredicate
    case userTipsCell:
      selectedPredicate = hasUserTipsPredicate
      
    // Sort By section
    case nameAZSortCell:
      selectedSortDescriptor = nameSortDescriptor
    case nameZASortCell:
      selectedSortDescriptor =
        nameSortDescriptor.reversedSortDescriptor
        as? NSSortDescriptor
    case distanceSortCell:
      selectedSortDescriptor = distanceSortDescriptor
    case priceSortCell:
      selectedSortDescriptor = priceSortDescriptor
      
    default: break
    }
    cell.accessoryType = .checkmark
  }
}

// MARK: - Helper methods
extension FilterViewController {
  func populateCheapVenueCountLabel() {
    let fetchRequest = // create a fetch request on the entity "Venue"
      NSFetchRequest<NSNumber>(entityName: "Venue") // expecting NSNumber because using .countResult
    fetchRequest.resultType = .countResultType // Request returns the count of the objects that match the request.
    fetchRequest.predicate = cheapVenuePredicate // predicate to return only $ places
    do {
      let countResult =
        try coreDataStack.managedContext.fetch(fetchRequest) // do the fetch on the managedContext
      let count = countResult.first!.intValue // looking at total $ places, i.e. 27 places with $
      let pluralized = count == 1 ? "place" : "places"
      firstPriceCategoryLabel.text = // set the label with count returned on fetch
      "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("Count not fetch \(error), \(error.userInfo)")
    }
  }
  // populate the moderate label with $$ price
  func populateModerateVenueCountLabel() {
    let fetchRequest =
      NSFetchRequest<NSNumber>(entityName: "Venue")
    fetchRequest.resultType = .countResultType // return count of objects
    fetchRequest.predicate = moderateVenuePredicate // predicate to return venue of objs priced $$
    do {
      let countResult =
        try coreDataStack.managedContext.fetch(fetchRequest)
      let count = countResult.first!.intValue
      let pluralized = count == 1 ? "place" : "places"
      secondPriceCategoryLabel.text =
      "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("Count not fetch \(error), \(error.userInfo)")
    }
  }
  // populate the thirdPriceCategoryLabel text with count of $$$ venue objects
  func populateExpensiveVenueCountLabel() {
    let fetchRequest: NSFetchRequest<Venue> = Venue.fetchRequest()
    fetchRequest.predicate = expensiveVenuePredicate
    do {
      let count =
        try coreDataStack.managedContext.count(for: fetchRequest) // alternate way uses managed context's count
      let pluralized = count == 1 ? "place" : "places"
      thirdPriceCategoryLabel.text =
      "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("Count not fetch \(error), \(error.userInfo)")
    }
  }
  func populateDealsCountLabel() {
    // 1
    let fetchRequest =
      NSFetchRequest<NSDictionary>(entityName: "Venue") // fetch type is on Venue objects
    fetchRequest.resultType = .dictionaryResultType // expect to return dictionaries
    // 2
    let sumExpressionDesc = NSExpressionDescription() // request the sum
    sumExpressionDesc.name = "sumDeals"
    // 3
    let specialCountExp =
      NSExpression(forKeyPath: #keyPath(Venue.specialCount))
    sumExpressionDesc.expression =
      NSExpression(forFunction: "sum:", //want the sum: function to sum over venue objs specialCount
                   arguments: [specialCountExp])
    sumExpressionDesc.expressionResultType =  // return int
      .integer32AttributeType
    // 4
    fetchRequest.propertiesToFetch = [sumExpressionDesc] // tell original fetch request to fetch the sum specified in sumExpressionDesc
    // 5
    // when managed context goes to do the fetch it is set to search for specialCount attribute from the venues object, and get the total sum of deals
    do {
      let results =
        try coreDataStack.managedContext.fetch(fetchRequest) // make the fetch req on the managedcontext
      let resultDict = results.first! // get first element of results array, which is a dictionary
      let numDeals = resultDict["sumDeals"] as! Int // get the specialCount result by calling the index of the dictionary "sumDeals" which ix sumExpressionDesc which was propertiestoFetch for fetchRequest
      let pluralized = numDeals == 1 ?  "deal" : "deals"
      numDealsLabel.text = "\(numDeals) \(pluralized)"
    } catch let error as NSError {
      print("Count not fetch \(error), \(error.userInfo)")
    }
  }
}
