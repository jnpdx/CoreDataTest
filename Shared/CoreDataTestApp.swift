//
//  CoreDataTestApp.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import SwiftUI

@main
struct CoreDataTestApp: App {
    @StateObject var persistenceController = PersistenceManager(cloud: false)

    var body: some Scene {
        WindowGroup {
            ContentView(persistenceController: persistenceController)
        }
    }
}
