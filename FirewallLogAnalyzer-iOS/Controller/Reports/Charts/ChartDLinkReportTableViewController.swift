//
//  ChartDLinkReportTableViewController.swift
//  FirewallLogAnalyzer-iOS
//
//  Created by Vadim Denisov on 10/05/2019.
//  Copyright © 2019 Vadim Denisov. All rights reserved.
//

import UIKit
import Charts
import SpreadsheetView

class ChartDLinkReportTableViewController: UITableViewController {
    
    enum Sorting {
        case ascending
        case descending
        
        var symbol: String {
            switch self {
            case .ascending:
                return "↑"
            case .descending:
                return "↓"
            }
        }
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var mostActiveChartView: PieChartView!
    @IBOutlet weak var liveTrafficChartView: BarChartView!
    @IBOutlet weak var liveTraffic24HoursChartView: LineChartView!
    @IBOutlet weak var severityLevelChartView: BarChartView!
    @IBOutlet weak var eventsChartView: BarChartView!
    @IBOutlet weak var protocolsChartView: PieChartView!
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    var sortedColumn = 0
    var sortedDirection: Sorting = .ascending
    var ip = "None"
    var minDate = Date()
    var maxDate = Date()
    var formatter = DateFormatter()
    var calendar = Calendar(identifier: .gregorian)
    var selectedCharts: [SelectCharts] = []
    var logs: [DLinkLog] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale.current
        
        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self
        spreadsheetView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        spreadsheetView.intercellSpacing = CGSize(width: 4, height: 1)
        spreadsheetView.bounces = false
        spreadsheetView.register(TextCell.self, forCellWithReuseIdentifier: String(describing: TextCell.self))
        
        dateLabel.text = "Date: \(formatter.string(from: minDate)) – \(formatter.string(from: maxDate))"
        ipLabel.text = "IP: \(ip)"
        countLabel.text = "Logs count: \(logs.count)"
        
        setupMostActiveChart()
        setupLivetTrafficChart()
        setupLiveTraffic24HoursChart()
        setupEventsChart()
        setupSeverityLevelChart()
        setupProtocolsChart()
        spreadsheetView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        spreadsheetView.flashScrollIndicators()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        switch row {
        case 0, 1, 2:
            return 44
        case 3:
            return selectedCharts.contains(.mostActive) ? 400 : 0
        case 4:
            return selectedCharts.contains(.liveTraffic) ? 400 : 0
        case 5:
            return selectedCharts.contains(.liveTraffic24Hours) ? 400 : 0
        case 6:
            return selectedCharts.contains(.events) ? 400 : 0
        case 7:
            return selectedCharts.contains(.severityLevel) ? 400 : 0
        case 8:
            return selectedCharts.contains(.protocols) ? 400 : 0
        case 9:
            return selectedCharts.contains(.tableOfLogs) ? spreadsheetView.contentSize.height : 0
        default:
            return 0
        }
    }
    
    func setupMostActiveChart() {
        mostActiveChartView.usePercentValuesEnabled = true
        mostActiveChartView.drawSlicesUnderHoleEnabled = false
        mostActiveChartView.holeRadiusPercent = 0.58
        mostActiveChartView.transparentCircleRadiusPercent = 0.61
        mostActiveChartView.chartDescription?.enabled = false
        mostActiveChartView.setExtraOffsets(left: 20, top: 0, right: 20, bottom: 0)
        
        mostActiveChartView.drawCenterTextEnabled = true
        
        mostActiveChartView.drawHoleEnabled = true
        mostActiveChartView.rotationAngle = 0
        mostActiveChartView.rotationEnabled = false
        mostActiveChartView.highlightPerTapEnabled = true
        
        let l = mostActiveChartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.xEntrySpace = 7
        l.yEntrySpace = 0
        l.yOffset = 0
        
        // entry label styling
        mostActiveChartView.entryLabelColor = .white
        mostActiveChartView.entryLabelFont = .systemFont(ofSize: 12, weight: .light)
        
        
        mostActiveChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        
        
        
        // Values
        var values: [PieChartDataEntry] = []
        var kasperskyValues: [String : Int] = [:]
        logs.forEach {
            if $0.srcIP != "" {
                kasperskyValues[$0.srcIP] = (kasperskyValues[$0.srcIP] ?? 0) + 1
            }
        }
        let kasperskySortedValues = kasperskyValues.sorted { $0.value > $1.value }
        
        let count = kasperskySortedValues.count > 15 ? 15 : kasperskySortedValues.count
        values = (0..<count).map { (i) -> PieChartDataEntry in
            return PieChartDataEntry(value: Double(kasperskySortedValues[i].value),
                                     label: kasperskySortedValues[i].key + " (\(kasperskySortedValues[i].value))")
        }
        
        let set = PieChartDataSet(values: values, label: "")
        set.sliceSpace = 2
        
        
        set.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]
        
