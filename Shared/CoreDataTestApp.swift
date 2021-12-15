//
//  CoreDataTestApp.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import SwiftUI

@main
struct CoreDataTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(context: PersistenceController.shared.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
