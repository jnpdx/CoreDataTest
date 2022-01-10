//
//  ContentView.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import SwiftUI
import CoreData
import Combine
import WidgetKit

struct ContentView: View {
    @ObservedObject private var viewModel : MetronomeItemStorage
    @ObservedObject var persistenceController : PersistenceManager
    @State private var filterType : FilterType = .allDevices
    
    private enum FilterType : String, CaseIterable {
        case thisDevice
        case allDevices
    }
    
    var viewContext : NSManagedObjectContext {
        persistenceController.persistentContainer.viewContext
    }
    
    init(persistenceController: PersistenceManager) {
        print("Init ContentView")
        _persistenceController = ObservedObject(wrappedValue: persistenceController)
        _viewModel = ObservedObject(wrappedValue: MetronomeItemStorage(context: persistenceController.persistentContainer.viewContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Toggle(isOn: $persistenceController.cloudEnabled) {
                    Text("Cloud enabled")
                }
                Picker(selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                } label: {
                    Text("Type")
                }.pickerStyle(.segmented)

                List {
                    let itemsByDay = viewModel.itemsByDay(onlyThisDevice: filterType == .thisDevice)
                    ForEach(itemsByDay, id: \.dateKey) { item in
                        Section(header: Text("\(item.dateKey)")) {
                            ForEach(item.items) { value in
                                NavigationLink {
                                    DetailView(item: value)
                                } label: {
                                    VStack {
                                        Text(value.timestamp ?? Date(), formatter: itemFormatter)
                                        Text("\(value.metronomeTime)")
                                    }
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
                .listStyle(.sidebar)
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
        }.environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct DetailView : View {
    @ObservedObject var item : MetronomeItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            Text("Metronome item")
            Text(item.creator?.uuidString ?? "No ID")
            Text(item.timestamp ?? Date(), formatter: itemFormatter)
            Text("Time: \(item.metronomeTime)")
            Button {
                presentationMode.wrappedValue.dismiss()
                viewContext.delete(item)
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving: ", error)
                }
            } label: {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
                }

            }
            Slider(value: $item.metronomeTime, in: 0...40, step: 10) {
                Text("Metronome time")
            }.onChange(of: item.metronomeTime) { _ in
                try? viewContext.save()
            }
        }
    }
}
