//
//  CoreDataWidget.swift
//  CoreDataWidget
//
//  Created by John Nastos on 12/15/21.
//

import WidgetKit
import SwiftUI
import CoreData

struct WidgetDataProvider {
    func getWidgetData() -> Float {
        let context = PersistenceController.shared.container.viewContext
        
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
            return (resultMap["sum"] ?? 10.0)
        } catch {
            print(error)
            fatalError()
        }
    }
    
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(sum: -1.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(sum: -1.0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let data = WidgetDataProvider().getWidgetData()
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        for _ in 0 ..< 5 {
            let entry = SimpleEntry(sum: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    var date = Date()
    let sum: Float
}

struct CoreDataWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("\(entry.sum)")
    }
}

@main
struct CoreDataWidget: Widget {
    let kind: String = "CoreDataWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CoreDataWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct CoreDataWidget_Previews: PreviewProvider {
    static var previews: some View {
        CoreDataWidgetEntryView(entry: SimpleEntry(sum: 1.0))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
