//
//  TelemetryScheduler.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 4/18/17.
//
//

import Foundation

public class TelemetryScheduler {
    private let configuration: TelemetryConfiguration
    private let storage: TelemetryStorage
    
    private let client: TelemetryClient
    
    init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.configuration = configuration
        self.storage = storage
        
        self.client = TelemetryClient(configuration: configuration)
    }
    
    public func scheduleUpload(pingType: String, completionHandler: @escaping () -> Void) {
        if hasReachedDailyUploadLimit(forPingType: pingType) {
            return
        }
        
        let pings = storage.load(pingType: pingType)

        let dispatchGroup = DispatchGroup()
        
        for ping in pings {
            dispatchGroup.enter()

            client.upload(ping: ping) { (error) in
                if error != nil {
                    print("Error uploading TelemetryPing: \(error!.localizedDescription)")
                }

                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { 
            print("Done uploading!!")
            completionHandler()
        }
    }
    
    private func hasReachedDailyUploadLimit(forPingType pingType: String) -> Bool {
        if let lastUploadTimestamp = storage.get(valueFor: "\(pingType)-lastUploadTimestamp") as? TimeInterval {
            if isNewDay(dateA: Date(timeIntervalSince1970: lastUploadTimestamp), dateB: Date()) {
                return false
            }
            
            if let dailyUploadCount = storage.get(valueFor: "\(pingType)-dailyUploadCount") as? Int {
                return dailyUploadCount >= configuration.maximumNumberOfPingUploadsPerDay
            }
        }
        
        return false
    }
    
    private func isNewDay(dateA: Date, dateB: Date) -> Bool {
        let dayA = Calendar.current.component(.day, from: dateA)
        let monthA = Calendar.current.component(.month, from: dateA)
        let yearA = Calendar.current.component(.year, from: dateA)
        
        let dayB = Calendar.current.component(.day, from: dateB)
        let monthB = Calendar.current.component(.month, from: dateB)
        let yearB = Calendar.current.component(.year, from: dateB)
        
        return dayA != dayB || monthA != monthB || yearA != yearB
    }
}
