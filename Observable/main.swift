//
//  main.swift
//  Observable
//
//  Created by Tbxark on 06/11/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import Foundation


class Man {
    let age = Variable<Int>(0)
}

let peter = Man()
_ = peter.age.asObserver().subscribeNext { (age) in
    print("Age change   \(age)")
}
peter.age.value = 1
peter.age.value = 18

