# Observable
Observable is a simple observer framework, like the Lite version of RxSwift

# Example

```swift

class Man {
    let age = Variable<Int>(0)
}

let peter = Man()
_ = peter.age.asObserver().subscribeNext { (age) in
    print("Age change   \(age)")
}
peter.age.value = 1
peter.age.value = 18

// Output
// Age change   1
// Age change   18
```
