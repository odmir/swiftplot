public struct PlotLabel{
    public var xLabel: String = "X-Axis"
    public var yLabel: String = "Y-Axis"
    public var labelSize: Float = 15
    public var xLabelLocation = zeroPoint
    public var yLabelLocation = zeroPoint
    public init(xLabel: String, yLabel: String, labelSize: Float = 15) {
      self.xLabel = xLabel
      self.yLabel = yLabel
      self.labelSize = labelSize
    }
}