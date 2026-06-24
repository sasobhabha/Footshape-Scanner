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
            let stlURL = self.documentsURL.appendingPathComponent("FootScan.stl")
            let meshedPLYURL = self.documentsURL.appendingPathComponent("FootScan_meshed.ply")
            
            // StandardCyborg local file writers (run on device GPU/CPU)
            let plySuccess = pointCloud.writeToPLY(atPath: plyURL.path)
            let objSuccess = pointCloud.writeToOBJ(atPath: objURL.path)
            let usdzSuccess = pointCloud.writeToUSDZ(atPath: usdzURL.path)
            
            // Perform PrimoEngine Solid/Meshing process natively on device
            let meshingOperation = SCMeshingOperation(inputPLYPath: plyURL.path, outputPLYPath: meshedPLYURL.path)
            meshingOperation.parameters.closed = true
            meshingOperation.parameters.resolution = 5 // solidResolution
            meshingOperation.parameters.smoothness = 2
            meshingOperation.start()
            
            var stlSuccess = false
            if meshingOperation.error == nil {
                let mesh = SCMesh(plyPath: meshedPLYURL.path, jpegPath: "")
                stlSuccess = self.writeSTL(from: mesh, to: stlURL)
            }
            
            if let thumbnail = thumbnail,
               let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: self.scanThumbnailURL)
            }
            
            DispatchQueue.main.async {
                progressAlert.dismiss(animated: true) {
                    if plySuccess && objSuccess && usdzSuccess && stlSuccess {
                        self.lastScanPointCloud = pointCloud
                        self.lastScanThumbnail = thumbnail
                        self.lastScanDate = Date()
                        self.updateUI()
                        
                        self.presentLocalOptionsAlert(usdzURL: usdzURL, objURL: objURL, stlURL: stlURL)
                    } else {
                        self.showErrorAlert(message: "Failed to generate local 3D models (including STL).")
                    }
                }
            }
        }
    }

    private func presentLocalOptionsAlert(usdzURL: URL, objURL: URL, stlURL: URL) {
        let alert = UIAlertController(title: "Scan Processed",
                                      message: "Your local 3D Footshape model has been successfully generated.",
                                      preferredStyle: .actionSheet)
        
        let previewAction = UIAlertAction(title: "Preview in AR", style: .default) { [weak self] _ in
            self?.previewLocalModel(usdzURL: usdzURL)
        }
        
        let saveSTLAction = UIAlertAction(title: "Save STL Model (3D Print)", style: .default) { [weak self] _ in
            self?.exportLocalFile(url: stlURL)
        }
        
        let saveUSDZAction = UIAlertAction(title: "Save USDZ Model", style: .default) { [weak self] _ in
            self?.exportLocalFile(url: usdzURL)
        }
        
        let saveOBJAction = UIAlertAction(title: "Save OBJ Model", style: .default) { [weak self] _ in
            self?.exportLocalFile(url: objURL)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(previewAction)
        alert.addAction(saveSTLAction)
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
    
    private func writeSTL(from mesh: SCMesh, to url: URL) -> Bool {
        let faceCount = mesh.faceCount
        let vertexCount = mesh.vertexCount
        guard faceCount > 0 else { return false }
        
        guard let positions = mesh.positionData else { return false }
        guard let normals = mesh.normalData else { return false }
        guard let faces = mesh.facesData else { return false }
        
        guard positions.count >= vertexCount * MemoryLayout<simd_float3>.size else { return false }
        guard faces.count >= faceCount * 3 * MemoryLayout<Int32>.size else { return false }
        
        var data = Data()
        var header = [UInt8](repeating: 0, count: 80)
        let headerText = "Created by Footshape Scanner"
        let headerBytes = Array(headerText.utf8)
        for i in 0..<min(headerBytes.count, 80) {
            header[i] = headerBytes[i]
        }
        data.append(contentsOf: header)
        
        var numFacets = UInt32(faceCount)
        withUnsafeBytes(of: &numFacets) { data.append(contentsOf: $0) }
        
        positions.withUnsafeBytes { (positionsPointer: UnsafeRawBufferPointer) in
            faces.withUnsafeBytes { (facesPointer: UnsafeRawBufferPointer) in
                let posPtr = positionsPointer.bindMemory(to: simd_float3.self)
                let facesPtr = facesPointer.bindMemory(to: Int32.self)
                
                let hasNormals = normals.count >= vertexCount * MemoryLayout<simd_float3>.size
                normals.withUnsafeBytes { (normalsPointer: UnsafeRawBufferPointer) in
                    let normPtr = normalsPointer.bindMemory(to: simd_float3.self)
                    
                    for f in 0..<faceCount {
                        let idx0 = Int(facesPtr[f * 3 + 0])
                        let idx1 = Int(facesPtr[f * 3 + 1])
                        let idx2 = Int(facesPtr[f * 3 + 2])
                        
                        guard idx0 < vertexCount && idx1 < vertexCount && idx2 < vertexCount else { continue }
                        
                        let v0 = posPtr[idx0]
                        let v1 = posPtr[idx1]
                        let v2 = posPtr[idx2]
                        
                        var normal = simd_float3(0, 0, 0)
                        if hasNormals {
                            let n0 = normPtr[idx0]
                            let n1 = normPtr[idx1]
                            let n2 = normPtr[idx2]
                            normal = simd_normalize(n0 + n1 + n2)
                        } else {
                            let edge1 = v1 - v0
                            let edge2 = v2 - v0
                            normal = simd_normalize(simd_cross(edge1, edge2))
                        }
                        
                        var nx = normal.x; var ny = normal.y; var nz = normal.z
                        withUnsafeBytes(of: &nx) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &ny) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &nz) { data.append(contentsOf: $0) }
                        
                        var v0x = v0.x; var v0y = v0.y; var v0z = v0.z
                        withUnsafeBytes(of: &v0x) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v0y) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v0z) { data.append(contentsOf: $0) }
                        
                        var v1x = v1.x; var v1y = v1.y; var v1z = v1.z
                        withUnsafeBytes(of: &v1x) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v1y) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v1z) { data.append(contentsOf: $0) }
                        
                        var v2x = v2.x; var v2y = v2.y; var v2z = v2.z
                        withUnsafeBytes(of: &v2x) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v2y) { data.append(contentsOf: $0) }
                        withUnsafeBytes(of: &v2z) { data.append(contentsOf: $0) }
                        
                        var attr: UInt16 = 0
                        withUnsafeBytes(of: &attr) { data.append(contentsOf: $0) }
                    }
                }
            }
        }
        
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error writing STL data: \(error)")
            return false
        }
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

