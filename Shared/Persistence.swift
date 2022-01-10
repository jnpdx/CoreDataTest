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
            objectWillChange.send()
        }
    }
    
    var persistentContainer: NSPersistentContainer
    
    init(cloud: Bool) {
        _cloudEnabled = Published(initialValue: cloud)
        persistentContainer = Self.setupContainer(cloudEnabled: cloud)
    }
    
    static func setupContainer(cloudEnabled: Bool) -> NSPersistentContainer {
        var container : NSPersistentContainer?
        if cloudEnabled {
            print("Generating NSPersistentCloudKitContainer")
            container = NSPersistentCloudKitContainer(name: "CoreDataTest", managedObjectModel: try! model(name: "CoreDataTest"))
            let cloudDescription = generateStoreDescription(cloud: true)
            container?.persistentStoreDescriptions = [cloudDescription]
            
//#if DEBUG
//            //on macOS, this has to go before loading the stores, but it causes a console error
//            //on iOS, it can go after
//            do {
//                try (container as? NSPersistentCloudKitContainer)?.initializeCloudKitSchema(options: [])
//            } catch {
//                print("CloudKit schema error")
//                print(error)
//            }
//#endif
            
        } else {
            print("Generating NSPersistentContainer")
            container = NSPersistentContainer(name: "CoreDataTest", managedObjectModel: try! model(name: "CoreDataTest"))
            let desc = generateStoreDescription(cloud: false)
            container?.persistentStoreDescriptions = [desc]
        }
        
        container?.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print("Loaded stores")
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
            container?.viewContext.automaticallyMergesChangesFromParent = true
        })
    
        
        return container!
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

struct _PersistenceController {
    var cloudEnabled : Bool = true {
        didSet {
            print("SETTING CLOUDENABLED")
            initializeContainer(inMemory: false, inCloud: cloudEnabled)
        }
    }
    var container: NSPersistentContainer = NSPersistentCloudKitContainer(name: "CoreDataTest")
    
    func generateNonCloudStoreDescription() -> NSPersistentStoreDescription {
        let storeURL = Self.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest-Cloud")
        print("StoreURL: ",storeURL)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.configuration = "Cloud"
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        return storeDescription
    }
    
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
        let storeURL = Self.storeURL(for: "group.com.johnnastos.CoreDataTest", databaseName: "CoreDataTest-Cloud")
        print("StoreURL (local): ",storeURL)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.cloudKitContainerOptions = nil
        storeDescription.configuration = "Cloud"
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        return storeDescription
    }
    
    mutating func initializeContainer(inMemory: Bool, inCloud: Bool) {
        if inCloud {
            let cloudContainer = NSPersistentCloudKitContainer(name: "CoreDataTest")
            container = cloudContainer
            container.viewContext.automaticallyMergesChangesFromParent = true
            
            let cloudDescription = generateCloudStoreDescription()
            
            container.persistentStoreDescriptions = [
                cloudDescription,
                //localDescription
            ]
            
#if DEBUG
            do {
                try cloudContainer.initializeCloudKitSchema(options: [])
            } catch {
                print("CloudKit schema error")
                print(error)
            }
#endif
        } else {
            container = NSPersistentContainer(name: "CoreDataTest")
            let desc = generateLocalStoreDescription()
            container.persistentStoreDescriptions = [desc]
        }
        
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
    
    init(inMemory: Bool = false) {
        initializeContainer(inMemory: inMemory, inCloud: true)
    }
}

extension _PersistenceController {
    static var preview: _PersistenceController = {
        let result = _PersistenceController(inMemory: true)
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

extension _PersistenceController {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
