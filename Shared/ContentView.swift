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
    
    var viewContext : NSManagedObjectContext {
        persistenceController.persistentContainer.viewContext
    }
    
    init(persistenceController: PersistenceManager) {
        print("Init ContentView")
        _persistenceController = ObservedObject(wrappedValue: persistenceController)
        _viewModel = ObservedObject(wrappedValue:
                                        MetronomeItemStorage(context: persistenceController.persistentContainer.viewContext)
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                VStack {
                    Toggle(isOn: $persistenceController.cloudEnabled) {
                        Text("Cloud enabled")
                    }
                    Picker(selection: $filterType) {
                        ForEach(FilterType.allCases, id: \.self) {
                            Text($0.name)
                        }
                    } label: {
                        Text("Type")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }.padding()
                
                List {
                    ForEach(viewModel.items) { value in
                        NavigationLink {
                            DetailView(item: value)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(value.timestamp ?? Date(), formatter: itemFormatter)
                                + Text(": \(Int(value.metronomeTime))min")
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                
                
                Text("Total time: \(viewModel.totalTime)")
                    .padding()
            }
            
            .toolbar {
                ToolbarItem {
                    Button(action: viewModel.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            
            //Detail view:
            Text("Select an item")
        }.environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
    }
}

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

private enum FilterType : String, CaseIterable {
    case thisDevice
    case allDevices
    
    var name : String {
        switch self {
        case .allDevices:
            return "All Devices"
        case .thisDevice:
            return "This Device"
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
