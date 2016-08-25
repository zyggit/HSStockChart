//
//  KLineStockChartView.swift
//  MyStockChartDemo
//
//  Created by Hanson on 16/8/22.
//  Copyright © 2016年 hanson. All rights reserved.
//

import UIKit

class KLineStockChartView: BaseStockChartView {

    var dataSet: KLineDataSet?
    var candleCoordsScale: CGFloat = 0
    var volumeCoordsScale: CGFloat = 0
    var candleWidth: CGFloat = 8
    var monthLineLimit = 0
    var candleMaxWidth: CGFloat = 30
    var candleMinWidth: CGFloat = 5
    
    var countOfshowCandle: Int {
        get{
            return Int(contentWidth / candleWidth)
        }
    }
    var _startDrawIndex: Int = 0
    var startDrawIndex : Int {
        get{
            return _startDrawIndex
        }
        set(value){
            var temp = 0
            if (value < 0) {
                temp = 0
            }else{
                temp = value
            }
            if (temp + self.countOfshowCandle > self.dataSet!.data!.count) {
                temp = self.dataSet!.data!.count - self.countOfshowCandle
            }
            _startDrawIndex = temp
        }
    }
    
    var panGesture: UIPanGestureRecognizer {
        get{
            return UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureAction(_:)))
        }
    }
    
    var pinGesture: UIPinchGestureRecognizer {
        get{
            return UIPinchGestureRecognizer(target: self, action: #selector(handlePinGestureAction(_:)))
        }
    }
    
    var longPressGesture: UILongPressGestureRecognizer {
        get{
            return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureAction(_:)))
        }
    }
    
    var tapGesture: UITapGestureRecognizer {
        get{
            return UITapGestureRecognizer(target: self, action: #selector(handleTapGestureAction(_:)))
        }
    }
    
    var lastPinScale: CGFloat = 0
    
    // MARK: - Initialize
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(longPressGesture)
        self.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(pinGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if let data  = self.dataSet?.data where data.count > 0{
            let context = UIGraphicsGetCurrentContext()
            self.setCurrentDataMaxAndMin()
            self.drawGridBackground(context!, rect: rect)
            self.drawCandleLine(context!, data: data)
            self.drawLabelPrice(context!)
        }
    }
    
    func setUpData(dataSet: KLineDataSet) {
        if let d = dataSet.data where self.countOfshowCandle > 0 {

            self.dataSet = dataSet
            //dataSet.data = [KLineEntity](d)
            
            if d.count > self.countOfshowCandle {
                self.startDrawIndex = d.count - self.countOfshowCandle
            }
            self.self.setNeedsDisplay()
            
        } else {
            //self.showFailStatusView()
        }
    }

    
    // MARK: - Function
    
    func setCurrentDataMaxAndMin() {
        if let data = self.dataSet?.data where data.count > 0 {
            self.maxPrice = CGFloat.min
            self.minPrice = CGFloat.max
            self.maxRatio = CGFloat.min
            self.minRatio = CGFloat.max
            self.maxVolume = CGFloat.min
            let startIndex = self.startDrawIndex
            //data.count
            let count = (startIndex + countOfshowCandle) > data.count ? data.count : (startIndex + countOfshowCandle)
            for i in startIndex ..< count {
                let entity = data[i]
                self.minPrice = self.minPrice < entity.low ? self.minPrice : entity.low
                self.maxPrice = self.maxPrice > entity.high ? self.maxPrice : entity.high
                self.maxVolume = self.maxVolume > entity.volume ? self.maxVolume : entity.volume
            }
        }
    }
    
    override func drawGridBackground(context: CGContextRef,rect: CGRect) {
        super.drawGridBackground(context, rect: rect)
        
        //内上边线
        self.drawline(context,
                      startPoint: CGPointMake(self.contentLeft, self.contentInnerTop),
                      stopPoint: CGPointMake(self.contentLeft + self.contentWidth, self.contentInnerTop),
                      color: self.borderColor,
                      lineWidth: self.borderWidth/2.0)
        //内下边线
        self.drawline(context,
                      startPoint: CGPointMake(self.contentLeft, uperChartHeight),
                      stopPoint: CGPointMake(self.contentLeft + self.contentWidth, self.contentTop + uperChartHeight - gapBetweenInnerAndOuterRect),
                      color: self.borderColor,
                      lineWidth: self.borderWidth / 2.0)
        
        //画中间的线
        self.drawline(context,
                      startPoint: CGPointMake(self.contentLeft, uperChartHeight / 2.0 + self.contentTop),
                      stopPoint: CGPointMake(self.contentRight, uperChartHeight /  2.0 + self.contentTop),
                      color: self.borderColor,
                      lineWidth: self.borderWidth/2.0)

    }
    
    //画纵坐标标签
    func drawLabelPrice(context: CGContextRef) {
        drawYAxisLabel(context, max: maxPrice, mid: (maxPrice + minPrice) / 2.0, min: minPrice)
    }
    
    // 画 K 线
    func drawCandleLine(context: CGContextRef, data: [KLineEntity]) {
        CGContextSaveGState(context)
        
        var oldDate: NSDate?
        let idex = self.startDrawIndex
        
        self.candleCoordsScale = (self.uperChartHeightScale * self.contentInnerHeight) / (self.maxPrice-self.minPrice)
//        self.volumeCoordsScale = (self.contentInnerHeight - (self.uperChartHeightScale * self.contentInnerHeight)-self.xAxisHeitht)/(self.maxVolume - 0)
//        
//        self.candleCoordsScale = (self.contentInnerHeight) / (self.maxPrice - self.minPrice)
        self.volumeCoordsScale = (self.contentHeight - uperChartHeight - self.xAxisHeitht) / self.maxVolume
        
        for i in idex ..< data.count {
            let entity = data[i]
            let open = ((self.maxPrice - entity.open) * self.candleCoordsScale) + self.contentInnerTop
            let close = ((self.maxPrice - entity.close) * self.candleCoordsScale) + self.contentInnerTop
            let high = ((self.maxPrice - entity.high) * self.candleCoordsScale) + self.contentInnerTop
            let low = ((self.maxPrice - entity.low) * self.candleCoordsScale) + self.contentInnerTop
            let left = (self.candleWidth * CGFloat(i - idex) + self.contentLeft) + self.candleWidth / 6.0
            
            let candleWidth = self.candleWidth - self.candleWidth / 6.0
            let startX = left + candleWidth / 2.0
            
            //画表格灰色竖线
            if let date = entity.date.toDate("yyyy-MM-dd") {
                if oldDate == nil {
                    oldDate = date
                }
                if date.year > oldDate?.year || date.month > oldDate!.month + monthLineLimit {
                    self.drawline(context,
                                  startPoint: CGPointMake(startX, self.contentTop),
                                  stopPoint: CGPointMake(startX,  uperChartHeight + self.contentTop), color: self.borderColor, lineWidth: 0.5)
                    
                    self.drawline(context,
                                  startPoint: CGPointMake(startX, uperChartHeight + self.xAxisHeitht),
                                  stopPoint: CGPointMake(startX,self.contentBottom), color: self.borderColor, lineWidth: 0.5)
                    
                    if !self.longPressToHighlightEnabled{
                        let drawAttributes = self.xAxisAttributedDic
                        let dateStrAtt = NSMutableAttributedString(string: date.toString("yyyy-MM"), attributes: drawAttributes)
                        let dateStrAttSize = dateStrAtt.size()
                        self.drawLabel(context,
                                       attributesText: dateStrAtt,
                                       rect: CGRectMake(startX - dateStrAttSize.width/2, (uperChartHeight + self.contentTop), dateStrAttSize.width,dateStrAttSize.height))
                    }
                    oldDate = date
                }
                
            }
            
            var color = self.dataSet?.candleRiseColor
            if open < close {
                color = self.dataSet?.candleFallColor
                self.drawColumnRect(context, rect: CGRectMake(left, open, candleWidth, close - open), color: color!)
                self.drawline(context, startPoint: CGPointMake(startX, high), stopPoint: CGPointMake(startX, low), color: color!, lineWidth: self.dataSet!.candleTopBottmLineWidth)
                
            } else if open == close {
                if i > 1{
                    let lastEntity = data[i-1]
                    if lastEntity.close > entity.close{
                        color = self.dataSet?.candleFallColor
                    }
                }
                
                self.drawColumnRect(context, rect: CGRectMake(left, open, candleWidth, 1.5), color: color!)
                self.drawline(context, startPoint: CGPointMake(startX, high), stopPoint: CGPointMake(startX, low), color: color!, lineWidth: self.dataSet!.candleTopBottmLineWidth)
                
            } else {
                color = self.dataSet?.candleRiseColor
                self.drawColumnRect(context, rect: CGRectMake(left, close, candleWidth, open-close), color: color!)
                self.drawline(context, startPoint: CGPointMake(startX, high), stopPoint: CGPointMake(startX, low), color: color!, lineWidth: self.dataSet!.candleTopBottmLineWidth)
            }
            
            if i > 0 {
//                let lastEntity = data[i-1]
//                let lastX = startX - self.candleWidth
//                
//                let lastY5 = (self.maxPrice - lastEntity.ma5)*self.candleCoordsScale + self.contentTop
//                let  y5 = (self.maxPrice - entity.ma5)*self.candleCoordsScale  + self.contentTop
//                self.drawline(context, startPoint: CGPointMake(lastX, lastY5), stopPoint: CGPointMake(startX, y5), color: self.dataSet!.avgMA5Color, lineWidth: self.dataSet!.avgLineWidth)
//                
//                let lastY10 = (self.maxPrice - lastEntity.ma10)*self.candleCoordsScale  + self.contentTop
//                let  y10 = (self.maxPrice - entity.ma10)*self.candleCoordsScale  + self.contentTop
//                self.drawline(context, startPoint: CGPointMake(lastX, lastY10) , stopPoint: CGPointMake(startX, y10), color: self.dataSet!.avgMA10Color, lineWidth: self.dataSet!.avgLineWidth)
//                
//                let lastY20 = (self.maxPrice - lastEntity.ma20)*self.candleCoordsScale  + self.contentTop
//                let  y20 = (self.maxPrice - entity.ma20)*self.candleCoordsScale  + self.contentTop
//                self.drawline(context, startPoint: CGPointMake(lastX, lastY20), stopPoint: CGPointMake(startX, y20), color: self.dataSet!.avgMA20Color, lineWidth: self.dataSet!.avgLineWidth)
//                
                
                //成交量
                let volume = ((entity.volume - 0) * self.volumeCoordsScale)
                self.drawColumnRect(context,rect:CGRectMake(left, self.contentBottom - volume , candleWidth, volume) ,color:color!)
            }
        }
        
        //长按显示线条
        for i in idex  ..< data.count  {
            let entity = data[i]
            let close = ((self.maxPrice - entity.close) * self.candleCoordsScale) + self.contentTop
            let left = (self.candleWidth * CGFloat(i - idex) + self.contentLeft) + self.candleWidth / 6.0
            
            let candleWidth = self.candleWidth - self.candleWidth / 6.0
            let startX = left + candleWidth/2.0
            
            if self.longPressToHighlightEnabled {
                if i == self.highlightLineCurrentIndex {
                    var entity:KLineEntity?
                    if i < data.count {
                        entity = data[i]
                    }
                    self.drawLongPressHighlight(context,
                                                pricePoint: CGPointMake(startX, close),
                                                volumePoint: CGPointMake(startX, close),
                                                idex: idex,
                                                value: entity!,
                                                color: self.dataSet!.highlightLineColor,
                                                lineWidth: self.dataSet!.highlightLineWidth)
//                    self.drawAvgMarker(context, idex: i)
//                    if delegate != nil{
//                        self.delegate!.chartValueSelected?(self, entry: entity!, entryIndex: i)
//                    }
                }
            }
            
        }
        
        if !self.longPressToHighlightEnabled{
//            self.drawAvgMarker(context, idex: 0)
        }
        
        CGContextRestoreGState(context)
    }
    
    func handlePanGestureAction(recognizer: UIPanGestureRecognizer) {
        self.longPressToHighlightEnabled = false
        
        var isPanRight = false
        let point = recognizer.translationInView(self) //获得拖动的信息
        
        if (recognizer.state == UIGestureRecognizerState.Began) {
        }
        if (recognizer.state == UIGestureRecognizerState.Changed) {
        }
        
        let offset = point.x
        if point.x > 0 {
            
            let temp = offset / self.candleWidth
            var moveCount = 0
            if temp <= 1 {
                moveCount = 1
                
            }else {
                moveCount = Int(temp)
            }
            
            print("moveCount: " + "\(moveCount)")
            
            self.startDrawIndex = self.startDrawIndex - moveCount
            if self.startDrawIndex < 10 {
//                if self.delegate != nil {
//                    self.delegate?.chartKlineScrollLeft!(self)
//                }
            }
            
        } else {
            // 判断是否拖动到右边缘尽头
            let count = Int(CGFloat(self.startDrawIndex + self.countOfshowCandle) + (-offset/self.candleWidth))
            if count > self.dataSet?.data?.count {
                isPanRight = true
                print("isPanRight  " + "\(isPanRight)")
            }
            
            let temp = (-offset) / self.candleWidth
            var moveCount = 0
            if temp <= 1 {
                moveCount = 1
                
            } else {
                moveCount = Int(temp)
            }
            
            self.startDrawIndex += moveCount
            //TODO:回弹效果
//            if startDrawIndex > self.dataSet?.data?.count {
//                self.startDrawIndex = self.dataSet!.data!.count - self.countOfshowCandle
//            }
        }
        
        if recognizer.state == UIGestureRecognizerState.Ended {
            if isPanRight {
                self.startDrawIndex = self.dataSet!.data!.count - self.countOfshowCandle
                print("startDrawIndex  " + "\(startDrawIndex)")
//                self.notifyDataSetChanged()
            }
        }
        
        self.setNeedsDisplay()
        
        // 切换回零点，不然拖动的速度变快
        recognizer.setTranslation(CGPointZero, inView: self)
    }
    
    func handlePinGestureAction(recognizer: UIPinchGestureRecognizer) {
        self.longPressToHighlightEnabled = false
        
        if recognizer.state == .Began {
            self.lastPinScale = 1.0
        }
        
        print("lastScale: " + "\(self.lastPinScale)")
        print("thisScale: " + "\(recognizer.scale)")
        
        recognizer.scale = 1 - (self.lastPinScale - recognizer.scale)
        
        print("currentScale" + "\(recognizer.scale)")
        self.candleWidth = recognizer.scale * self.candleWidth
        
        if self.candleWidth > self.candleMaxWidth {
            self.candleWidth = self.candleMaxWidth
        }
        
        if self.candleWidth < self.candleMinWidth {
            self.candleWidth = self.candleMinWidth
        }
        
//        self.startDrawIndex = self.dataSet!.data!.count - self.countOfshowCandle
        self.setNeedsDisplay()
        self.lastPinScale = recognizer.scale
    }
    
    func handleTapGestureAction(recognizer: UIPanGestureRecognizer) {
        
    }
    
    func handleLongPressGestureAction(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .Began || recognizer.state == .Changed {
            let  point = recognizer.locationInView(self)
            
            if (point.x > contentLeft && point.x < contentRight && point.y > contentTop && point.y < contentBottom) {
                self.longPressToHighlightEnabled = true
                self.highlightLineCurrentIndex = startDrawIndex + Int((point.x - contentLeft) / candleWidth)
                self.setNeedsDisplay()
            }
            if self.highlightLineCurrentIndex < self.dataSet?.data?.count {
                // TODO: 添加 notification 通知显示 viewcontroller 显示具体信息的 view
            }
        }
        
        if recognizer.state == .Ended {
            self.longPressToHighlightEnabled = false
            self.setNeedsDisplay()
            if self.highlightLineCurrentIndex < self.dataSet?.data?.count {
                // TODO: 添加 notification 通知显示 viewcontroller 隐藏 显示具体信息的 view
            }
        }
    }
    
}
