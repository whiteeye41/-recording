//
//  Coredata.swift
//  HW-20200506
//
//  Created by cosima on 2020/5/7.
//  Copyright © 2020 cosima. All rights reserved.
//

import UIKit
import CoreData


class CoreDataType : NSManagedObject {
    
    @NSManaged var fileID : String
    @NSManaged var fileName : String
    @NSManaged var date :String!
    
    
    override func awakeFromInsert() {
        fileID = UUID().uuidString
        print("我的fileID是\(fileID)")
    }
}
