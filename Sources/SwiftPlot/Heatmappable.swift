//
//  Heatmappable.swift
//  SwiftPlot
//
//  Created by Ricardo Nogueira on 02/02/2020.
//

import Foundation

// MARK: - Alternative approach

// MARK: Basic Protocols

public protocol Heatmappable {
    associatedtype Iterator: HeatmappableIterator
    var width: Int { get }
    var height: Int { get }
    
    func makeIterator() -> Iterator
}

public protocol HeatmappableIterator {
    mutating func next() -> (row: Int, column: Int, element: Float)?
}


// MARK: 1D Datasets.

public struct Heatmappable1D<Base: Sequence>: Heatmappable {
    typealias Element = Base.Element
    public let width: Int
    public let height: Int
    private let base: Base
    private let mapping: Mapping.Heatmap<Element>
    private let minValue: Element
    private let maxValue: Element
    
    init(base: Base, width: Int, mapping: Mapping.Heatmap<Element>) {
        self.base = base
        self.width = width
        self.mapping = mapping
        
        // Extract the first element as a starting point.
        var oneOffIterator = base.makeIterator()
        guard let firstElem = oneOffIterator.next() else {
            fatalError("Heatmappable1D.init(base:width:mapping): base is empty!")
        }
        var (minValue, maxValue) = (firstElem, firstElem)
        
        // - Discover the maximum/minimum values and shape of the data.
        var currentWidth: Int = 0
        var height: Int = 0
        for value in base {
            minValue = mapping.compare(minValue, value) ? minValue : value
            maxValue = mapping.compare(maxValue, value) ? value : maxValue
            currentWidth += 1
            if currentWidth == 1 {
                height += 1
            }
            if currentWidth == width {
                currentWidth = 0
            }
        }
        
        self.height = height
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    public struct Iterator: HeatmappableIterator {
        private var heatmappable: Heatmappable1D
        private var baseIterator: Base.Iterator
        private var row: Int = 0
        private var column: Int = 0
        
        init(_ heatmappable: Heatmappable1D<Base>) {
            self.heatmappable = heatmappable
            self.baseIterator = heatmappable.base.makeIterator()
        }
        
        mutating public func next() -> (row: Int, column: Int, element: Float)? {
            guard let nextElement = baseIterator.next() else { return nil }
            let result = (row: row,
                          column: column,
                          element: heatmappable.mapping.interpolate(nextElement,
                                                                    heatmappable.minValue,
                                                                    heatmappable.maxValue))
            column += 1
            if column == heatmappable.width {
                column = 0
                row += 1
            }
            return result
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}


// MARK: 2D Datasets.

public struct Heatmappable2D<Base: Sequence>: Heatmappable where Base.Element: Sequence {
    typealias Element = Base.Element.Element
    public let width: Int
    public let height: Int
    private let base: Base
    private let mapping: Mapping.Heatmap<Element>
    private let minValue: Element
    private let maxValue: Element
    
    init(base: Base, mapping: Mapping.Heatmap<Element>) {
        self.base = base
        self.mapping = mapping
        
        // Extract the first element as a starting point.
        var firstElement: Base.Element.Element? = nil
        loop: for row in base {
            for value in row {
                firstElement = value
                break loop
            }
        }
        guard let firstValue = firstElement else {
            fatalError("Heatmappable2D.init(base:width:mapping): base is empty!")
        }
        var (minValue, maxValue) = (firstValue, firstValue)
        
        // - Discover the maximum/minimum values and shape of the data.
        var currentWidth: Int = 0
        var width: Int = 0
        var height: Int = 0
        for row in base {
            for value in row {
                minValue = mapping.compare(minValue, value) ? minValue : value
                maxValue = mapping.compare(maxValue, value) ? value : maxValue
                currentWidth += 1
            }
            width = max(width, currentWidth)
            currentWidth = 0
            height += 1
        }
        self.width = width
        self.height = height
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    public struct Iterator: HeatmappableIterator {
        private let heatmappable: Heatmappable2D
        private var rowIterator: Base.Iterator
        private var columnIterator: EnumeratedSequence<Base.Element>.Iterator
        private var currentRow: Int
        
        init(_ heatmappable: Heatmappable2D) {
            self.heatmappable = heatmappable
            self.rowIterator = heatmappable.base.makeIterator()
            guard let firstRow = rowIterator.next() else {
                fatalError("Heatmappable2D.Iterator: base is empty!")
            }
            self.columnIterator = firstRow.enumerated().makeIterator()
            self.currentRow = 0
        }
        
        mutating public func next() -> (row: Int, column: Int, element: Float)? {
            var optColumnValuePair = columnIterator.next()
            while optColumnValuePair == nil {
                guard let nextRow = rowIterator.next() else { return nil }
                columnIterator = nextRow.enumerated().makeIterator()
                currentRow += 1
                optColumnValuePair = columnIterator.next()
            }
            let columnValuePair = optColumnValuePair!
            
            let value = heatmappable.mapping.interpolate(columnValuePair.element,
                                                         heatmappable.minValue,
                                                         heatmappable.maxValue)
            return (currentRow, columnValuePair.offset, value)
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}


