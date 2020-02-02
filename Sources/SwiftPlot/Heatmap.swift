
// Todo list for Heatmap:
// - Spacing between blocks
// - Setting X/Y axis labels
// - Displaying colormap next to plot

/// A heatmap is a plot of 2-dimensional data, where each value is assigned a colour value along a gradient.
///
/// Use the `mapping` property to control how values are graded. For example, if your data structure has
/// a salient integer or floating-point property, `.keyPath` will allow you to grade values by that property:
///
/// ```swift
/// let data: [[MyObject]] = ...
/// data.plots.heatmap(mapping: .keyPath(\.importantProperty)) {
///   $0.colorMap = .fiveColorHeatmap
/// }
/// ```
public struct Heatmap<SeriesType> where SeriesType: Heatmappable {
  public var layout = GraphLayout()
  
  public var heatmappable: SeriesType
  public var colorMap: ColorMap = .fiveColorHeatMap
    
    public init(_ heatmappable: SeriesType, style: (inout Self)->Void = { _ in }) {
      self.heatmappable = heatmappable
      self.layout.drawsGridOverForeground = true
      self.layout.markerLabelAlignment = .betweenMarkers
      self.showGrid = false
      style(&self)
    }
}

// Customisation properties.

extension Heatmap {
  
  public var showGrid: Bool {
    get { layout.enablePrimaryAxisGrid }
    set { layout.enablePrimaryAxisGrid = newValue }
  }
}

// Layout and drawing.

extension Heatmap: HasGraphLayout, Plot {
  
  public struct DrawingData: AdjustsPlotSize {
    var values: SeriesType?
    var itemSize = Size.zero
    var rows = 0
    var columns = 0
    
    var desiredPlotSize = Size.zero
  }
  
  public func layoutData(size: Size, renderer: Renderer) -> (DrawingData, PlotMarkers?) {
    
    var results = DrawingData()
    var markers = PlotMarkers()
    
    // - Calculate the element size.
    var elementSize = Size(
        width: size.width / Float(heatmappable.width),
        height: size.height / Float(heatmappable.height)
    )
    // We prefer showing smaller elements with integer dimensions to avoid aliasing.
    if elementSize.width > 1  { elementSize.width.round(.down)  }
    if elementSize.height > 1 { elementSize.height.round(.down) }
    
    // Update results.
    results.values = heatmappable
    results.rows = heatmappable.height
    results.columns = heatmappable.width
    results.itemSize = elementSize
    // The size rounding may leave a gap between the data and the border,
    // so let the layout know we desire a smaller plot.
    results.desiredPlotSize = Size(width: Float(results.columns) * results.itemSize.width,
                                   height: Float(results.rows) * results.itemSize.height)
    
    // Calculate markers.
    markers.xMarkers = (0..<results.columns).map {
      Float($0) * results.itemSize.width
    }
    markers.yMarkers = (0..<results.rows).map {
      Float($0) * results.itemSize.height
    }
    
    // TODO: Allow setting the marker text.
    markers.xMarkersText = (0..<results.columns).map { String($0) }
    markers.yMarkersText = (0..<results.rows).map    { String($0) }
    
    return (results, markers)
  }
  
  public func drawData(_ data: DrawingData, size: Size, renderer: Renderer) {
    guard let values = data.values else { return }
    
    var valueIterator = values.makeIterator()
    while let (row, column, value) = valueIterator.next() {
        let rect = Rect(
          origin: Point(Float(column) * data.itemSize.width,
                        Float(row) * data.itemSize.height),
          size: data.itemSize
        )
        let color = colorMap.colorForOffset(value)
        renderer.drawSolidRect(rect, fillColor: color, hatchPattern: .none)
        //        renderer.drawText(text: String(describing: element),
        //                          location: rect.origin + Point(50,50),
        //                          textSize: 20,
        //                          color: .white,
        //                          strokeWidth: 2,
        //                          angle: 0)
    }
  }
}

// MARK: - Convenience API.

