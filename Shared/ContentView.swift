//
//  ContentView.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import SwiftUI
import CoreData
import Combine

class MetronomeItemStorage : NSObject, ObservableObject {
    @Published var items : [MetronomeItem] = []
    
    @Published var totalTimeSum : Float = 0
    
    private let controller : NSFetchedResultsController<MetronomeItem>
    var context : NSManagedObjectContext
    
    //private let sumController: NSFetchedResultsController<NSFetchRequestResult>
    
    private var subscriptions: Set<AnyCancellable> = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        let fetchRequest = MetronomeItem.fetchRequest()
        let sortByTimestamp = NSSortDescriptor(keyPath: \MetronomeItem.timestamp, ascending: true)
        
        //        let beginRange = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        //        let endRange = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        //
        //        let predicate = NSPredicate(format: "timestamp > %@ && timestamp < %@", beginRange as NSDate, endRange as NSDate)
        //        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByTimestamp]
        controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        
        
        //        sumController = NSFetchedResultsController(fetchRequest: sumRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
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
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink { change in
                print("Remote change!")
                print(change)
            }
            .store(in: &subscriptions)
    }
    
    func addItem() {
        let newItem = MetronomeItem(context: context)
        newItem.timestamp = Date()
        newItem.metronomeTime = 5.0
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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

class ViewModel : ObservableObject {
    @Published var metronomeItems : [MetronomeItem] = []
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel : MetronomeItemStorage
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MetronomeItemStorage(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    let itemsByDay = viewModel.itemsByDay
                    ForEach(itemsByDay, id: \.dateKey) { item in
                        Section(header: Text("\(item.dateKey)")) {
                            ForEach(item.items) { value in
                                VStack {
                                    Text(value.timestamp ?? Date(), formatter: itemFormatter)
                                    Text("\(value.metronomeTime)")
                                }
                            }
                        }
                    }
//                    Section(header: Text("My section")) {
//                        ForEach(viewModel.items) { item in
//                            NavigationLink {
//                                Text("Item at \(item.timestamp ?? Date()) \(item.metronomeTime)")
//                            } label: {
//                                Text(item.timestamp ?? Date(), formatter: itemFormatter)
//                            }
//                        }
//                        .onDelete(perform: viewModel.deleteItems)
//                    }
                }
                Text("Total time: \(viewModel.totalTime)")
                Text("Total time (sum): \(viewModel.totalTimeSum)")
                Text("Total time in last 2 days: \(viewModel.totalTimeInLast2Days)")
            }
            
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: viewModel.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        let yesterdayItem = MetronomeItem(context: viewContext)
                        
                        let calendar = Calendar.current
                        
                        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
                        
                        yesterdayItem.timestamp = yesterday
                        yesterdayItem.metronomeTime = 7.00
                        
                        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())
                        
                        let lastWeekItem = MetronomeItem(context: viewContext)
                        lastWeekItem.timestamp = lastWeek
                        lastWeekItem.metronomeTime = 22.0
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                            fatalError()
                        }
                    }) {
                        Label("Add Fake Items", systemImage: "plus.circle")
                    }
                }
            }
            Text("Select an item")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
