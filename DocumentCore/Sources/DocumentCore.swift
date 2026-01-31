// DocumentCore - Shared SDK for Document Intelligence Platform
// This package provides shared functionality for DocuScan AI, PDFGenius, and InvoiceFlow AI

import Foundation

// Re-export all public modules
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL
@_exported import struct Foundation.Data

/// DocumentCore SDK Version
public enum DocumentCore {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}
