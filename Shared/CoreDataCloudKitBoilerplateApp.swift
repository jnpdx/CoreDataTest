//
//  CoreDataCloudKitBoilerplateApp.swift
//  Shared
//
//  Created by John Nastos on 12/15/21.
//

import SwiftUI

@main
struct CoreDataCloudKitBoilerplateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
