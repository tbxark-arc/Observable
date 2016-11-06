//
//  Observable.swift
//  Observable
//
//  Created by Tbxark on 06/11/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import Foundation


// MARK: - LOCK
protocol Lock {
    func lock()
    func unlock()
}

typealias SpinLock = NSRecursiveLock
extension SpinLock : Lock {
    func performLocked(_ action: () -> Void) {
        lock(); defer { unlock() }
        action()
    }
    
    func calculateLocked<T>(_ action: () -> T) -> T {
        lock(); defer { unlock() }
        return action()
    }
    
    func calculateLockedOrFail<T>(_ action: () throws -> T) throws -> T {
        lock(); defer { unlock() }
        let result = try action()
        return result
    }
}


// MARK: - Disposable
public protocol Disposable {
    func dispose()
}

extension Disposable {
    func addDisposableTo(_ bag: DisposeBag) {
        bag.insert(self)
    }
}

public final class DisposeBag {
    
    private var _lock = SpinLock()
    private var _disposables = [Disposable]()
    private var _isDisposed = false
    public func insert(_ disposable: Disposable) {
        _insert(disposable)?.dispose()
    }
    
    private func _insert(_ disposable: Disposable) -> Disposable? {
        _lock.lock(); defer { _lock.unlock() }
        if _isDisposed {
            return disposable
        }
        
        _disposables.append(disposable)
        
        return nil
    }
    
    private func dispose() {
        let oldDisposables = _dispose()
        for disposable in oldDisposables {
            disposable.dispose()
        }
    }
    
    private func _dispose() -> [Disposable] {
        _lock.lock(); defer { _lock.unlock() }
        
        let disposables = _disposables
        
        _disposables.removeAll(keepingCapacity: false)
        _isDisposed = true
        
        return disposables
    }
    
    deinit {
        dispose()
    }
}


// MARK: - Observable
public enum Event<T> {
    case next(T)
    case error(Error)
    case completed
}

public enum SubscribeHandler<T> {
    case next(handle: (T) -> Void)
    case error(handle: (Error) -> Void)
    case completed(handle: () -> Void)
    case event(handle: (Event<T>) -> Void)

}

public class Observable<T> {
    
    
    fileprivate var observers = [SubscribeDisposable<T>]()
   
    public init() {}
    
    
    public func on(_ event: Event<T>) {
        for handler in self.observers {
            handler.on(event)
        }
    }
    
    public func onNext(_ data: T) {
        on(Event<T>.next(data))
    }
    
    public func onError(_ error: Error) {
        on(Event<T>.error(error))
    }
    
    public func onComplete() {
        on(Event<T>.completed)
    }
    
    private func subscribe(handler: SubscribeHandler<T>) -> Disposable {
        let sub = SubscribeDisposable<T>(handler: handler, owner: self)
        observers.append(sub)
        return sub
    }
    
    public func subscribe(_ handler: @escaping (Event<T>) -> Void) -> Disposable {
        return subscribe(handler: SubscribeHandler<T>.event(handle: handler))
    }
    
    public func subscribeNext(_ handler: @escaping (T) -> Void ) -> Disposable {
        return subscribe(handler: SubscribeHandler<T>.next(handle: handler))
    }
    
    public func subscribeError(_ handler: @escaping (Error) -> Void) -> Disposable {
        return subscribe(handler: SubscribeHandler<T>.error(handle: handler))
    }
    
    public func subscribeComplete(_ handler: @escaping () -> Void) -> Disposable {
        return subscribe(handler: SubscribeHandler<T>.completed(handle: handler))
    }
    
}


private class SubscribeDisposable<T> : Disposable {
    
    let handler: SubscribeHandler<T>
    let owner: Observable<T>
    
    init(handler: SubscribeHandler<T>, owner: Observable<T>){
        self.handler = handler
        self.owner = owner;
    }
    
    public func on(_ event: Event<T>) {
        switch (handler, event) {
        case (.event(let handle), let event):
            handle(event)
        case (.next(let handle), .next(let data)):
            handle(data)
        case (.error(let handle), .error(let error)):
            handle(error)
        case (.completed(let handle), .completed):
            handle()
        default:
            break
        }
        switch event {
        case .completed, .error(_):
            dispose()
        default:
            break
        }
    }
    
    func dispose() {
        owner.observers = owner.observers.filter { $0 !== self }
    }
}


// MARK: Variable
class Variable<T> {
    
    let valueChange = Observable<(T, T)>()
    private var value: T
    
    init(_ initialValue: T) {
        value = initialValue
    }
    
    func set(newValue: T) {
        let oldValue = value
        value = newValue
        valueChange.onNext((oldValue, newValue))
    }
    
    func get() -> T {
        return value
    }
}



