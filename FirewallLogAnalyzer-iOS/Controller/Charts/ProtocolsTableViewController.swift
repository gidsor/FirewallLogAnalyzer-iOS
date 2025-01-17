//
//  ProtocolsTableViewController.swift
//  FirewallLogAnalyzer-iOS
//
//  Created by Vadim Denisov on 08/05/2019.
//  Copyright © 2019 Vadim Denisov. All rights reserved.
//

import UIKit
import Charts

class ProtocolsTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate  {
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var chartView: PieChartView!
    @IBOutlet weak var minDateButton: UIButton!
    @IBOutlet weak var maxDateButton: UIButton!
    @IBOutlet weak var logsCountLabel: UILabel!
    @IBOutlet weak var ipButton: UIButton!
    var minDate = Date()
    var maxDate = Date()
    var toolBar = UIToolbar()
    var datePicker  = UIDatePicker()
    var ipPicker = UIPickerView()
    var isMinDate = false
    var isMaxDate = false
    var formatter = DateFormatter()
    var sourceKasperskyLogs: [KasperskyLog] = []
    var sourceTPLinkLogs: [TPLinkLog] = []
    var sourceDLinkLogs: [DLinkLog] = []
    var kasperskyLogs: [KasperskyLog] = []
    var tplinkLogs: [TPLinkLog] = []
    var dlinkLogs: [DLinkLog] = []
    var ipKaspersky: [String] = []
    var ipDLink: [String] = []
    var ipTPLink: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale.current
        
        var kasperskyLoaded = false
        var tplinkLoaded = false
        var dlinkLoaded = false
        
        minDate = formatter.date(from: "01.01.2000") ?? Date()
        maxDate = formatter.date(from: formatter.string(from: Date())) ?? Date()
        minDateButton.setTitle(self.formatter.string(from: minDate), for: .normal)
        maxDateButton.setTitle(self.formatter.string(from: maxDate), for: .normal)
        
        showActivityIndicator(in: view)
        NetworkManager.shared.updateKasperskyLogFiles { (status, logs) in
            if status == .unknown {
                self.showAlert(type: .noInternetConnection)
                return
            }
            self.sourceKasperskyLogs = logs
            self.kasperskyLogs = logs
            self.ipKaspersky = logs.map { $0.ipAddress }
            self.ipKaspersky = self.ipKaspersky.filter { $0 != "" }
            self.ipKaspersky = Array(Set(self.ipKaspersky))
            kasperskyLoaded = true
            if kasperskyLoaded && tplinkLoaded && dlinkLoaded {
                self.hideActivityIndicator(in: self.view)
                self.setupChart()
            }
        }
        
        NetworkManager.shared.updateTPLinkLogFiles { (status, logs) in
            if status == .unknown {
                self.showAlert(type: .noInternetConnection)
                return
            }
            self.sourceTPLinkLogs = logs
            self.tplinkLogs = logs
            self.ipTPLink = logs.map { $0.ipAddress }
            self.ipTPLink = self.ipTPLink.filter { $0 != "" }
            self.ipTPLink = Array(Set(self.ipTPLink))
            tplinkLoaded = true
            if kasperskyLoaded && tplinkLoaded && dlinkLoaded {
                self.hideActivityIndicator(in: self.view)
                self.setupChart()
            }
        }
        
