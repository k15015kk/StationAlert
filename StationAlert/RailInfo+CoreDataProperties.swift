//
//  RailInfo+CoreDataProperties.swift
//  StationAlert
//
//  Created by k15015kk on 2017/08/18.
//  Copyright © 2017年 HarukiInoue. All rights reserved.
//

import Foundation
import CoreData


extension RailInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RailInfo> {
        return NSFetchRequest<RailInfo>(entityName: "RailInfo")
    }

    @NSManaged public var company: String?
    @NSManaged public var latitude: Double
    @NSManaged public var lineName: String?
    @NSManaged public var longitude: Double

}