        set.valueLinePart1OffsetPercentage = 0.8
        set.valueLinePart1Length = 0.2
        set.valueLinePart2Length = 0.4
        //set.xValuePosition = .outsideSlice
        set.yValuePosition = .outsideSlice
        
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueFont(.systemFont(ofSize: 11, weight: .light))
        data.setValueTextColor(.black)
        
        mostActiveChartView.data = data
        mostActiveChartView.highlightValues(nil)
    }
    
    func setupLivetTrafficChart() {
        liveTrafficChartView.drawBarShadowEnabled = false
        liveTrafficChartView.drawValueAboveBarEnabled = false
        liveTrafficChartView.doubleTapToZoomEnabled = false
        liveTrafficChartView.scaleYEnabled = false
        
        let xAxis = liveTrafficChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 7
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        
        let leftAxis = liveTrafficChartView.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0
        
        liveTrafficChartView.rightAxis.enabled = false
        
        let l = liveTrafficChartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.form = .circle
        l.formSize = 9
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.xEntrySpace = 4
        
        liveTrafficChartView.animate(yAxisDuration: 1.5)
        
        var logsCountByDate: [Date : Int] = [:]
        
        for log in logs {
            if log.formatterDate <= maxDate && log.formatterDate >= minDate {
                let date = formatter.date(from: formatter.string(from: log.formatterDate))!
                logsCountByDate[date] = (logsCountByDate[date] ?? 0) + 1
            }
        }
        
        let sortedLogsCountByDate = logsCountByDate.sorted(by: { (value1, value2) -> Bool in
            value1.key < value2.key
        })
        
        var days: [String] = []
        var values: [Double] = []
        sortedLogsCountByDate.forEach { (value) in
            days.append(formatter.string(from: value.key))
            values.append(Double(value.value))
        }
        liveTrafficChartView.setBarChartData(xValues: days, yValues: values, label: "Traffic count")
    }
    
    func setupLiveTraffic24HoursChart() {
        liveTraffic24HoursChartView.chartDescription?.enabled = false
        liveTraffic24HoursChartView.dragEnabled = false
        liveTraffic24HoursChartView.setScaleEnabled(false)
        liveTraffic24HoursChartView.pinchZoomEnabled = false
        
        let l = liveTraffic24HoursChartView.legend
        l.form = .line
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.textColor = .black
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        let xAxis = liveTraffic24HoursChartView.xAxis
        xAxis.labelCount = 23
        xAxis.spaceMin = 0
        xAxis.spaceMax = 0
        xAxis.labelFont = .systemFont(ofSize: 8)
        xAxis.labelTextColor = .black
        xAxis.labelPosition = .bottom
        xAxis.drawAxisLineEnabled = false
        
        let leftAxis = liveTraffic24HoursChartView.leftAxis
        leftAxis.labelTextColor = .black
        leftAxis.axisMaximum = 20
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        
        liveTraffic24HoursChartView.rightAxis.enabled = false
        
        liveTraffic24HoursChartView.animate(xAxisDuration: 1.5)
        
        var chartDataEntry: [ChartDataEntry] = []
        var logsCountForHour: [Int : Int] = [:]
        for i in 0..<24 {
            logsCountForHour[i] = 0
        }
        
        let maxDateEndDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: maxDate)!
        let maxDateBeginDay = formatter.date(from: formatter.string(from: maxDateEndDay))!
        for log in logs {
            if log.formatterDate <= maxDateEndDay && log.formatterDate >= maxDateBeginDay {
                let components = calendar.dateComponents([.day, .hour], from: log.formatterDate)
                logsCountForHour[components.hour!] = logsCountForHour[components.hour!]! + 1
            }
        }
        
        let sortedLogsCountForHour = logsCountForHour.sorted(by: { (value1, value2) -> Bool in
            value1.key < value2.key
        })
        sortedLogsCountForHour.forEach { (value) in
            chartDataEntry.append(ChartDataEntry(x: Double(value.key), y: Double(value.value)))
        }
        
        leftAxis.axisMaximum = Double.maximum(leftAxis.axisMaximum, chartDataEntry.max(by: { (value1, value2) -> Bool in
            value1.y < value2.y
        })!.y + 30)
        let set1 = LineChartDataSet(values: chartDataEntry, label: "Kaspersky")
        set1.axisDependency = .left
        set1.setColor(.red)
        set1.setCircleColor(.red)
        set1.lineWidth = 2
        set1.circleRadius = 3
        set1.fillAlpha = 65/255
        set1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        liveTraffic24HoursChartView.data = LineChartData(dataSet: set1)
    }
    
    func setupEventsChart() {
        eventsChartView.drawBarShadowEnabled = false
        eventsChartView.drawValueAboveBarEnabled = false
        eventsChartView.doubleTapToZoomEnabled = false
        eventsChartView.scaleYEnabled = false
        
        let xAxis = eventsChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 7
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        
        let leftAxis = eventsChartView.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0
        
        eventsChartView.rightAxis.enabled = false
        
        let l = eventsChartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.form = .circle
        l.formSize = 9
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.xEntrySpace = 4
        
        eventsChartView.animate(yAxisDuration: 1.5)
        
        var logsCountByDate: [String : Int] = [:]
        
        for log in logs {
            if log.formatterDate <= maxDate && log.formatterDate >= minDate {
                logsCountByDate[log.event] = (logsCountByDate[log.event] ?? 0) + 1
            }
        }
        
        let sortedLogsCountByDate = logsCountByDate.sorted(by: { (value1, value2) -> Bool in
            value1.key < value2.key
        })
        
        var events: [String] = []
        var values: [Double] = []
        sortedLogsCountByDate.forEach { (value) in
            events.append(value.key)
            values.append(Double(value.value))
        }
        eventsChartView.setBarChartData(xValues: events, yValues: values, label: "Events count")
    }
    
    func setupSeverityLevelChart() {
        severityLevelChartView.drawBarShadowEnabled = false
        severityLevelChartView.drawValueAboveBarEnabled = false
        severityLevelChartView.doubleTapToZoomEnabled = false
        severityLevelChartView.scaleYEnabled = false
        
        let xAxis = severityLevelChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 7
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        
        let leftAxis = severityLevelChartView.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0
        
        severityLevelChartView.rightAxis.enabled = false
        
        let l = severityLevelChartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.form = .circle
        l.formSize = 9
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.xEntrySpace = 4
        
        severityLevelChartView.animate(yAxisDuration: 1.5)
        var logsCountByDate: [String : Int] = [:]
        
        for log in logs {
            if log.formatterDate <= maxDate && log.formatterDate >= minDate {
                logsCountByDate[log.severity] = (logsCountByDate[log.severity] ?? 0) + 1
            }
        }
        
        let sortedLogsCountByDate = logsCountByDate.sorted(by: { (value1, value2) -> Bool in
            value1.key < value2.key
        })
        
        var events: [String] = []
        var values: [Double] = []
        sortedLogsCountByDate.forEach { (value) in
            events.append(value.key)
            values.append(Double(value.value))
        }
        severityLevelChartView.setBarChartData(xValues: events, yValues: values, label: "Events count")
    }
    
    func setupProtocolsChart() {
        protocolsChartView.usePercentValuesEnabled = true
        protocolsChartView.drawSlicesUnderHoleEnabled = false
        protocolsChartView.holeRadiusPercent = 0.58
        protocolsChartView.transparentCircleRadiusPercent = 0.61
        protocolsChartView.chartDescription?.enabled = false
        protocolsChartView.setExtraOffsets(left: 20, top: 0, right: 20, bottom: 0)
        
        protocolsChartView.drawCenterTextEnabled = true
        
        protocolsChartView.drawHoleEnabled = false
        protocolsChartView.rotationAngle = 0
        protocolsChartView.rotationEnabled = false
        protocolsChartView.highlightPerTapEnabled = false
        
        let l = protocolsChartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.xEntrySpace = 7
        l.yEntrySpace = 0
        l.yOffset = 0
        
        // entry label styling
        protocolsChartView.entryLabelColor = .white
        protocolsChartView.entryLabelFont = .systemFont(ofSize: 12, weight: .light)
        
        
        protocolsChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        
        
        
        // Values
        var values: [PieChartDataEntry] = []
        var kasperskyValues: [String : Int] = [:]
        logs.forEach {
            if $0.protocolNetwork != "" {
                kasperskyValues[$0.protocolNetwork] = (kasperskyValues[$0.protocolNetwork] ?? 0) + 1
            }
        }
        let kasperskySortedValues = kasperskyValues.sorted { $0.value > $1.value }
        
        let count = kasperskySortedValues.count > 15 ? 15 : kasperskySortedValues.count
        values = (0..<count).map { (i) -> PieChartDataEntry in
            return PieChartDataEntry(value: Double(kasperskySortedValues[i].value),
                                     label: kasperskySortedValues[i].key + " (\(kasperskySortedValues[i].value))")
        }
        
        let set = PieChartDataSet(values: values, label: "")
        set.sliceSpace = 2
        
        
        set.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]
        
        set.valueLinePart1OffsetPercentage = 1
        set.valueLinePart1Length = 0.2
        set.valueLinePart2Length = 0.4
        //set.xValuePosition = .outsideSlice
        set.yValuePosition = .outsideSlice
        
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueFont(.systemFont(ofSize: 11, weight: .light))
        data.setValueTextColor(.black)
        // hide percents
        data.setDrawValues(false)
        
        protocolsChartView.data = data
        protocolsChartView.highlightValues(nil)
    }
}