        NetworkManager.shared.updateDLinkLogFiles { (status, logs) in
            if status == .unknown {
                self.showAlert(type: .noInternetConnection)
                return
            }
            self.sourceDLinkLogs = logs
            self.dlinkLogs = logs
            self.ipDLink = logs.map { $0.srcIP }
            self.ipDLink = self.ipDLink.filter { $0 != "" }
            self.ipDLink = Array(Set(self.ipDLink))
            dlinkLoaded = true
            if kasperskyLoaded && tplinkLoaded && dlinkLoaded {
                self.hideActivityIndicator(in: self.view)
                self.setupChart()
            }
        }
    }
    
    @IBAction func changeFirewallType(_ sender: UISegmentedControl) {
        setupChart()
    }
    
    @IBAction func setIPButton(_ sender: UIButton) {
        toolBar.removeFromSuperview()
        ipPicker.removeFromSuperview()
        datePicker.removeFromSuperview()
        ipPicker = UIPickerView()
        ipPicker.backgroundColor = .white
        ipPicker.autoresizingMask = .flexibleWidth
        ipPicker.delegate = self
        ipPicker.frame = CGRect(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        view.addSubview(ipPicker)
        toolBar = UIToolbar(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
        toolBar.barStyle = .default
        toolBar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onDoneButtonClick))]
        toolBar.sizeToFit()
        view.addSubview(toolBar)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            return ipDLink.count + 1
        } else if segmentControl.selectedSegmentIndex == 1 {
            return ipTPLink.count + 1
        } else if segmentControl.selectedSegmentIndex == 2 {
            return ipKaspersky.count + 1
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            ipButton.setTitle("None", for: .normal)
        } else if segmentControl.selectedSegmentIndex == 0 {
            ipButton.setTitle(ipDLink[row - 1], for: .normal)
        } else if segmentControl.selectedSegmentIndex == 1 {
            ipButton.setTitle(ipTPLink[row - 1], for: .normal)
        } else if segmentControl.selectedSegmentIndex == 2 {
            ipButton.setTitle(ipKaspersky[row - 1], for: .normal)
        } else {
            ipButton.setTitle("None", for: .normal)
        }
        update()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "None"
        }
        if segmentControl.selectedSegmentIndex == 0 {
            return ipDLink[row - 1]
        } else if segmentControl.selectedSegmentIndex == 1 {
            return ipTPLink[row - 1]
        } else if segmentControl.selectedSegmentIndex == 2 {
            return ipKaspersky[row - 1]
        } else {
            return "None"
        }
    }
    
    
    @IBAction func setDateButton(_ sender: UIButton) {
        toolBar.removeFromSuperview()
        datePicker.removeFromSuperview()
        ipPicker.removeFromSuperview()
        datePicker = UIDatePicker()
        if sender == minDateButton {
            isMinDate = true
            isMaxDate = false
            datePicker.setDate(formatter.date(from: minDateButton.title(for: .normal) ?? "01.01.2000") ?? Date(), animated: true)
        } else {
            isMinDate = false
            isMaxDate = true
            datePicker.setDate(formatter.date(from: maxDateButton.title(for: .normal) ?? "01.01.2000") ?? Date(), animated: true)
        }
        datePicker.backgroundColor = UIColor.white
        
        datePicker.autoresizingMask = .flexibleWidth
        datePicker.datePickerMode = .date
        
        datePicker.addTarget(self, action: #selector(self.dateChanged(_:)), for: .valueChanged)
        datePicker.frame = CGRect(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        self.view.addSubview(datePicker)
        
        toolBar = UIToolbar(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
        toolBar.barStyle = .default
        toolBar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onDoneButtonClick))]
        toolBar.sizeToFit()
        view.addSubview(toolBar)
    }
    
    @objc func dateChanged(_ sender: UIDatePicker?) {
        update()
    }
    
    func update() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        if isMinDate {
            minDate = datePicker.date
            minDateButton.setTitle(formatter.string(from: datePicker.date), for: .normal)
        } else if isMaxDate {
            maxDate = datePicker.date
            maxDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: maxDate) ?? Date()
            maxDateButton.setTitle(formatter.string(from: datePicker.date), for: .normal)
        }
        let ip = ipButton.title(for: .normal) ?? "None"
        kasperskyLogs = sourceKasperskyLogs.filter({ (log) -> Bool in
            if ip == "None" {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate
            } else {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate && log.ipAddress == ip
            }
        })
        tplinkLogs = sourceTPLinkLogs.filter({ (log) -> Bool in
            if ip == "None" {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate
            } else {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate && log.ipAddress == ip
            }
        })
        dlinkLogs = sourceDLinkLogs.filter({ (log) -> Bool in
            if ip == "None" {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate
            } else {
                return log.formatterDate <= maxDate && log.formatterDate >= minDate && log.srcIP == ip
            }
        })
        setupChart()
    }
    
    @objc func onDoneButtonClick() {
        update()
        toolBar.removeFromSuperview()
        ipPicker.removeFromSuperview()
        datePicker.removeFromSuperview()
    }
    
    func setupChart() {
        chartView.usePercentValuesEnabled = true
        chartView.drawSlicesUnderHoleEnabled = false
        chartView.holeRadiusPercent = 0.58
        chartView.transparentCircleRadiusPercent = 0.61
        chartView.chartDescription?.enabled = false
        chartView.setExtraOffsets(left: 20, top: 0, right: 20, bottom: 0)
        
        chartView.drawCenterTextEnabled = true
        
        chartView.drawHoleEnabled = false
        chartView.rotationAngle = 0
        chartView.rotationEnabled = false
        chartView.highlightPerTapEnabled = false
        
        let l = chartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.xEntrySpace = 7
        l.yEntrySpace = 0
        l.yOffset = 0
        
        // entry label styling
        chartView.entryLabelColor = .white
        chartView.entryLabelFont = .systemFont(ofSize: 12, weight: .light)
        
        
        chartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        
        
        
        // Values
        var values: [PieChartDataEntry] = []
        if segmentControl.selectedSegmentIndex == 2 {
            var kasperskyValues: [String : Int] = [:]
            kasperskyLogs.forEach {
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
            logsCountLabel.text = "Logs count: \(kasperskyLogs.count)"
        } else if segmentControl.selectedSegmentIndex == 1 {
            var tplinkValues: [String : Int] = [:]
            tplinkLogs.forEach {
                if $0.protocolNetwork != "" {
                    tplinkValues[$0.protocolNetwork] = (tplinkValues[$0.protocolNetwork] ?? 0) + 1
                }
            }
            let tplinkSortedValues = tplinkValues.sorted { $0.value > $1.value }
            
            let count = tplinkSortedValues.count > 15 ? 15 : tplinkSortedValues.count
            values = (0..<count).map { (i) -> PieChartDataEntry in
                return PieChartDataEntry(value: Double(tplinkSortedValues[i].value),
                                         label: tplinkSortedValues[i].key + " (\(tplinkSortedValues[i].value))")
            }
            logsCountLabel.text = "Logs count: \(tplinkLogs.count)"
        } else if segmentControl.selectedSegmentIndex == 0 {
            var dlinkValues: [String : Int] = [:]
            dlinkLogs.forEach {
                if $0.protocolNetwork != "" {
                    dlinkValues[$0.protocolNetwork] = (dlinkValues[$0.protocolNetwork] ?? 0) + 1
                }
            }
            let dlinkSortedValues = dlinkValues.sorted { $0.value > $1.value }
            
            let count = dlinkSortedValues.count > 15 ? 15 : dlinkSortedValues.count
            values = (0..<count).map { (i) -> PieChartDataEntry in
                return PieChartDataEntry(value: Double(dlinkSortedValues[i].value),
                                         label: dlinkSortedValues[i].key + " (\(dlinkSortedValues[i].value))")
            }
            logsCountLabel.text = "Logs count: \(dlinkLogs.count)"
        }
        
        let set = PieChartDataSet(entries: values, label: "")
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
        
        chartView.data = data
        chartView.highlightValues(nil)
        
    }
    
}

