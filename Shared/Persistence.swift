//
//  Persistence.swift
//  Shared
//
//  Created by John Nastos on 12/14/21.
//

import CoreData

class PersistenceManager : ObservableObject {
    
    @Published var cloudEnabled : Bool {
        didSet {
            persistentContainer = Self.setupContainer(cloudEnabled: cloudEnabled)
            objectWillChange.send() //use this to have the view hierarchy update and create new references to the new persistentContainer
        }
    }
    
    var persistentContainer: NSPersistentContainer
    
    init(cloud: Bool) {
        _cloudEnabled = Published(initialValue: cloud)
        persistentContainer = Self.setupContainer(cloudEnabled: cloud)
    }
    
    static func setupContainer(cloudEnabled: Bool) -> NSPersistentContainer {
        var container : NSPersistentContainer
        if cloudEnabled {
            print("Generating NSPersistentCloudKitContainer")
            container = NSPersistentCloudKitContainer(name: "CoreDataTest", managedObjectModel: try! model(name: "CoreDataTest"))
            let cloudDescription = generateStoreDescription(cloud: true)
            container.persistentStoreDescriptions = [cloudDescription]
            
#if DEBUG
            //on macOS, this has to go before loading the stores, but it causes a console error
            //on iOS, it can (should?) go after
            do {
                try (container as? NSPersistentCloudKitContainer)?.initializeCloudKitSchema(options: [])
            } catch {
                print("CloudKit schema error")
                print(error)
            }
#endif
            
        } else {
            print("Generating NSPersistentContainer")
            container = NSPersistentContainer(name: "CoreDataTest", managedObjectModel: try! model(name: "CoreDataTest"))
            let desc = generateStoreDescription(cloud: false)
            container.persistentStoreDescriptions = [desc]
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print("Loaded stores")
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    
        
        return container
    }
    
    static func generateStoreDescription(cloud: Bool) -> NSPersistentStoreDescription {
        print("---GENERARTING DESCRIPTION FOR CLOUD: ", cloud)
        let storeURL = Self.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest-Cloud")
        print("StoreURL: ",storeURL)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.configuration = "Cloud"
        if cloud {
            let cloudkitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.johnnastos.CoreDataTest")
            storeDescription.cloudKitContainerOptions = cloudkitOptions
        } else {
            storeDescription.cloudKitContainerOptions = nil
        }
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        return storeDescription
    }
    
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

//Have to use this strategy when recreating NSPersistentContainer or else
//there will be warnings about multiple instances owning the Core Data models
extension PersistenceManager {
    private static var _model: NSManagedObjectModel?
    private static func model(name: String) throws -> NSManagedObjectModel {
        if _model == nil {
            _model = try loadModel(name: name, bundle: Bundle.main)
        }
        return _model!
    }
    private static func loadModel(name: String, bundle: Bundle) throws -> NSManagedObjectModel {
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError()
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError()
       }
        return model
    }
}
