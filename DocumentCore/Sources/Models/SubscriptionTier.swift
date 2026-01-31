import Foundation

/// Subscription tiers for the apps
public enum SubscriptionTier: String, Codable {
    case free = "free"
    case pro = "pro"

    /// Features available in each tier
    public var features: Set<Feature> {
        switch self {
        case .free:
            return [
                .scan,
                .basicFilters,
                .localStorage,
                .limitedExport,
                .viewPDF,
                .basicAnnotations,
                .createInvoice,
                .limitedInvoices
            ]
        case .pro:
            return Feature.allCases.reduce(into: Set<Feature>()) { $0.insert($1) }
        }
    }

    /// Check if a feature is available
    public func hasFeature(_ feature: Feature) -> Bool {
        features.contains(feature)
    }
}

/// All available features across the platform
public enum Feature: String, Codable, CaseIterable {
    // Scanner features
    case scan = "scan"
    case basicFilters = "basic_filters"
    case advancedFilters = "advanced_filters"
    case localStorage = "local_storage"
    case cloudSync = "cloud_sync"
    case limitedExport = "limited_export"
    case unlimitedExport = "unlimited_export"
    case ocr = "ocr"
    case aiSummary = "ai_summary"
    case autoTitle = "auto_title"
    case fieldExtraction = "field_extraction"
    case searchDocuments = "search_documents"
    case removeWatermark = "remove_watermark"

    // PDF Editor features
    case viewPDF = "view_pdf"
    case basicAnnotations = "basic_annotations"
    case advancedAnnotations = "advanced_annotations"
    case signature = "signature"
    case editText = "edit_text"
    case mergePDF = "merge_pdf"
    case splitPDF = "split_pdf"
    case passwordProtect = "password_protect"
    case smartFormFill = "smart_form_fill"
    case contractAnalysis = "contract_analysis"

    // Invoice features
    case createInvoice = "create_invoice"
    case limitedInvoices = "limited_invoices"
    case unlimitedInvoices = "unlimited_invoices"
    case clientDatabase = "client_database"
    case itemTemplates = "item_templates"
    case recurringInvoices = "recurring_invoices"
    case taxCalculation = "tax_calculation"
    case logoUpload = "logo_upload"
    case paymentTracking = "payment_tracking"
    case voiceToInvoice = "voice_to_invoice"
    case receiptScan = "receipt_scan"

    public var displayName: String {
        switch self {
        case .scan: return "Document Scanning"
        case .basicFilters: return "Basic Filters"
        case .advancedFilters: return "Advanced Filters"
        case .localStorage: return "Local Storage"
        case .cloudSync: return "Cloud Sync"
        case .limitedExport: return "Export (Watermarked)"
        case .unlimitedExport: return "Export (No Watermark)"
        case .ocr: return "Text Recognition (OCR)"
        case .aiSummary: return "AI Summaries"
        case .autoTitle: return "Auto-Title Documents"
        case .fieldExtraction: return "Extract Key Fields"
        case .searchDocuments: return "Search Documents"
        case .removeWatermark: return "Remove Watermark"
        case .viewPDF: return "View PDFs"
        case .basicAnnotations: return "Basic Annotations"
        case .advancedAnnotations: return "Advanced Annotations"
        case .signature: return "Add Signature"
        case .editText: return "Edit PDF Text"
        case .mergePDF: return "Merge PDFs"
        case .splitPDF: return "Split PDFs"
        case .passwordProtect: return "Password Protection"
        case .smartFormFill: return "Smart Form Fill"
        case .contractAnalysis: return "Contract Analysis"
        case .createInvoice: return "Create Invoices"
        case .limitedInvoices: return "3 Invoices/Month"
        case .unlimitedInvoices: return "Unlimited Invoices"
        case .clientDatabase: return "Client Database"
        case .itemTemplates: return "Item Templates"
        case .recurringInvoices: return "Recurring Invoices"
        case .taxCalculation: return "Tax Calculation"
        case .logoUpload: return "Logo Upload"
        case .paymentTracking: return "Payment Tracking"
        case .voiceToInvoice: return "Voice to Invoice"
        case .receiptScan: return "Receipt Scanning"
        }
    }

    public var isPro: Bool {
        !SubscriptionTier.free.features.contains(self)
    }
}
