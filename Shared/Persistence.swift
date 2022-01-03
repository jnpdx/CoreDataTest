//
//  Persistence.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CoreDataTest")
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        let storeURL = URL.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        let cloudkitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.johnnastos.CoreDataTest")
        storeDescription.cloudKitContainerOptions = cloudkitOptions

        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        
        container.persistentStoreDescriptions = [storeDescription]
        print("StoreURL: ",storeURL)

#if DEBUG
        do {
            try container.initializeCloudKitSchema(options: [])
        } catch {
            print("CloudKit schema error")
            print(error)
        }
#endif
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}

extension PersistenceController {
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = MetronomeItem(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
}

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
