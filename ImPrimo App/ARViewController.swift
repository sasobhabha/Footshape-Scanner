//
//  ARViewController.swift
//  StandardCyborgTest
//
//  Created by Ridvan Song on 2020-03-29.
//  Copyright © 2020 Ridvan Song. All rights reserved.
//

//
//  ARTestViewController.swift
//  Print.ology
//
//  Created by Trav Haran on 2020-01-26.
//  Copyright © 2020 Dollar  Luo. All rights reserved.
//

import UIKit
import ARKit
import QuickLook

class ARViewController: QLPreviewController, QLPreviewControllerDataSource{
    
    let testView = UIView()
    private var fileURL: URL!
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        setupView()
    }
    
    private func setupView() {
        
        self.view.addSubview(testView)
        testView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            testView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            testView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            testView.heightAnchor.constraint(equalToConstant: 100)
        ])

        let view = UIButton()
        testView.addSubview(view)
        view.frame = CGRect(x: 0, y: 0, width: 327, height: 53)

        view.backgroundColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0)
        view.setTitle("Export Model", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.titleLabel?.font = UIFont(name:"Avenir", size: 18)
        view.layer.cornerRadius = 25
        view.centerXAnchor.constraint(equalTo: testView.centerXAnchor).isActive = true

        

        view.translatesAutoresizingMaskIntoConstraints = false

        view.widthAnchor.constraint(equalToConstant: 327).isActive = true

        view.heightAnchor.constraint(equalToConstant: 53).isActive = true
        view.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc func buttonTapped(){
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func buttonDone(){
        
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) ->
    QLPreviewItem {
        return fileURL as QLPreviewItem
    }
    
}
