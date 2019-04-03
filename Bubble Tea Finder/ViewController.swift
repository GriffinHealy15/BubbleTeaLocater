import UIKit
import CoreData

class ViewController: UIViewController {

  // MARK: - Properties
  private let filterViewControllerSegueIdentifier = "toFilterViewController"
  private let venueCellIdentifier = "VenueCell"

  var coreDataStack: CoreDataStack!
  var fetchRequest: NSFetchRequest<Venue>? // hold the fetch request
  var venues: [Venue] = [] // array of Venue objects you’ll use to populate the table view
  var asyncFetchRequest: NSAsynchronousFetchRequest<Venue>? // async fetch request

  // MARK: - IBOutlets
  @IBOutlet weak var tableView: UITableView!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let batchUpdate = NSBatchUpdateRequest(entityName: "Venue")
    batchUpdate.propertiesToUpdate =
      [#keyPath(Venue.favorite): true] // batch update to update Venue objects favorite attribute to 'true'
    batchUpdate.affectedStores = // affected stores is our persistent store coordinator’s persistentStores array
      coreDataStack.managedContext
        .persistentStoreCoordinator?.persistentStores
    batchUpdate.resultType = .updatedObjectsCountResultType // set the result type to be a count
    do {
      let batchResult =
        try coreDataStack.managedContext.execute(batchUpdate) //tell the context to do a batchupdate
          as! NSBatchUpdateResult
      print("Records updated \(batchResult.result!)") // print count of result which should be 30
    } catch let error as NSError {
      print("Could not update \(error), \(error.userInfo)")
    }
    
    // 1
    let venueFetchRequest: NSFetchRequest<Venue> =
    Venue.fetchRequest()
    fetchRequest = venueFetchRequest // create a fetch request
    // 2
    // aysnc fetch request is like a wrapper to a regular fetch request
    asyncFetchRequest = // create the async fetch request
      NSAsynchronousFetchRequest<Venue>(
      fetchRequest: venueFetchRequest) { // completion block to occur
        [unowned self] (result: NSAsynchronousFetchResult) in
        guard let venues = result.finalResult else {//fetched venues contained in result.finalResult
          return
        }
        self.venues = venues // set venues to self.venues (meaning this classes venues(array of venue objects)
        self.tableView.reloadData() // populate tableView with fetched venue objectts
    }
    // 3
    do {
      guard let asyncFetchRequest = asyncFetchRequest else {
        return
      }
      try coreDataStack.managedContext.execute(asyncFetchRequest) // tell managedContext to do an async fetch request
      // Returns immediately, cancel here if you want
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue,
                        sender: Any?) {
    guard segue.identifier == filterViewControllerSegueIdentifier, // if this is identifier attached to the segue, then were opening navigation controller
      let navController = segue.destination // put segue dest as navigation controller
        as? UINavigationController,
      let filterVC = navController.topViewController // put filterviewcontroller as top view of nav
        as? FilterViewController else {
          return
    }
    filterVC.coreDataStack = coreDataStack // pass the coreDataStack to the FilterViewController
    filterVC.delegate = self // declate us, ViewController.swift, as the delegate to filterVc, which is FilterViewController. So, ViewController.swift is the delegate for FilterViewController
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func unwindToVenueListViewController(_ segue: UIStoryboardSegue) {
  }
}

// MARK: - Helper methods
// fetches
extension ViewController {
  func fetchAndReload() {
    guard let fetchRequest = fetchRequest else {
      return
    }
    do { venues = // put fetch results (which is venue objs) in venue (an array of venue objs)
      try coreDataStack.managedContext.fetch(fetchRequest) // context fetches on data model "FetchRequest"
      tableView.reloadData()
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
  } }

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return venues.count // return the count of venue objects filled after the fetch
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: venueCellIdentifier, for: indexPath)
    let venue = venues[indexPath.row] // get the venue array and venue object at each index
    cell.textLabel?.text = venue.name // get the name of the venue object
    cell.detailTextLabel?.text = venue.priceInfo?.priceCategory // get the price category
    return cell // return the cell to the tableView
  }
}

// MARK: - FilterViewControllerDelegate
// we say we are the delegate of FilterViewController so we conform to its protocol and said protocols methods
extension ViewController: FilterViewControllerDelegate {
  // this function is passed a predicate and sortDescriptor from the FilterViewController
  func filterViewController(
    filter: FilterViewController,
    didSelectPredicate predicate: NSPredicate?,
    sortDescriptor: NSSortDescriptor?) {
    guard let fetchRequest = fetchRequest else {
      return
    }
    // fetchRequest on Venue objects with passed predicate and sort
    fetchRequest.predicate = nil // reset predicate and sort desciptors
    fetchRequest.sortDescriptors = nil
    fetchRequest.predicate = predicate // set based on what was passed to us, the delagate, i.e. Venue objects with priceinfo.pricecategory matching $
    if let sr = sortDescriptor {
      fetchRequest.sortDescriptors = [sr] // sort the venue objects that are filtered by a predicate
    }
    fetchAndReload() // call this to acutally do the fetch request
  }
}
