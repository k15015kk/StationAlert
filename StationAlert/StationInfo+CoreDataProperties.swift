//
//  StationInfo+CoreDataProperties.swift
//  StationAlert
//
//  Created by k15015kk on 2017/08/02.
//  Copyright © 2017年 HarukiInoue. All rights reserved.
//

import Foundation
import CoreData


extension StationInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StationInfo> {
        return NSFetchRequest<StationInfo>(entityName: "StationInfo")
    }

    @NSManaged public var company: String?
    @NSManaged public var latitude: Double
    @NSManaged public var lineName: String?
    @NSManaged public var longitude: Double
    @NSManaged public var stationName: String?

}
