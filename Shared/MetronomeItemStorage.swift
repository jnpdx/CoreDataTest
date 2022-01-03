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
    @Published var totalTimeSum : Float = 0
    
    private let controller : NSFetchedResultsController<MetronomeItem>
    private var context : NSManagedObjectContext
    
    private var subscriptions: Set<AnyCancellable> = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        let fetchRequest = MetronomeItem.fetchRequest()
        let sortByTimestamp = NSSortDescriptor(keyPath: \MetronomeItem.timestamp, ascending: true)
        
        let calendar = Calendar.current
        
        let beginRange =
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: -30, to: Date())!)

        let endRange =
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        
        let predicate = NSPredicate(format: "timestamp > %@ && timestamp < %@", beginRange as NSDate, endRange as NSDate)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByTimestamp]
        controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        
        super.init()
        
        controller.delegate = self
        
        do {
            try controller.performFetch()
            self.newItems(items: controller.fetchedObjects ?? [])
        } catch {
            print(error)
            fatalError()
        }
        
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didSaveObjectsNotification)
            .sink { change in
                print("Save: --", change)
                self.updateWidgets()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink { change in
                print("Remote change!")
                print(change)
                self.updateWidgets()
            }
            .store(in: &subscriptions)
    }
    
    func updateWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "CoreDataWidget")
    }
    
    func addItem() {
        let newItem = MetronomeItem(context: context)
        newItem.timestamp = Date()
        newItem.metronomeTime = 5.0
        
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
    
    var totalTimeInLast2Days : Float {
        //TODO: calculate
        0.0
    }
}

extension MetronomeItemStorage {
    var itemsByDay : [(dateKey: String, items: [MetronomeItem])] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-YYYY"
        
        let calendar = Calendar.current
        let curDate = Date()
        
        return (0..<7).reversed().map { day -> (dateKey: String, items: [MetronomeItem]) in
            let dayStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 0 - day, to: curDate)!)
            var components = DateComponents()
            components.day = 1
            components.second = -1
            let dayEnd = calendar.date(byAdding: components, to: dayStart)!
            
            let key = dateFormatter.string(from: dayStart)
            let dateItems = self.items.filter { ($0.timestamp ?? Date()) >= dayStart && ($0.timestamp ?? Date()) <= dayEnd }
            return (dateKey: key, items: dateItems)
        }
    }
}

extension MetronomeItemStorage {
    func doSumRequest() {
        //sum request
        let sumRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetronomeItem")
        sumRequest.sortDescriptors = [.init(keyPath: \MetronomeItem.timestamp, ascending: true)]
        sumRequest.resultType = .dictionaryResultType
        let desc = NSExpressionDescription()
        desc.name = "sum"
        desc.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: \MetronomeItem.metronomeTime)])
        desc.expressionResultType = .floatAttributeType
        sumRequest.propertiesToFetch = [desc]
        do {
            let results = try context.fetch(sumRequest)
            print("RESULTS:")
            print(results)
            let resultMap = results[0] as! [String:Float]
            self.totalTimeSum = resultMap["sum"] ?? 0
        } catch {
            print(error)
            fatalError()
        }
    }
    
    func newItems(items: [MetronomeItem]) {
        withAnimation {
            self.items = items
        }
        print("New items!")
        print(itemsByDay.map(\.dateKey))
        self.doSumRequest()
    }
}

extension MetronomeItemStorage : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let items = controller.fetchedObjects as? [MetronomeItem] else { return }
        DispatchQueue.main.async {
            self.newItems(items: items)
        }
    }
}
