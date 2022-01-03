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
    
    func generateCloudStoreDescription() -> NSPersistentStoreDescription {
        let storeURL = Self.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest-Cloud")
        print("StoreURL: ",storeURL)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.configuration = "Cloud"
        let cloudkitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.johnnastos.CoreDataTest")
        storeDescription.cloudKitContainerOptions = cloudkitOptions
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        return storeDescription
    }
    
    ///Probably don't use this, as we can't share entities between two stores
    func generateLocalStoreDescription() -> NSPersistentStoreDescription {
        let storeURL = Self.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest-Local")
        print("StoreURL (local): ",storeURL)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.configuration = "Local"
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        return storeDescription
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CoreDataTest")
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        let cloudDescription = generateCloudStoreDescription()
        //let localDescription = generateLocalStoreDescription()
        
        container.persistentStoreDescriptions = [
            cloudDescription,
            //localDescription
        ]

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

extension PersistenceController {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
