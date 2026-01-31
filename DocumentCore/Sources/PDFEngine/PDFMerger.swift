import PDFKit

/// Handles merging and splitting PDF documents
public final class PDFMerger {

    public init() {}

    // MARK: - Merge Operations

    /// Merge multiple PDF documents into one
    public func merge(documents: [PDFDocument]) -> PDFDocument? {
        guard !documents.isEmpty else { return nil }

        let mergedDocument = PDFDocument()
        var pageIndex = 0

        for document in documents {
            for docPageIndex in 0..<document.pageCount {
                guard let page = document.page(at: docPageIndex) else { continue }
                mergedDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }

        return mergedDocument.pageCount > 0 ? mergedDocument : nil
    }

    /// Merge PDF data arrays into one
    public func merge(pdfDataArray: [Data]) -> Data? {
        let documents = pdfDataArray.compactMap { PDFDocument(data: $0) }
        return merge(documents: documents)?.dataRepresentation()
    }

    /// Insert pages from one document into another at a specific index
    public func insert(
        pages: PDFDocument,
        into targetDocument: PDFDocument,
        at index: Int
    ) -> PDFDocument {
        let resultDocument = PDFDocument()

        // Copy pages before insertion point
        for i in 0..<min(index, targetDocument.pageCount) {
            if let page = targetDocument.page(at: i) {
                resultDocument.insert(page, at: resultDocument.pageCount)
            }
        }

        // Insert new pages
        for i in 0..<pages.pageCount {
            if let page = pages.page(at: i) {
                resultDocument.insert(page, at: resultDocument.pageCount)
            }
        }

        // Copy remaining pages
        for i in index..<targetDocument.pageCount {
            if let page = targetDocument.page(at: i) {
                resultDocument.insert(page, at: resultDocument.pageCount)
            }
        }

        return resultDocument
    }

    // MARK: - Split Operations

    /// Split a PDF document at specified page indices
    public func split(document: PDFDocument, at indices: [Int]) -> [PDFDocument] {
        var result: [PDFDocument] = []
        var sortedIndices = indices.sorted()

        // Add 0 at the beginning if not present
        if sortedIndices.first != 0 {
            sortedIndices.insert(0, at: 0)
        }

        // Add document page count at the end
        sortedIndices.append(document.pageCount)

        for i in 0..<(sortedIndices.count - 1) {
            let startIndex = sortedIndices[i]
            let endIndex = sortedIndices[i + 1]

            let newDocument = PDFDocument()

            for pageIndex in startIndex..<endIndex {
                if let page = document.page(at: pageIndex) {
                    newDocument.insert(page, at: newDocument.pageCount)
                }
            }

            if newDocument.pageCount > 0 {
                result.append(newDocument)
            }
        }

        return result
    }

    /// Extract specific pages from a PDF document
    public func extractPages(from document: PDFDocument, pageIndices: [Int]) -> PDFDocument? {
        let newDocument = PDFDocument()

        for index in pageIndices.sorted() {
            guard index >= 0 && index < document.pageCount,
                  let page = document.page(at: index) else { continue }
            newDocument.insert(page, at: newDocument.pageCount)
        }

        return newDocument.pageCount > 0 ? newDocument : nil
    }

    /// Remove pages from a PDF document
    public func removePages(from document: PDFDocument, pageIndices: [Int]) -> PDFDocument {
        let newDocument = PDFDocument()
        let indicesToRemove = Set(pageIndices)

        for index in 0..<document.pageCount {
            if !indicesToRemove.contains(index),
               let page = document.page(at: index) {
                newDocument.insert(page, at: newDocument.pageCount)
            }
        }

        return newDocument
    }

    // MARK: - Page Operations

    /// Reorder pages in a document
    public func reorderPages(in document: PDFDocument, newOrder: [Int]) -> PDFDocument {
        let newDocument = PDFDocument()

        for index in newOrder {
            guard index >= 0 && index < document.pageCount,
                  let page = document.page(at: index) else { continue }
            newDocument.insert(page, at: newDocument.pageCount)
        }

        return newDocument
    }

    /// Rotate a page by specified degrees (90, 180, 270)
    public func rotatePage(in document: PDFDocument, pageIndex: Int, degrees: Int) {
        guard let page = document.page(at: pageIndex) else { return }
        let currentRotation = page.rotation
        let newRotation = (currentRotation + degrees) % 360
        page.rotation = newRotation
    }

    /// Duplicate a page
    public func duplicatePage(in document: PDFDocument, pageIndex: Int) {
        guard let page = document.page(at: pageIndex),
              let pageCopy = page.copy() as? PDFPage else { return }
        document.insert(pageCopy, at: pageIndex + 1)
    }
}
