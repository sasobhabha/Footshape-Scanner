import StandardCyborgFusion
import StandardCyborgUI
import UIKit
import QuickLook

extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }
        
        return String(data: data as Data, encoding: String.Encoding.utf8)
    }
    
    func toBase64() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }

        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}

class ViewController: UIViewController, ScanningViewControllerDelegate, UIDocumentPickerDelegate {
    
    private var processingAlert: UIAlertController?
    
    // MARK: - IBOutlets and IBActions
    
    @IBOutlet private weak var showScanButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var scanButton: UIButton!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var yourScanLabel: UILabel!
    @IBOutlet private weak var horizontalLine: UIView!
    
    
    @IBAction private func startScanning(_ sender: UIButton) {
        #if targetEnvironment(simulator)
        let alert = UIAlertController(title: "Simulator Unsupported", message: "There is no depth camera available on the iOS Simulator. Please build and run on an iOS device with TrueDepth", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
        #else
        let scanningVC = ScanningViewController()
        scanningVC.delegate = self
        scanningVC.modalPresentationStyle = .fullScreen
        present(scanningVC, animated: true)
        #endif
    }
    
    @IBAction private func showScan(_ sender: UIButton) {
        guard let pointCloud = lastScanPointCloud else { return }
        
        pointCloudPreviewVC.pointCloud = pointCloud
        pointCloudPreviewVC.leftButton.setTitle("Delete", for: UIControl.State.normal)
        pointCloudPreviewVC.rightButton.setTitle("Dismiss", for: UIControl.State.normal)
        pointCloudPreviewVC.leftButton.backgroundColor = UIColor(named: "DestructiveAction")
        pointCloudPreviewVC.rightButton.backgroundColor = UIColor(named: "DefaultAction")
        pointCloudPreviewVC.modalPresentationStyle = .fullScreen
        
        present(pointCloudPreviewVC, animated: true)
    }
    
    // MARK: - UIViewController
    
    override func loadView() {
        super.loadView()
        
        showScanButton.imageView?.contentMode = .scaleAspectFill
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNewBranding()
        loadScan()
    }
    
    private func setupNewBranding() {
        // Deep Midnight Blue theme background
        view.backgroundColor = UIColor(red: 11/255, green: 15/255, blue: 25/255, alpha: 1.0)
        
        // Hide vendor logo to focus on our brand
        logoImageView.isHidden = true
        
        // Modern styled header for "Footshape Scanner"
        let attrString = NSMutableAttributedString(
            string: "Footshape\nScanner",
            attributes: [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 42, weight: .bold)
            ]
        )
        // Set "Scanner" to a vibrant electric/cyan color
        if let range = attrString.string.range(of: "Scanner") {
            let nsRange = NSRange(range, in: attrString.string)
            attrString.addAttributes([
                .foregroundColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0) // #06B6D4 Neon Cyan
            ], range: nsRange)
        }
        titleLabel.attributedText = attrString
        titleLabel.numberOfLines = 2
        
