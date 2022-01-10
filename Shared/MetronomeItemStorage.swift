//
//  MetronomeItemStorage.swift
//  CoreDataTest
//
//  Created by John Nastos on 1/2/22.
//

import Foundation
import Combine
import CoreData
import SwiftUI
import WidgetKit

class MetronomeItemStorage : NSObject, ObservableObject {
    @Published var items : [MetronomeItem] = []
    
    private let controller : NSFetchedResultsController<MetronomeItem>
    private var context : NSManagedObjectContext
    
    @AppStorage("ItemCreatorID") private var deviceID : String = ""
    
    init(context: NSManagedObjectContext) {
        print("Creating storage")
        
        self.context = context
        let fetchRequest = MetronomeItem.fetchRequest()
        let sortByTimestamp = NSSortDescriptor(keyPath: \MetronomeItem.timestamp, ascending: true)
        fetchRequest.sortDescriptors = [sortByTimestamp]
        controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        
        super.init()
        
        if deviceID == "" {
            //create a unique ID and store it
            let createdID = UUID().uuidString
            deviceID = createdID
            print("Storing ID: ", createdID)
        } else {
            print("Retrieved ID: ", deviceID)
        }
        
        controller.delegate = self
        
        do {
            try controller.performFetch()
            self.newItems(items: controller.fetchedObjects ?? [])
        } catch {
            print(error)
            fatalError()
        }
    }
    
    func filteredItems(onlyThisDevice: Bool) -> [MetronomeItem] {
        return onlyThisDevice ?
            items.filter { $0.creator?.uuidString == deviceID }
            :
            items
    }
    
    func updateWidgets() {
        print("Updating widget...")
        WidgetCenter.shared.reloadTimelines(ofKind: "CoreDataWidget")
    }
    
    func addItem() {
        print("Adding item in:",context)
        let newItem = MetronomeItem(context: context)
        newItem.timestamp = Date()
        newItem.metronomeTime = 5.0
        newItem.creator = UUID(uuidString: deviceID)
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(context.delete)
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    var totalTime : Float {
        items.reduce(0) { partialResult, item in
            partialResult + item.metronomeTime
        }
    }
}

extension MetronomeItemStorage : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let items = controller.fetchedObjects as? [MetronomeItem] else { return }
        DispatchQueue.main.async {
            self.newItems(items: items)
        }
    }
    
    private func newItems(items: [MetronomeItem]) {
        withAnimation {
            self.items = items
        }
    }
}
