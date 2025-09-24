import SwiftUI
import VisionKit
import PDFKit

/// A view that scans documents.
public struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode)
    private var presentationMode

    public enum CompletionType {
        case images((Result<[UIImage], Error>) -> Void)
        case pdf((Result<PDFDocument, Error>) -> Void)
    }
    
    private var completion: CompletionType

    /// Creates a scanner that scans documents.
    /// - Parameter onCompletion: A callback that will be invoked when the scanning operation has succeeded or failed.
    public init(onCompletion: @escaping (Result<[UIImage], Error>) -> Void) {
        self.completion = .images(onCompletion)
    }

    /// Creates a scanner that scans documents.
    /// - Parameter onCompletion: A callback that will be invoked when the scanning operation has succeeded or failed.
    public init(onCompletion: @escaping (Result<PDFDocument, Error>) -> Void) {
        self.completion = .pdf(onCompletion)
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    /// A Boolean variable that indicates whether or not the current device supports document scanning.
    ///
    /// This class method returns `false` for unsupported hardware.
    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
}

extension DocumentScannerView {
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map(scan.imageOfPage(at:))
            switch parent.completion {
            case .images(let onCompletion):
                onCompletion(.success(images))
            case .pdf(let onCompletion):
                let pdfDocument = PDFDocument()
                for image in images {
                    guard let page = PDFPage(image: image) else { continue }
                    pdfDocument.insert(page, at: pdfDocument.pageCount)
                }
                onCompletion(.success(pdfDocument))
            }
            parent.dismiss()
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Error:", error)
            switch parent.completion {
            case .images(let onCompletion):
                onCompletion(.failure(error))
            case .pdf(let onCompletion):
                onCompletion(.failure(error))
            }
            parent.dismiss()
        }
    }
}