//extension Heatmap where HeatmapConstraints.IsFloat<Element>: Any {
//
//    public init(_ values: SeriesType, style: (inout Self)->Void = { _ in }) {
//        self.init(values, mapping: .linear, style: style)
//    }
//}
//
//extension Heatmap where HeatmapConstraints.IsInteger<Element>: Any {
//
//    public init(_ values: SeriesType, style: (inout Self)->Void = { _ in }) {
//        self.init(values, mapping: .linear, style: style)
//    }
//}

// SequencePlots.
// 2D Datasets.
//
//extension SequencePlots where Base.Element: Sequence {
//
//    /// Returns a heatmap of values from this 2-dimensional sequence.
//    ///
//    /// - parameters:
//    ///   	- mapping:	A function or `KeyPath` which maps values to a continuum between 0 and 1.
//    ///		- style:	A closure which applies a style to the heatmap.
//    /// - returns:		A heatmap plot of the sequence's inner items.
//    ///
//    public func heatmap(
//        mapping: Mapping.Heatmap<Base.Element.Element>,
//        style: (inout Heatmap<Heatmappable2D<Base>>)->Void = { _ in }
//    ) -> Heatmap<Heatmappable2D<Base>> {
//        return Heatmap(Heatmappable2D(base: base), mapping: mapping, style: style)
//    }
//}

extension SequencePlots where Base.Element: Sequence, HeatmapConstraints.IsFloat<Base.Element.Element>: Any {

    /// Returns a heatmap of values from this 2-dimensional sequence.
    ///
    public func heatmap(
        style: (inout Heatmap<Heatmappable2D<Base>>)->Void = { _ in }
    ) -> Heatmap<Heatmappable2D<Base>> {
        return heatmap(mapping: .linear, style: style)
    }
}

extension SequencePlots where Base.Element: Sequence, HeatmapConstraints.IsInteger<Base.Element.Element>: Any {

    /// Returns a heatmap of values from this 2-dimensional sequence.
    ///
    public func heatmap(
        style: (inout Heatmap<Heatmappable2D<Base>>)->Void = { _ in }
    ) -> Heatmap<Heatmappable2D<Base>> {
        return heatmap(mapping: .linear, style: style)
    }
}

