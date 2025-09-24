//
//  ContentView.swift
//  DocScanner
//

import SwiftUI
import DocumentScannerView
import UIKit
import PDFKit

func gracefulExit() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
}

/// Converts an array of UIImage instances to a PDFDocument.
func convertImagesToPDF(images: [UIImage]) -> PDFDocument? {
    let pdfDocument = PDFDocument()
    
    for (index, image) in images.enumerated() {
        guard let pdfPage = PDFPage(image: image) else {
            return nil // Return nil if any image fails to convert to a PDFPage
        }
        pdfDocument.insert(pdfPage, at: index)
    }
    
    return pdfDocument
}

var filePath = ""

func saveTempPDF(pdf: PDFDocument) -> String? {
    // Get the temporary directory path
    let tempDirectory = FileManager.default.temporaryDirectory
    
    // Create a unique file name
    let fileName = "Scanned Document.pdf"
    
    // Combine the directory path with the file name
    let fileURL = tempDirectory.appendingPathComponent(fileName)
    
    // Save the PDF to the temporary directory
    if pdf.write(to: fileURL) {
        print("PDF saved to: \(fileURL.path)")
        filePath = fileURL.path
        return filePath
    } else {
        print("Failed to save PDF.")
        return nil
    }
}

func deleteTempPDF(backupPath: String?) {
    do {
        try FileManager.default.removeItem(at: (URL(string: filePath) ?? URL(string: backupPath!)!))
        print("PDF deleted.")
    } catch {
        print("Failed to delete PDF: \(error.localizedDescription)")
    }
}

extension PDFDocument: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pdf) { pdf in
            if let data = pdf.dataRepresentation() {
                return data
            } else {
                return Data()
            }
        } importing: { data in
            if let pdf = PDFDocument(data: data) {
                return pdf
            } else {
                return PDFDocument()
            }
        }
        .suggestedFileName("Scanned Document.pdf")
        DataRepresentation(exportedContentType: .pdf) { pdf in
            if let data = pdf.dataRepresentation() {
                return data
            } else {
                return Data()
            }
        }
        .suggestedFileName("Scanned Document.pdf")
    }
}

struct ContentView: View {
    @AppStorage("filePath") var pdfFilePath = ""
    
    @State private var content: [UIImage]? = nil
    @State private var showScanner = false
    @State private var showShareSheet = false
    @State private var doc: PDFDocument? = nil
    
    var body: some View {
        VStack {
            Spacer()
            if doc != nil {
                ShareLink(item: doc ?? PDFDocument(), preview: SharePreview("Scanned Document (PDF)"))
                    .scaleEffect(2.0)
                    .disabled(doc == nil)
            } else {
                Button(action: {
                    showScanner = true
                }, label: {
                    Label("Tap to Scan", systemImage: "viewfinder")
                        .font(.largeTitle)
                })
            }
            Spacer()
            Text("To retry, leave the app and open it again. To cancel, leave the app.")
                .multilineTextAlignment(.center)
                .opacity(0.75)
        }
        .onAppear {
            #if RELEASE
            self.showScanner = true
            #endif
        }
        .documentScanner(isPresented: $showScanner, onCompletion: {( result: Result<[UIImage], Error>) in
            switch result {
            case .success(let pages):
                self.content = pages
                if content != nil {
                    doc = convertImagesToPDF(images: pages)!
                    showShareSheet = true
                }
            case .failure(let error):
                print("error: \(error)")
            }
        })
        .padding()
        .onChange(of: showScanner) { newValue in
            if newValue == false && self.content == nil {
                gracefulExit()
            }
        }
    }
}

#Preview {
    ContentView()
}