        // Thin glowing blue horizontal line
        horizontalLine.backgroundColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 0.6) // #3B82F6 Electric Blue
        
        // Your Scan label
        yourScanLabel.text = "Recent Scans"
        yourScanLabel.textColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0) // Slate-400
        
        // Style Recent Scan Card
        showScanButton.layer.cornerRadius = 16
        showScanButton.layer.borderWidth = 1.5
        showScanButton.layer.borderColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0).cgColor // Slate-700
        showScanButton.backgroundColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 0.8) // Slate-800
        showScanButton.setTitleColor(UIColor(red: 203/255, green: 213/255, blue: 225/255, alpha: 1.0), for: .normal) // Slate-300
        
        // Rebrand Bottom "Scan" Button
        scanButton.layer.cornerRadius = 28
        scanButton.layer.masksToBounds = true
        scanButton.setTitle("Start Scanning", for: .normal)
        scanButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.backgroundColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0) // #3B82F6 Electric Blue
        
        // Add subtle shadow to start button for premium feel
        scanButton.layer.shadowColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 0.4).cgColor
        scanButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        scanButton.layer.shadowRadius = 16
        scanButton.layer.shadowOpacity = 1.0
        scanButton.layer.masksToBounds = false
    }
    
    // MARK: - ScanningViewControllerDelegate
    
    func scanningViewControllerDidCancel(_ controller: ScanningViewController) {
        dismiss(animated: true)
    }
    
    func scanningViewController(_ controller: ScanningViewController, didScan pointCloud: SCPointCloud) {
        pointCloudPreviewVC.pointCloud = pointCloud
        pointCloudPreviewVC.leftButton.setTitle("Rescan", for: UIControl.State.normal)
        pointCloudPreviewVC.rightButton.setTitle("Save Scan", for: UIControl.State.normal)
        pointCloudPreviewVC.leftButton.backgroundColor = UIColor(named: "DestructiveAction")
        pointCloudPreviewVC.rightButton.backgroundColor = UIColor(named: "SaveAction")
        
        controller.present(pointCloudPreviewVC, animated: false)
    }
    
    @objc private func previewLeftButtonTapped(_ sender: UIButton) {
        let isExistingScan = pointCloudPreviewVC.pointCloud == lastScanPointCloud
        
        if isExistingScan {
            // Delete
            deleteScan()
            dismiss(animated: true)
        } else {
            // Retake
            dismiss(animated: false)
        }
    }
    
    @objc private func previewRightButtonTapped(_ sender: UIButton) {
        let isExistingScan = pointCloudPreviewVC.pointCloud == lastScanPointCloud
        
        if isExistingScan {
            // Dismiss
            dismiss(animated: true)
        } else {
            // Save
            saveScan(pointCloud: pointCloudPreviewVC.pointCloud!, thumbnail: pointCloudPreviewVC.renderedPointCloudImage)
            
        }
    }
    
    // MARK: - Private
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private lazy var pointCloudPreviewVC: PointCloudPreviewViewController = {
        let previewVC: PointCloudPreviewViewController = PointCloudPreviewViewController()
        previewVC.leftButton.addTarget(self, action: #selector(previewLeftButtonTapped(_:)), for: UIControl.Event.touchUpInside)
        previewVC.rightButton.addTarget(self, action: #selector(previewRightButtonTapped(_:)), for: UIControl.Event.touchUpInside)
        return previewVC
    }()
    
    private var lastScanPointCloud: SCPointCloud?
    private var lastScanDate: Date?
    private var lastScanThumbnail: UIImage?
    
    private lazy var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private lazy var scanPLYURL = documentsURL.appendingPathComponent("Scan.ply")
    private lazy var scanThumbnailURL = documentsURL.appendingPathComponent("Scan.jpeg")
    
    // MARK: -
    
    private func updateUI() {
        if lastScanThumbnail == nil {
            showScanButton.layer.borderWidth = 1.5
            showScanButton.layer.borderColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0).cgColor
            showScanButton.setTitle("No Scan Available", for: UIControl.State.normal)
        } else {
            showScanButton.layer.borderWidth = 1.5
            showScanButton.layer.borderColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 0.8).cgColor
            showScanButton.setTitle(nil, for: UIControl.State.normal)
        }
        
        showScanButton.setImage(lastScanThumbnail, for: UIControl.State.normal)
    }
    
    private func loadScan() {
        let scanPLYPath = scanPLYURL.path
        let scanThumbnailPath = scanThumbnailURL.path
        let fileManager = FileManager.default
        
        if
            fileManager.fileExists(atPath: scanPLYPath),
            let plyAttributes = try? fileManager.attributesOfItem(atPath: scanPLYPath),
            let dateCreated = plyAttributes[FileAttributeKey.creationDate] as? Date,
            let pointCloud = SCPointCloud(plyPath: scanPLYPath),
            pointCloud.pointCount > 0
        {
            lastScanPointCloud = pointCloud
            lastScanDate = dateCreated
            lastScanThumbnail = UIImage(contentsOfFile: scanThumbnailPath)
        }
        
        updateUI()
    }
    
    private func saveScan(pointCloud: SCPointCloud, thumbnail: UIImage?) {
        let progressAlert = UIAlertController(title: "Generating Model...", message: "Processing 3D point cloud locally", preferredStyle: .alert)
        self.presentOnTop(progressAlert, animated: true, completion: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let plyURL = self.documentsURL.appendingPathComponent("FootScan.ply")
            let objURL = self.documentsURL.appendingPathComponent("FootScan.obj")
            let usdzURL = self.documentsURL.appendingPathComponent("FootScan.usdz")
            
            // StandardCyborg local file writers (run on device GPU/CPU)
            let plySuccess = pointCloud.writeToPLY(atPath: plyURL.path)
            let objSuccess = pointCloud.writeToOBJ(atPath: objURL.path)
            let usdzSuccess = pointCloud.writeToUSDZ(atPath: usdzURL.path)
            
            if let thumbnail = thumbnail,
               let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: self.scanThumbnailURL)
            }
            
            DispatchQueue.main.async {
                progressAlert.dismiss(animated: true) {
                    if plySuccess && objSuccess && usdzSuccess {
                        self.lastScanPointCloud = pointCloud
                        self.lastScanThumbnail = thumbnail
                        self.lastScanDate = Date()
                        self.updateUI()
                        
                        self.presentLocalOptionsAlert(usdzURL: usdzURL, objURL: objURL)
                    } else {
                        self.showErrorAlert(message: "Failed to generate local 3D models.")
                    }
                }
            }
        }
    }

    private func presentLocalOptionsAlert(usdzURL: URL, objURL: URL) {
        let alert = UIAlertController(title: "Scan Processed",
                                      message: "Your local 3D Footshape model has been successfully generated.",
                                      preferredStyle: .actionSheet)
        
        let previewAction = UIAlertAction(title: "Preview in AR", style: .default) { [weak self] _ in
            self?.previewLocalModel(usdzURL: usdzURL)
        }
        
        let saveUSDZAction = UIAlertAction(title: "Save USDZ Model", style: .default) { [weak self] _ in
            self?.exportLocalFile(url: usdzURL)
        }
        
        let saveOBJAction = UIAlertAction(title: "Save OBJ Model", style: .default) { [weak self] _ in
            self?.exportLocalFile(url: objURL)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(previewAction)
        alert.addAction(saveUSDZAction)
        alert.addAction(saveOBJAction)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.presentOnTop(alert, animated: true, completion: nil)
    }
    
    private func previewLocalModel(usdzURL: URL) {
        let previewVC = ARViewController(fileURL: usdzURL)
        self.presentOnTop(previewVC, animated: true, completion: nil)
    }
    
    private func exportLocalFile(url: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        documentPicker.delegate = self
        self.presentOnTop(documentPicker, animated: true, completion: nil)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.presentOnTop(alert, animated: true, completion: nil)
    }
    
    private func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    private func presentOnTop(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        topMostController().present(viewController, animated: animated, completion: completion)
    }
    
    
    private func deleteScan() {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: scanPLYURL.path) {
            try? fileManager.removeItem(at: scanPLYURL)
        }
        
        if fileManager.fileExists(atPath: scanThumbnailURL.path) {
            try? fileManager.removeItem(at: scanThumbnailURL)
        }
        
        lastScanPointCloud = nil
        lastScanThumbnail = nil
        lastScanDate = nil
        
        updateUI()
    }
    
}