//// 1D Datasets (Collection).
//
//extension SequencePlots where Base: Collection {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:		The width of the heatmap to generate. Must be greater than 0.
//    ///   - mapping:	A function or `KeyPath` which maps values to a continuum between 0 and 1.
//    /// - returns:		A heatmap plot of the collection's values.
//    /// - complexity: 	O(n). Consider though, that rendering a heatmap or copying to a `RamdomAccessCollection`
//    ///               	is also at least O(n), and this does not copy the data.
//    ///
//    public func heatmap(
//        width: Int,
//        mapping: Mapping.Heatmap<Base.Element>,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//
//        precondition(width > 0, "Cannot build a heatmap with zero or negative width")
//        var rows = [Base.SubSequence]()
//        var rowStart = base.startIndex
//        while rowStart != base.endIndex {
//            guard let rowEnd = base.index(rowStart, offsetBy: width, limitedBy: base.endIndex) else {
//                rows.append(base[rowStart..<base.endIndex])
//                break
//            }
//            rows.append(base[rowStart..<rowEnd])
//            rowStart = rowEnd
//        }
//        return rows.plots.heatmap(mapping: mapping, style: style)
//    }
//}
//
//
//
//extension SequencePlots where Base: Collection, HeatmapConstraints.IsFloat<Base.Element>: Any {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:		The width of the heatmap to generate. Must be greater than 0.
//    /// - returns:		A heatmap plot of the collection's values.
//    /// - complexity:	O(n). Consider though, that rendering a heatmap or copying to a `RamdomAccessCollection`
//    ///               	is also at least O(n), and this does not copy the data.
//    ///
//    public func heatmap(
//        width: Int,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//        return heatmap(width: width, mapping: .linear, style: style)
//    }
//}
//
//extension SequencePlots where Base: Collection, HeatmapConstraints.IsInteger<Base.Element>: Any {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:		The width of the heatmap to generate. Must be greater than 0.
//    /// - returns:		A heatmap plot of the collection's values.
//    /// - complexity:	O(n). Consider though, that rendering a heatmap or copying to a `RamdomAccessCollection`
//    ///               	is also at least O(n), and this does not copy the data.
//    ///
//    public func heatmap(
//        width: Int,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//        return heatmap(width: width, mapping: .linear, style: style)
//    }
//}
//
//// 1D Datasets (RandomAccessCollection).
//
//extension SequencePlots where Base: RandomAccessCollection {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:		The width of the heatmap to generate. Must be greater than 0.
//    ///   - mapping:	A function or `KeyPath` which maps values to a continuum between 0 and 1.
//    /// - returns:		A heatmap plot of the collection's values.
//    ///
//    public func heatmap(
//        width: Int,
//        mapping: Mapping.Heatmap<Base.Element>,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//
//        func sliceForRow(_ row: Int, width: Int) -> Base.SubSequence {
//            guard let start = base.index(base.startIndex, offsetBy: row * width, limitedBy: base.endIndex) else {
//                return base[base.startIndex..<base.startIndex]
//            }
//            guard let end = base.index(start, offsetBy: width, limitedBy: base.endIndex) else {
//                return base[start..<base.endIndex]
//            }
//            return base[start..<end]
//        }
//
//        precondition(width > 0, "Cannot build a histogram with zero or negative width")
//        let height = Int((Float(base.count) / Float(width)).rounded(.up))
//        return (0..<height)
//            .map { sliceForRow($0, width: width) }
//            .plots.heatmap(mapping: mapping, style: style)
//    }
//}
//
//extension SequencePlots where Base: RandomAccessCollection, HeatmapConstraints.IsFloat<Base.Element>: Any {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:	The width of the heatmap to generate. Must be greater than 0.
//    /// - returns:  A heatmap plot of the collection's values.
//    ///
//    public func heatmap(
//        width: Int,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//        return heatmap(width: width, mapping: .linear, style: style)
//    }
//}
//
//extension SequencePlots where Base: RandomAccessCollection, HeatmapConstraints.IsInteger<Base.Element>: Any {
//
//    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
//    ///
//    /// - parameters:
//    ///   - width:	The width of the heatmap to generate. Must be greater than 0.
//    /// - returns:	A heatmap plot of the collection's values.
//    ///
//    public func heatmap(
//        width: Int,
//        style: (inout Heatmap<[Base.SubSequence]>)->Void = { _ in }
//    ) -> Heatmap<[Base.SubSequence]> {
//        return heatmap(width: width, mapping: .linear, style: style)
//    }
//}





// MARK: - Different take on it!



// MARK: 1D Datasets.

extension SequencePlots where Base: Collection {
    
    /// Returns a heatmap of this collection's values, generated by slicing rows with the given width.
    ///
    /// - parameters:
    ///   - width:        The width of the heatmap to generate. Must be greater than 0.
    ///   - mapping:      A function or `KeyPath` which maps values to a continuum between 0 and 1.
    /// - returns:        A heatmap plot of the collection's values.
    /// - complexity:     O(n). Consider though, that rendering a heatmap or copying to a `RamdomAccessCollection`
    ///                   is also at least O(n), and this does not copy the data.
    ///
    public func heatmap(
        width: Int,
        mapping: Mapping.Heatmap<Base.Element>,
        style: (inout Heatmap<Heatmappable1D<Base>>) -> Void = { _ in }
    ) -> Heatmap<Heatmappable1D<Base>> {
        
        precondition(width > 0, "Cannot build a heatmap with zero or negative width")
        return Heatmap(Heatmappable1D(base: base, width: width, mapping: mapping), style: style)
    }
}

// MARK: 2D Datasets.

extension SequencePlots where Base.Element: Sequence {
    
    /// Returns a heatmap of values from this 2-dimensional sequence.
    ///
    /// - parameters:
    ///       - mapping:  A function or `KeyPath` which maps values to a continuum between 0 and 1.
    ///       - style:    A closure which applies a style to the heatmap.
    /// - returns:        A heatmap plot of the sequence's inner items.
    ///
    public func heatmap(
        mapping: Mapping.Heatmap<Base.Element.Element>,
        style: (inout Heatmap<Heatmappable2D<Base>>) -> Void = { _ in }
    ) -> Heatmap<Heatmappable2D<Base>> {
        return Heatmap(Heatmappable2D(base: base, mapping: mapping), style: style)
    }
}
