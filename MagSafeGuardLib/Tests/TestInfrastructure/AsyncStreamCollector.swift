//
//  AsyncStreamCollector.swift
//  MagSafe Guard
//

import Foundation

/// Collects values from a non-throwing async stream without Swift 6 data-race warnings in tests.
public actor AsyncStreamCollector<Element: Sendable> {
  private var values: [Element] = []
  private var collectionTask: Task<Void, Never>?

  public init() {}

  public func start(collecting stream: AsyncStream<Element>) {
    collectionTask?.cancel()
    collectionTask = Task {
      for await value in stream {
        await append(value)
      }
    }
  }

  private func append(_ value: Element) {
    values.append(value)
  }

  public func snapshot() -> [Element] {
    values
  }

  public func cancel() {
    collectionTask?.cancel()
    collectionTask = nil
  }
}
