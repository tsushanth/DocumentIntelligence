import PDFKit

/// Merge and split PDF documents
public final class PDFMerger {
    
    public init() {}
    
    /// Merge multiple PDFs into one
    public func merge(documents: [PDFDocument]) -> PDFDocument {
        let merged = PDFDocument()
        var pageIndex = 0
        
        for document in documents {
            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }
                merged.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        return merged
    }
    
    /// Split PDF into separate single-page documents
    public func split(document: PDFDocument) -> [PDFDocument] {
        var pages: [PDFDocument] = []
        
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let singlePage = PDFDocument()
            singlePage.insert(page, at: 0)
            pages.append(singlePage)
        }
        
        return pages
    }
    
    /// Extract specific pages from PDF
    public func extractPages(from document: PDFDocument, pageIndices: [Int]) -> PDFDocument {
        let extracted = PDFDocument()
        var insertIndex = 0
        
        for pageIndex in pageIndices {
            guard pageIndex < document.pageCount,
                  let page = document.page(at: pageIndex) else { continue }
            extracted.insert(page, at: insertIndex)
            insertIndex += 1
        }
        
        return extracted
    }
    
    /// Remove pages from PDF
    public func removePages(from document: PDFDocument, pageIndices: Set<Int>) -> PDFDocument {
        let result = PDFDocument()
        var insertIndex = 0
        
        for i in 0..<document.pageCount {
            if !pageIndices.contains(i), let page = document.page(at: i) {
                result.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }
        
        return result
    }
    
    /// Reorder pages in PDF
    public func reorderPages(in document: PDFDocument, newOrder: [Int]) -> PDFDocument {
        let reordered = PDFDocument()
        
        for (newIndex, oldIndex) in newOrder.enumerated() {
            guard oldIndex < document.pageCount,
                  let page = document.page(at: oldIndex) else { continue }
            reordered.insert(page, at: newIndex)
        }
        
        return reordered
    }
    
    /// Insert pages from one PDF into another
    public func insertPages(from source: PDFDocument, into destination: PDFDocument, at index: Int) -> PDFDocument {
        let result = PDFDocument()
        var insertIndex = 0
        
        // Add pages before insertion point
        for i in 0..<min(index, destination.pageCount) {
            if let page = destination.page(at: i) {
                result.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }
        
        // Add source pages
        for i in 0..<source.pageCount {
            if let page = source.page(at: i) {
                result.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }
        
        // Add remaining destination pages
        for i in index..<destination.pageCount {
            if let page = destination.page(at: i) {
                result.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }
        
        return result
    }
}