extension ChartDLinkReportTableViewController: SpreadsheetViewDataSource, SpreadsheetViewDelegate {
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return 24
    }
    
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return logs.count + 1
    }
    
    func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }
    
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
        return logs.count == 0 ? 0 : 1
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: String(describing: TextCell.self), for: indexPath) as! TextCell
        // For headers
        if indexPath.row == 0 {
            if indexPath.column == 0 {
                cell.label.text = "ID"
            }
            if indexPath.column == 1 {
                cell.label.text = "Date"
            }
            if indexPath.column == 2 {
                cell.label.text = "Time"
            }
            if indexPath.column == 3 {
                cell.label.text = "Severity"
            }
            if indexPath.column == 4 {
                cell.label.text = "Category"
            }
            if indexPath.column == 5 {
                cell.label.text = "ID of category"
            }
            if indexPath.column == 6 {
                cell.label.text = "Rule"
            }
            if indexPath.column == 7 {
                cell.label.text = "Protocol"
            }
            if indexPath.column == 8 {
                cell.label.text = "Source If"
            }
            if indexPath.column == 9 {
                cell.label.text = "Destination If"
            }
            if indexPath.column == 10 {
                cell.label.text = "Source IP"
            }
            if indexPath.column == 11 {
                cell.label.text = "Destination IP"
            }
            if indexPath.column == 12 {
                cell.label.text = "Source Port"
            }
            if indexPath.column == 13 {
                cell.label.text = "Destination Port"
            }
            if indexPath.column == 14 {
                cell.label.text = "Event"
            }
            if indexPath.column == 15 {
                cell.label.text = "Action"
            }
            if indexPath.column == 16 {
                cell.label.text = "Connection"
            }
            if indexPath.column == 17 {
                cell.label.text = "Connection New Src IP"
            }
            if indexPath.column == 18 {
                cell.label.text = "Connection New Src Port"
            }
            if indexPath.column == 19 {
                cell.label.text = "Connection New Dst IP"
            }
            if indexPath.column == 20 {
                cell.label.text = "Connection New Dst Port"
            }
            if indexPath.column == 21 {
                cell.label.text = "OrigSent"
            }
            if indexPath.column == 22 {
                cell.label.text = "TermSent"
            }
            if indexPath.column == 23 {
                cell.label.text = "Connection Time"
            }
            
            if indexPath.column == sortedColumn {
                cell.label.text = (cell.label.text ?? "") + sortedDirection.symbol
            }
            return cell
        }
        
        // For information
        let log = logs[indexPath.row - 1]
        if indexPath.column == 0 {
            cell.label.text = "\(log.id)"
        }
        if indexPath.column == 1 {
            cell.label.text = log.date
        }
        if indexPath.column == 2 {
            cell.label.text = log.time
        }
        if indexPath.column == 3 {
            cell.label.text = log.severity
        }
        if indexPath.column == 4 {
            cell.label.text = log.category
        }
        if indexPath.column == 5 {
            cell.label.text = log.categoryID
        }
        if indexPath.column == 6 {
            cell.label.text = log.rule
        }
        if indexPath.column == 7 {
            cell.label.text = log.protocolNetwork
        }
        if indexPath.column == 8 {
            cell.label.text = log.srcIf
        }
        if indexPath.column == 9 {
            cell.label.text = log.dstIf
        }
        if indexPath.column == 10 {
            cell.label.text = log.srcIP
        }
        if indexPath.column == 11 {
            cell.label.text = log.dstIP
        }
        if indexPath.column == 12 {
            cell.label.text = log.srcPort
        }
        if indexPath.column == 13 {
            cell.label.text = log.dstPort
        }
        if indexPath.column == 14 {
            cell.label.text = log.event
        }
        if indexPath.column == 15 {
            cell.label.text = log.action
        }
        if indexPath.column == 16 {
            cell.label.text = log.conn
        }
        if indexPath.column == 17 {
            cell.label.text = log.connNewSrcIP
        }
        if indexPath.column == 18 {
            cell.label.text = log.connNewSrcPort
        }
        if indexPath.column == 19 {
            cell.label.text = log.connNewDstIP
        }
        if indexPath.column == 20 {
            cell.label.text = log.connNewDstPort
        }
        if indexPath.column == 21 {
            cell.label.text = log.origSent
        }
        if indexPath.column == 22 {
            cell.label.text = log.termSent
        }
        if indexPath.column == 23 {
            cell.label.text = log.connTime
        }
        return cell
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        return 40
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        if column == 6 {
            return 120
        }
        if column == 14 {
            return 160
        }
        if column == 17 {
            return 120
        }
        if column == 18 {
            return 130
        }
        if column == 19 {
            return 120
        }
        if column == 20 {
            return 130
        }
        if column == 23 {
            return 90
        }
        return 80
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if sortedColumn == indexPath.column {
                if sortedDirection == .ascending {
                    sortedDirection = .descending
                } else {
                    sortedDirection = .ascending
                }
            } else {
                sortedColumn = indexPath.column
                sortedDirection = .ascending
            }
            
            if indexPath.column == 0 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.id < $1.id })
                } else {
                    logs = logs.sorted(by: { $0.id > $1.id })
                }
            }
            if indexPath.column == 1 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.date < $1.date })
                } else {
                    logs = logs.sorted(by: { $0.date > $1.date })
                }
            }
            if indexPath.column == 2 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.time < $1.time })
                } else {
                    logs = logs.sorted(by: { $0.time > $1.time })
                }
            }
            if indexPath.column == 3 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.severity < $1.severity })
                } else {
                    logs = logs.sorted(by: { $0.severity > $1.severity })
                }
            }
            if indexPath.column == 4 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.category < $1.category })
                } else {
                    logs = logs.sorted(by: { $0.category > $1.category })
                }
            }
            if indexPath.column == 5 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.categoryID < $1.categoryID })
                } else {
                    logs = logs.sorted(by: { $0.categoryID > $1.categoryID })
                }
            }
            if indexPath.column == 6 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.rule < $1.rule })
                } else {
                    logs = logs.sorted(by: { $0.rule > $1.rule })
                }
            }
            if indexPath.column == 7 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.protocolNetwork < $1.protocolNetwork })
                } else {
                    logs = logs.sorted(by: { $0.protocolNetwork > $1.protocolNetwork })
                }
            }
            if indexPath.column == 8 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.srcIf < $1.srcIf })
                } else {
                    logs = logs.sorted(by: { $0.srcIf > $1.srcIf })
                }
            }
            if indexPath.column == 9 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.dstIf < $1.dstIf })
                } else {
                    logs = logs.sorted(by: { $0.dstIf > $1.dstIf })
                }
            }
            if indexPath.column == 10 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.srcIP < $1.srcIP })
                } else {
                    logs = logs.sorted(by: { $0.srcIP > $1.srcIP })
                }
            }
            if indexPath.column == 11 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.srcPort < $1.srcPort })
                } else {
                    logs = logs.sorted(by: { $0.srcPort > $1.srcPort })
                }
            }
            if indexPath.column == 12 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.dstPort < $1.dstPort })
                } else {
                    logs = logs.sorted(by: { $0.dstPort > $1.dstPort })
                }
            }
            if indexPath.column == 13 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.dstPort < $1.dstPort })
                } else {
                    logs = logs.sorted(by: { $0.dstPort > $1.dstPort })
                }
            }
            if indexPath.column == 14 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.event < $1.event })
                } else {
                    logs = logs.sorted(by: { $0.event > $1.event })
                }
            }
            if indexPath.column == 15 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.action < $1.action })
                } else {
                    logs = logs.sorted(by: { $0.action > $1.action })
                }
            }
            if indexPath.column == 16 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.conn < $1.conn })
                } else {
                    logs = logs.sorted(by: { $0.conn > $1.conn })
                }
            }
            if indexPath.column == 17 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.connNewSrcIP < $1.connNewSrcIP })
                } else {
                    logs = logs.sorted(by: { $0.connNewSrcIP > $1.connNewSrcIP })
                }
            }
            if indexPath.column == 18 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.connNewSrcPort < $1.connNewSrcPort })
                } else {
                    logs = logs.sorted(by: { $0.connNewSrcPort > $1.connNewSrcPort })
                }
            }
            if indexPath.column == 19 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.connNewDstIP < $1.connNewDstIP })
                } else {
                    logs = logs.sorted(by: { $0.connNewDstIP > $1.connNewDstIP })
                }
            }
            if indexPath.column == 20 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.connNewDstPort < $1.connNewDstPort })
                } else {
                    logs = logs.sorted(by: { $0.connNewDstPort > $1.connNewDstPort })
                }
            }
            if indexPath.column == 21 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.origSent < $1.origSent })
                } else {
                    logs = logs.sorted(by: { $0.origSent > $1.origSent })
                }
            }
            if indexPath.column == 22 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.termSent < $1.termSent })
                } else {
                    logs = logs.sorted(by: { $0.termSent > $1.termSent })
                }
            }
            if indexPath.column == 23 {
                if sortedDirection == .ascending {
                    logs = logs.sorted(by: { $0.connTime < $1.connTime })
                } else {
                    logs = logs.sorted(by: { $0.connTime > $1.connTime })
                }
            }
            spreadsheetView.reloadData()
        }
        
        // IP address
        if indexPath.row != 0 {
            var ip = ""
            let log = logs[indexPath.row - 1]
            if indexPath.column == 10 { ip = log.srcIP }
            if indexPath.column == 11 { ip = log.dstIP }
            if indexPath.column == 17 { ip = log.connNewSrcIP }
            if indexPath.column == 19 { ip = log.connNewDstIP }
            if ip == "" { return }
            let alert = UIAlertController(title: "Show IP Geolocation?", message: ip, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Show", style: .default, handler: { _ in
                self.tabBarController?.selectedIndex = 3
                let ipGeolocationController = (self.tabBarController?.viewControllers?[3] as? UINavigationController)?.topViewController as? IPGeolocationTableViewController
                ipGeolocationController?.search(ip: ip)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}