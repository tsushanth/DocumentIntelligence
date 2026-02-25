# DocuScanAI Consolidation -- Claude Worker Handoff Document

> **Purpose:** This document gives a future Claude worker everything needed to merge three published iOS apps into one unified DocuScanAI app. Read this instead of exploring the codebase from scratch.
>
> **Date generated:** 2026-02-24
>
> **Monorepo root:** `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/`

---

## Table of Contents

1. [Project Context](#1-project-context)
2. [Repository Structure and Complete File Inventory](#2-repository-structure-and-complete-file-inventory)
3. [Shared SDK: DocumentCore](#3-shared-sdk-documentcore)
4. [App 1: DocuScanAI (Base App -- KEEP)](#4-app-1-docuscanai-base-app----keep)
5. [App 2: PDFGenius / All-in-One PDF (ABSORB)](#5-app-2-pdfgenius--all-in-one-pdf-absorb)
6. [App 3: InvoiceFlowAI / InvoiceFlow Pro (ABSORB)](#6-app-3-invoiceflowai--invoiceflow-pro-absorb)
7. [Target Tab Structure](#7-target-tab-structure)
8. [Phase 1: Merge PDF Features into DocuScanAI](#8-phase-1-merge-pdf-features-into-docuscanai)
9. [Phase 2: Merge Invoice Features into DocuScanAI](#9-phase-2-merge-invoice-features-into-docuscanai)
10. [Phase 3: Sunset Old Apps](#10-phase-3-sunset-old-apps)
11. [Paywall / Subscription Integration](#11-paywall--subscription-integration)
12. [Info.plist Permissions -- Merged App](#12-infoplist-permissions----merged-app)
13. [Data Model and Storage](#13-data-model-and-storage)
14. [AI Service and API Key Concerns](#14-ai-service-and-api-key-concerns)
15. [Naming Conflicts and Resolution Strategy](#15-naming-conflicts-and-resolution-strategy)
16. [Third-Party Dependencies](#16-third-party-dependencies)
17. [Testing Checklist](#17-testing-checklist)
18. [Risk Assessment](#18-risk-assessment)
19. [Quick Reference: Key File Paths](#19-quick-reference-key-file-paths)

---

## 1. Project Context

### What exists today

Three published iOS apps share a monorepo (`InvoiceFlow/`) and a common Swift Package (`DocumentCore`):

| App (Store name) | Bundle ID | Code dir | Version | Downloads |
|---|---|---|---|---|
| **DocuScan AI** | `com.documentintelligence.docuscan` | `Apps/DocuScanAI/` | 1.0.0 build 3 | ~10 |
| **All-in-One PDF** | `com.documentintelligence.pdfgenius` | `Apps/PDFGenius/` | 1.0.0 build 1 | ~50 |
| **InvoiceFlow Pro** | `com.documentintelligence.invoiceflow` | `Apps/InvoiceFlowAI/` | 1.0.0 build 2 | ~10 |

### What we want

Merge all three into the **DocuScanAI** app target (`com.documentintelligence.docuscan`). This keeps the existing App Store listing and bundle ID. The other two apps will eventually be sunset.

### Why this is feasible

All three apps already depend on the same `DocumentCore` Swift Package for scanning, OCR, PDF engine, AI, paywall, and storage. The merge is primarily a **UI-level integration** -- copying Views and ViewModels from the other two apps into DocuScanAI and wiring them into a unified tab bar.

---

## 2. Repository Structure and Complete File Inventory

```
InvoiceFlow/                          # Monorepo root
├── CONSOLIDATION_PLAN.md             # Original high-level plan
├── CLAUDE_HANDOFF.md                 # THIS FILE
│
├── DocumentCore/                     # Shared Swift Package (SPM)
│   ├── Package.swift                 # swift-tools-version: 5.9, iOS 16+
│   └── Sources/
│       ├── DocumentCore.swift        # Version 1.0.0, re-exports Foundation
│       ├── Models/
│       │   ├── Document.swift        # Document, DocumentPage, ImageFilter, ExtractedField, FieldType, DocumentCategory
│       │   ├── Folder.swift          # Folder, FolderColor
│       │   └── SubscriptionTier.swift # SubscriptionTier (.free/.pro), Feature enum (ALL features across all 3 apps)
│       ├── AI/
│       │   ├── AIService.swift       # Singleton, GCP Cloud Run proxy, chatCompletion, analyzeDocument, askQuestion
│       │   ├── FieldExtractor.swift  # extractFields, extractInvoiceFields, extractReceiptFields
│       │   ├── Prompts.swift         # All AI prompt templates (summarize, categorize, auto-title, etc.)
│       │   ├── AutoTitler.swift      # generateTitle from text or category+fields
│       │   └── DocumentAnalyzer.swift # summarize, categorize, answerQuestion, extractKeyPoints, analyzeContract
│       ├── Camera/
│       │   ├── DocumentScanner.swift # UIViewControllerRepresentable for VNDocumentCameraViewController
│       │   ├── EdgeDetector.swift    # Vision VNDetectRectanglesRequest, perspective correction
│       │   └── ImageProcessor.swift  # Filters (B&W, color, grayscale, contrast, sharpen), crop, resize, compress
│       ├── OCR/
│       │   ├── TextRecognizer.swift  # recognizeText from UIImage or CGPDFPage (VNRecognizeTextRequest)
│       │   └── TextBlock.swift       # TextBlock with confidence, bounding box, pattern extraction helpers
│       ├── PDFEngine/
│       │   ├── PDFGenerator.swift    # Create PDFs from images
│       │   ├── PDFViewer.swift       # PDFViewer (read-only) and EditablePDFView (writable, page change notification)
│       │   ├── PDFEditor.swift       # Annotations: highlight, underline, text, ImageAnnotation (signatures), ink/drawing
│       │   ├── PDFMerger.swift       # merge, split, extractPages, removePages, reorderPages, insertPages
│       │   └── WatermarkService.swift # Text, image, diagonal watermarks with position options
│       ├── Paywall/
│       │   ├── StoreKitManager.swift # StoreKit 2 singleton, product IDs for all 3 apps, purchase/restore
│       │   ├── PaywallView.swift     # Generic paywall accepting appName, features list, productID
│       │   └── FeatureGate.swift     # FeatureGate<Content> view, FeatureLock modifier, .featureLocked() extension
│       └── Storage/
│           ├── DocumentStore.swift   # Core Data persistent container "DocumentCore", CRUD, search
│           ├── DocumentEntity.swift  # Core Data entity (programmatic): id, title, type, fileURL, ocrText, aiSummary, etc.
│           └── FolderEntity.swift    # Core Data entity (programmatic): id, name, color, documents (to-many cascade)
│
├── Apps/
│   ├── DocuScanAI/                   # *** BASE APP (KEEP) ***
│   │   ├── DocuScanAI.xcodeproj/
│   │   └── DocuScanAI/
│   │       ├── App/
│   │       │   ├── DocuScanAIApp.swift      # @main, AppState (isProUser, showPaywall)
│   │       │   ├── ContentView.swift        # TabView: Documents(0), Scan(1), Settings(2) -- tint .blue
│   │       │   └── Models.swift             # ScannedDocument, DocumentFolder (local structs, NOT Core Data)
│   │       ├── Views/
│   │       │   ├── HomeView.swift           # Document list with folders, search, sort options
│   │       │   ├── ScannerView.swift        # Camera scanning with VisionKit, filter selector, save PDF
│   │       │   ├── DocumentDetailView.swift # PDF viewer with AI insights button
│   │       │   ├── AIInsightsView.swift     # Smart title, summary, field extraction, OCR, Ask AI
│   │       │   ├── FolderDetailView.swift   # Folder contents view
│   │       │   └── SettingsView.swift       # Subscription, general, AI, about. Contains DocuScanPaywallView
│   │       ├── ViewModels/
│   │       │   ├── HomeViewModel.swift            # Document/folder management
│   │       │   ├── ScannerViewModel.swift         # Scanning, filtering, PDF generation
│   │       │   ├── DocumentDetailViewModel.swift  # PDF loading, OCR, AI summary
│   │       │   └── AIInsightsViewModel.swift      # AI insight operations, ExtractedDocumentFields
│   │       ├── Subscription/
│   │       │   ├── SubscriptionManager.swift # *** RevenueCat *** API key: appl_GLZeYTvGYnnLQktoQgmqDInOsNW
│   │       │   │                             # Products: docuscan_pro_monthly, docuscan_pro_annual, docuscan_pro_lifetime
│   │       │   ├── PaywallView.swift         # Full paywall with RevenueCat packages + mock pricing fallback
│   │       │   └── ProFeature.swift          # ProFeature enum (8 cases), FeatureGate, FeatureGatedModifier, ProBadgeOverlay
│   │       ├── Services/
│   │       │   └── WatermarkService.swift    # Diagonal + footer watermarks for free tier
│   │       └── Resources/
│   │           └── Info.plist               # Camera, Photo Library, User Tracking permissions
│   │
│   ├── PDFGenius/                    # *** TO BE ABSORBED (Phase 1) ***
│   │   ├── PDFGenius.xcodeproj/
│   │   └── PDFGenius/
│   │       ├── App/
│   │       │   ├── PDFGeniusApp.swift        # @main, PDFAppState (isProUser, showPaywall)
│   │       │   ├── PDFContentView.swift      # TabView: Documents(0), Tools(1), Settings(2) -- tint .purple
│   │       │   └── Models.swift              # PDFDocumentItem struct
│   │       ├── Views/
│   │       │   ├── DocumentListView.swift    # PDF list with file importer (.pdf), search
│   │       │   ├── PDFEditorView.swift       # *** KEY *** PDF editing with floating toolbar, annotations, signature/AI sheets
│   │       │   ├── PDFToolsView.swift        # *** KEY *** Grid: Merge, Split, Compress, Convert, Password(Pro), OCR(Pro)
│   │       │   ├── PDFAIAssistantView.swift  # *** KEY *** Segmented: Summary, Contract Analysis, Ask AI
│   │       │   ├── SignatureView.swift        # *** KEY *** Canvas-based signature drawing
│   │       │   └── PDFSettingsView.swift     # Settings with PDFGeniusPaywallView ($5.99/month)
│   │       ├── ViewModels/
│   │       │   ├── PDFDocumentListViewModel.swift # PDF import, file management
│   │       │   └── PDFEditorViewModel.swift       # *** KEY *** PDF editing, annotations, undo/redo, AI, merge/split
│   │       ├── Subscription/
│   │       │   ├── SubscriptionManager.swift # *** RevenueCat *** API key: appl_GtPahdnIplNbumCJhqbsscYRlpj
│   │       │   │                             # Products: pdfgenius_pro_monthly, pdfgenius_pro_annual, pdfgenius_pro_lifetime
│   │       │   ├── PaywallView.swift         # Purple/pink themed paywall
│   │       │   └── ProFeature.swift          # ProFeature enum (10 cases), own FeatureGate, ProBadgeOverlay
│   │       └── Resources/
│   │           └── Info.plist               # PDF document type handler, Photo Library Add, File Sharing
│   │
│   └── InvoiceFlowAI/               # *** TO BE ABSORBED (Phase 2) ***
│       ├── InvoiceFlowAI.xcodeproj/
│       └── InvoiceFlowAI/
│           ├── App/
│           │   ├── InvoiceFlowAIApp.swift     # @main, Facebook SDK init, Search Ads Attribution, InvoiceAppState
│           │   ├── InvoiceContentView.swift   # TabView: Invoices(0), Clients(1), Items(2), Settings(3) -- tint .green
│           │   └── Models.swift               # *** LARGE *** Invoice, Payment, LineItem, Client, ItemTemplate,
│           │                                  #   Estimate, BusinessInfo, PaymentDetails, InvoiceNumberSettings,
│           │                                  #   RecurringInvoice, LateFeeSettings, InvoiceStorage, NotificationManager, Currency
│           ├── Views/
│           │   ├── InvoiceListView.swift       # *** KEY *** Invoice list with create options (manual, voice, receipt scan)
│           │   ├── CreateInvoiceView.swift     # *** KEY *** Form: client, invoice details, line items, summary, notes
│           │   ├── InvoiceDetailView.swift     # *** KEY *** Header, client card, line items, totals, actions (send, download)
│           │   ├── ClientsView.swift           # *** KEY *** Client list, add client, client detail
│           │   ├── ItemsView.swift             # *** KEY *** Item templates list, add item
│           │   ├── VoiceToInvoiceView.swift    # *** KEY (Pro) *** Voice recording UI, transcript, extracted invoice data
│           │   ├── ScanReceiptView.swift       # *** KEY (Pro) *** Receipt scanning with VisionKit, extracted expense display
│           │   ├── InvoiceSettingsView.swift   # *** LARGE ~1600 lines *** Business info, logo, currency, tax, payment details,
│           │   │                               #   recurring invoices, late fees, notifications, export/backup
│           │   │                               #   Contains InvoiceFlowPaywallView (uses StoreKitManager directly)
│           │   ├── DashboardView.swift         # Dashboard with Charts framework: revenue charts, status breakdown, top clients
│           │   ├── EstimateListView.swift      # Estimate management
│           │   ├── CreateEstimateView.swift    # Estimate creation
│           │   ├── EstimateDetailView.swift    # Estimate detail
│           │   ├── ExportDataView.swift        # CSV/PDF data export
│           │   ├── LateFeeSettingsView.swift   # Late fee configuration
│           │   ├── SignatureView.swift          # Signature for invoices (separate from PDFGenius signature)
│           │   └── CloudSyncSettingsView.swift # iCloud sync settings
│           ├── ViewModels/
│           │   ├── InvoiceListViewModel.swift         # Invoice list management
│           │   ├── CreateInvoiceViewModel.swift       # Invoice creation with line items, tax, totals
│           │   ├── ClientsViewModel.swift             # Client CRUD
│           │   ├── ScanReceiptViewModel.swift         # Receipt scanning and AI extraction
│           │   ├── VoiceToInvoiceViewModel.swift      # SFSpeechRecognizer, AVAudioEngine integration
│           │   ├── EstimateListViewModel.swift        # Estimate management
│           │   └── CreateEstimateViewModel.swift      # Estimate creation
│           ├── Services/
│           │   ├── CSVExporter.swift           # CSV export utility
│           │   ├── ClientPortalGenerator.swift # Client portal generation
│           │   ├── CloudSyncManager.swift      # iCloud sync manager
│           │   ├── NetworkMonitor.swift        # Network reachability
│           │   ├── PDFTemplateGenerator.swift  # PDF invoice template rendering
│           │   ├── SearchAdsAttribution.swift  # Apple Search Ads attribution fetching
│           │   └── FacebookSDKManager.swift    # Facebook/Meta Ads SDK wrapper
│           └── Resources/
│               ├── Info.plist                 # Camera, Microphone, Speech Recognition, Photo Library, Facebook SDK, User Tracking
│               └── InvoiceFlowAI.entitlements # iCloud: CloudDocuments for iCloud.com.documentintelligence.invoiceflow
```

---

## 3. Shared SDK: DocumentCore

**Path:** `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/DocumentCore/`

### Package.swift

```swift
// swift-tools-version: 5.9
// Platforms: iOS 16+
// Single target: "DocumentCore"
// Dependencies: None (all Apple frameworks)
```

### Key Design Decisions

1. **Single target** -- everything compiles into one module `import DocumentCore`. No sub-targets for Camera, PDFEngine, etc.
2. **All entities use programmatic Core Data descriptions** -- no `.xcdatamodeld` file. The `DocumentStore` builds the managed object model in code.
3. **AI goes through a GCP Cloud Run proxy** -- the OpenAI API key is NOT in client code. The app authenticates with its own API key to the proxy.
4. **The `Feature` enum in `SubscriptionTier.swift` already defines ALL features across all three apps** -- scanner features, PDF editor features, and invoice features. The free tier grants: `scan`, `basicFilters`, `localStorage`, `limitedExport`, `viewPDF`, `basicAnnotations`, `createInvoice`, `limitedInvoices`. Everything else is Pro.
5. **The `StoreKitManager` in DocumentCore has product IDs for all three apps** but is NOT the primary subscription manager used by DocuScanAI or PDFGenius (they use RevenueCat instead). InvoiceFlowAI's paywall does reference `StoreKitManager` from DocumentCore.

### Important Types to Know

| File | Key Types | Notes |
|---|---|---|
| `Models/Document.swift` | `Document`, `DocumentPage`, `ImageFilter`, `ExtractedField`, `FieldType`, `DocumentCategory` | Core domain model for scanned docs |
| `Models/Folder.swift` | `Folder`, `FolderColor` | Folder organization |
| `Models/SubscriptionTier.swift` | `SubscriptionTier`, `Feature` | **Critical**: defines free/pro feature gates for ALL apps |
| `AI/AIService.swift` | `AIService`, `ChatMessage`, `AIServiceError` | Singleton, all AI requests go through this |
| `Camera/DocumentScanner.swift` | `DocumentScanner`, `DocumentScannerViewModel` | VNDocumentCameraViewController wrapper |
| `Camera/EdgeDetector.swift` | `EdgeDetector`, `DocumentCorners` | Vision rectangle detection |
| `Camera/ImageProcessor.swift` | `ImageProcessor` | Filters, crop, resize, compress |
| `OCR/TextRecognizer.swift` | `TextRecognizer`, `RecognizedText` | VNRecognizeTextRequest wrapper |
| `PDFEngine/PDFEditor.swift` | `PDFEditor`, `ImageAnnotation` | Annotations including signature images |
| `PDFEngine/PDFMerger.swift` | `PDFMerger` | Merge, split, extract, remove, reorder pages |
| `Paywall/StoreKitManager.swift` | `StoreKitManager`, `StoreKitError` | StoreKit 2 (used by InvoiceFlowAI only) |
| `Paywall/FeatureGate.swift` | `FeatureGate<Content>` | Generic view-level feature gating |
| `Storage/DocumentStore.swift` | `DocumentStore`, `DocumentType` | Core Data CRUD, search |
| `Storage/DocumentEntity.swift` | `DocumentEntity` | Programmatic NSManagedObject |
| `Storage/FolderEntity.swift` | `FolderEntity` | Programmatic NSManagedObject |

---

## 4. App 1: DocuScanAI (Base App -- KEEP)

**Path:** `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/DocuScanAI/`
**Bundle ID:** `com.documentintelligence.docuscan`
**Store name:** "DocuScan AI"
**Version:** 1.0.0 build 3
**Tint color:** `.blue`

### Current Tab Structure

```
Tab 0: "Documents" (doc.fill)       -> HomeView
Tab 1: "Scan" (camera.fill)         -> ScannerView
Tab 2: "Settings" (gear)            -> SettingsView
```

### Entry Point

```swift
// DocuScanAIApp.swift
@main
struct DocuScanAIApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
```

`AppState` has `isProUser: Bool` and `showPaywall: Bool`. The `checkSubscription()` method currently has a placeholder comment "Will integrate with StoreKitManager" -- it delegates to `SubscriptionManager.shared` (RevenueCat) in practice.

### Subscription System

**Uses RevenueCat (NOT StoreKit 2 from DocumentCore).**

- **API Key:** `appl_GLZeYTvGYnnLQktoQgmqDInOsNW`
- **Entitlement ID:** `"pro"`
- **Product IDs:**
  - `docuscan_pro_monthly`
  - `docuscan_pro_annual`
  - `docuscan_pro_lifetime`
- **RevenueCat Package Identifiers:** `$rc_monthly`, `$rc_annual`, `$rc_lifetime`

The `SubscriptionManager` is in `Subscription/SubscriptionManager.swift`. It configures RevenueCat, handles purchases, restores, and determines tier based on the `"pro"` entitlement.

### Feature Gating

`ProFeature.swift` defines 8 pro features for DocuScanAI:
- `ocrExtraction`, `aiSummary`, `autoTitle`, `fieldExtraction`, `askAI`, `searchInDocuments`, `noWatermark`, `cloudSync`

Each has `displayName`, `description`, `icon`, and `color`. There is a local `FeatureGate` singleton, `FeatureGatedModifier`, `ProBadgeOverlay`, and `ProFeatureButton` -- all wired to `SubscriptionManager.shared.isPro`.

### Local Models (NOT Core Data)

`Models.swift` defines `ScannedDocument` and `DocumentFolder` as plain Swift structs with `Codable` conformance. These are **independent** from the Core Data `DocumentEntity`/`FolderEntity` in DocumentCore.

### Watermark

`Services/WatermarkService.swift` adds diagonal "DocuScan AI" + footer "Created with DocuScan AI - Upgrade to Pro to remove" watermarks on free-tier exports.

### Info.plist Permissions

| Key | Value |
|---|---|
| `NSCameraUsageDescription` | "DocuScan AI needs camera access to scan documents" |
| `NSPhotoLibraryUsageDescription` | "DocuScan AI needs photo library access to import documents" |
| `NSUserTrackingUsageDescription` | "This allows us to provide you with a better, personalized experience..." |
| `ITSAppUsesNonExemptEncryption` | `false` |

### What stays as-is

- The @main entry point
- The bundle ID
- The RevenueCat subscription system
- The existing Documents tab (HomeView) and Scan tab (ScannerView)
- The Settings tab (will be expanded)

---

## 5. App 2: PDFGenius / All-in-One PDF (ABSORB)

**Path:** `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/PDFGenius/`
**Bundle ID:** `com.documentintelligence.pdfgenius`
**Store name:** "All-in-One PDF"
**Version:** 1.0.0 build 1
**Tint color:** `.purple`

### Current Tab Structure

```
Tab 0: "Documents" (doc.fill)              -> DocumentListView
Tab 1: "Tools" (slider.horizontal.3)       -> PDFToolsView
Tab 2: "Settings" (gear)                   -> PDFSettingsView
```

### Views to Copy into DocuScanAI

| Source File | What It Does | Target Tab |
|---|---|---|
| `PDFEditorView.swift` | PDF editing with floating toolbar (highlight, underline, text, draw), undo/redo, signature sheet, AI assistant sheet. Contains `EditingTool` enum and `PDFEditableView` UIViewRepresentable. | PDF Tools |
| `PDFToolsView.swift` | Grid of tools: Merge, Split, Compress, Convert, Password (Pro), OCR (Pro). | PDF Tools |
| `PDFAIAssistantView.swift` | Segmented control: Summary, Contract Analysis, Ask AI. | PDF Tools (sub-view) |
| `SignatureView.swift` | Canvas-based signature drawing with clear/done buttons. | PDF Tools (sheet) |
| `DocumentListView.swift` | PDF file list with file importer for `.pdf` files, search. | Documents (merge into HomeView or separate section) |

### ViewModels to Copy

| Source File | What It Does |
|---|---|
| `PDFEditorViewModel.swift` | PDF editing operations, annotation management, undo/redo stack, AI features, merge/split |
| `PDFDocumentListViewModel.swift` | PDF file import, document management |

### Subscription System

**Also uses RevenueCat (separate API key and products).**

- **API Key:** `appl_GtPahdnIplNbumCJhqbsscYRlpj`
- **Entitlement ID:** `"pro"`
- **Product IDs:**
  - `pdfgenius_pro_monthly`
  - `pdfgenius_pro_annual`
  - `pdfgenius_pro_lifetime`

### Feature Gating

`ProFeature.swift` defines 10 pro features for PDFGenius:
- `signatures`, `drawing`, `mergeSplit`, `aiSummary`, `aiContractAnalysis`, `aiQA`, `ocrExtraction`, `passwordProtection`, `convertToImages`, `noWatermark`

### Info.plist Notable Entries

| Key | Value |
|---|---|
| `CFBundleDocumentTypes` | Registers as PDF editor (`com.adobe.pdf`) |
| `LSSupportsOpeningDocumentsInPlace` | `true` |
| `UIFileSharingEnabled` | `true` |
| `NSPhotoLibraryAddUsageDescription` | "...needs access to save exported PDF pages as images..." |

### What to absorb into DocuScanAI

- **PDFEditorView** + **PDFEditorViewModel** (full PDF editing UI)
- **PDFToolsView** (the tools grid)
- **PDFAIAssistantView** (AI for PDFs)
- **SignatureView** (signature canvas)
- **PDFDocumentListViewModel** (PDF import logic -- may merge into existing HomeViewModel)
- **PDF Document Type registration** from Info.plist
- **File sharing flags** from Info.plist

### What to DISCARD

- `PDFGeniusApp.swift` (use DocuScanAIApp instead)
- `PDFContentView.swift` (replaced by new 5-tab ContentView)
- `PDFSettingsView.swift` (merge relevant settings into DocuScanAI SettingsView)
- `PDFAppState` class (merge into DocuScanAI's AppState)
- PDFGenius's `SubscriptionManager.swift` (use DocuScanAI's RevenueCat setup)
- PDFGenius's `ProFeature.swift` (merge cases into DocuScanAI's ProFeature enum)
- PDFGenius's `PaywallView.swift` (use DocuScanAI's PaywallView)

---

## 6. App 3: InvoiceFlowAI / InvoiceFlow Pro (ABSORB)

**Path:** `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/InvoiceFlowAI/`
**Bundle ID:** `com.documentintelligence.invoiceflow`
**Store name:** "InvoiceFlow Pro"
**Version:** 1.0.0 build 2
**Tint color:** `.green`

### Current Tab Structure

```
Tab 0: "Invoices" (doc.text.fill)          -> InvoiceListView
Tab 1: "Clients" (person.2.fill)           -> ClientsView
Tab 2: "Items" (list.bullet.rectangle)     -> ItemsView
Tab 3: "Settings" (gear)                   -> InvoiceSettingsView
```

### Views to Copy into DocuScanAI

| Source File | Lines | What It Does | Target Tab |
|---|---|---|---|
| `InvoiceListView.swift` | | Invoice list with create options (manual, voice, receipt scan). Contains `InvoiceRow`, `StatusBadge`. | Invoices |
| `CreateInvoiceView.swift` | | Form: client selection, invoice details, line items, summary, notes. Contains `LineItemRow`, `SelectClientView`. | Invoices |
| `InvoiceDetailView.swift` | | Header, client card, line items, totals, actions (send, download PDF). Contains `InvoiceDetailViewModel`. | Invoices |
| `ClientsView.swift` | | Client list, add client, client detail. Contains `ClientRow`, `ClientDetailView`, `AddClientView`. | Invoices (sub-tab) |
| `ItemsView.swift` | | Item templates list, add item. Contains `ItemTemplateRow`, `AddItemView`, `ItemsViewModel`. | Invoices (sub-tab) |
| `VoiceToInvoiceView.swift` | | Voice recording UI, transcript display, extracted invoice data. Contains `ExtractedInvoiceData`. Pro feature. | Invoices |
| `ScanReceiptView.swift` | | Receipt scanning with VisionKit, extracted expense display. Contains `ReceiptScannerView`, `ExtractedExpense`, `ExpenseItem`. Pro feature. | Invoices |
| `DashboardView.swift` | | Revenue charts (Charts framework), status breakdown, top clients, recent activity. Contains `SummaryCard`, `PieChartView`, `DashboardViewModel`. | Invoices |
| `InvoiceSettingsView.swift` | ~1600 | Business info, logo picker, signature, currency, tax rate, payment details (bank/PayPal/Venmo/Zelle/Stripe), invoice numbering, recurring invoices, late fees, notifications, export/backup. **Very large file.** | Settings |
| `EstimateListView.swift` | | Estimate management | Invoices |
| `CreateEstimateView.swift` | | Estimate creation | Invoices |
| `EstimateDetailView.swift` | | Estimate detail | Invoices |
| `ExportDataView.swift` | | CSV/PDF data export | Settings |
| `LateFeeSettingsView.swift` | | Late fee configuration | Settings |
| `SignatureView.swift` | | Signature for invoices (separate from PDFGenius signature) | Settings |
| `CloudSyncSettingsView.swift` | | iCloud sync settings | Settings |

### ViewModels to Copy

| Source File | What It Does |
|---|---|
| `InvoiceListViewModel.swift` | Invoice list management, filtering, sorting |
| `CreateInvoiceViewModel.swift` | Invoice creation: line items, tax calculation, totals |
| `ClientsViewModel.swift` | Client CRUD operations |
| `ScanReceiptViewModel.swift` | Receipt scanning + AI extraction of expense data |
| `VoiceToInvoiceViewModel.swift` | SFSpeechRecognizer + AVAudioEngine for voice input |
| `EstimateListViewModel.swift` | Estimate management |
| `CreateEstimateViewModel.swift` | Estimate creation |

### Services to Copy

| Source File | What It Does |
|---|---|
| `CSVExporter.swift` | CSV export utility |
| `ClientPortalGenerator.swift` | Client portal generation |
| `CloudSyncManager.swift` | iCloud sync manager |
| `NetworkMonitor.swift` | Network reachability (NWPathMonitor) |
| `PDFTemplateGenerator.swift` | PDF invoice template rendering |
| `SearchAdsAttribution.swift` | Apple Search Ads attribution |
| `FacebookSDKManager.swift` | Facebook/Meta Ads SDK wrapper |

### Models (CRITICAL -- very large)

`Models.swift` (~1000+ lines) contains:

```swift
struct Invoice              // Main invoice model with Status enum, DiscountType enum, InvoiceTemplate enum
struct Payment              // Payment with PaymentMethod enum (cash, bankTransfer, creditCard, payPal, venmo, zelle, stripe, other)
struct LineItem             // Invoice line item
struct Client               // Client with contact info, notes
struct ItemTemplate         // Reusable item template
struct Estimate             // Project estimate
struct BusinessInfo         // User's business info (name, email, phone, address, taxID, website, logo)
struct PaymentDetails       // Bank, PayPal, Venmo, Zelle, Stripe details
struct InvoiceNumberSettings // Auto-numbering prefix, next number, date format
struct RecurringInvoice     // Recurring invoice schedule
struct LateFeeSettings      // Late fee configuration
class InvoiceStorage        // Singleton, UserDefaults-based storage for invoices, clients, items, estimates, etc.
class NotificationManager   // UNUserNotificationCenter for payment reminders
enum Currency               // USD, EUR, GBP, CAD, AUD, JPY, INR
```

**IMPORTANT:** `InvoiceStorage` uses **UserDefaults** (encoding to JSON), NOT Core Data. This is independent from DocumentCore's Core Data store.

### Subscription System

InvoiceFlowAI's paywall (`InvoiceFlowPaywallView` inside `InvoiceSettingsView.swift`) uses `StoreKitManager` from DocumentCore directly (NOT RevenueCat). Product IDs referenced:
- `com.documentintelligence.invoiceflow.pro.monthly` (from StoreKitManager.ProductID.invoiceFlowPro)
- It also references a yearly product

### Info.plist Permissions

| Key | Value |
|---|---|
| `NSCameraUsageDescription` | "InvoiceFlow AI needs camera access to scan receipts" |
| `NSMicrophoneUsageDescription` | "InvoiceFlow AI needs microphone access for voice-to-invoice feature" |
| `NSPhotoLibraryUsageDescription` | "InvoiceFlow AI needs photo library access to import receipts" |
| `NSSpeechRecognitionUsageDescription` | "InvoiceFlow AI uses speech recognition for voice-to-invoice feature" |
| `NSUserTrackingUsageDescription` | "This identifier will be used to deliver personalized ads to you." |
| Facebook SDK keys | `FacebookAppID`, `FacebookClientToken`, `FacebookAdvertiserIDCollectionEnabled`, etc. |
| `CFBundleURLTypes` | Facebook URL scheme (`fb$(FACEBOOK_APP_ID)`) |
| `LSApplicationQueriesSchemes` | `fbapi`, `fb-messenger-share-api`, `fbauth2`, `fbshareextension` |

### Entitlements

`InvoiceFlowAI.entitlements`:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.documentintelligence.invoiceflow</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

### What to DISCARD

- `InvoiceFlowAIApp.swift` (use DocuScanAIApp instead)
- `InvoiceContentView.swift` (replaced by new 5-tab ContentView)
- `InvoiceAppState` class (merge `freeInvoiceLimit`/`canCreateInvoice` logic into DocuScanAI's AppState)
- InvoiceFlow's paywall view (replace with DocuScanAI's RevenueCat paywall)

---

## 7. Target Tab Structure

The merged DocuScanAI app will have **5 tabs**:

```swift
// New ContentView.swift
TabView(selection: $selectedTab) {
    // Tab 0: Scan (from existing DocuScanAI)
    ScannerView()
        .tabItem { Label("Scan", systemImage: "camera.fill") }
        .tag(0)

    // Tab 1: Documents (from existing DocuScanAI HomeView)
    HomeView()
        .tabItem { Label("Documents", systemImage: "doc.fill") }
        .tag(1)

    // Tab 2: PDF Tools (from PDFGenius)
    PDFToolsView()
        .tabItem { Label("PDF Tools", systemImage: "slider.horizontal.3") }
        .tag(2)

    // Tab 3: Invoices (from InvoiceFlowAI -- may need internal navigation for Clients/Items)
    InvoiceNavigationView() // wrapper with internal tabs or segmented control for Invoices/Clients/Items
        .tabItem { Label("Invoices", systemImage: "doc.text.fill") }
        .tag(3)

    // Tab 4: Settings (merged from all three)
    SettingsView() // expanded to include invoice settings, PDF settings
        .tabItem { Label("Settings", systemImage: "gear") }
        .tag(4)
}
.tint(.blue) // Keep DocuScanAI's brand color
```

### Design Decision: Invoice Tab Internal Navigation

InvoiceFlowAI currently has 4 separate tabs (Invoices, Clients, Items, Settings). Since we only get one tab in the merged app, create an **InvoiceNavigationView** that provides internal navigation:

**Option A (Recommended):** Use a NavigationStack within the Invoices tab. The main view shows `InvoiceListView`. Clients and Items are accessible via toolbar buttons or navigation links. Dashboard is accessible from a button in the invoice list header.

**Option B:** Use a segmented picker at the top (Invoices | Clients | Items | Dashboard).

The invoice settings (business info, payment details, recurring invoices, etc.) should be moved into the main Settings tab under an "Invoice Settings" section.

---

## 8. Phase 1: Merge PDF Features into DocuScanAI

### Step-by-step instructions

#### 8.1 Copy files

Copy the following files from `Apps/PDFGenius/PDFGenius/` into `Apps/DocuScanAI/DocuScanAI/`:

**Views (into DocuScanAI/Views/PDF/):**
1. `Views/PDFEditorView.swift`
2. `Views/PDFToolsView.swift`
3. `Views/PDFAIAssistantView.swift`
4. `Views/SignatureView.swift`

**ViewModels (into DocuScanAI/ViewModels/):**
1. `ViewModels/PDFEditorViewModel.swift`
2. `ViewModels/PDFDocumentListViewModel.swift`

**Models (into DocuScanAI/App/):**
1. Merge `PDFDocumentItem` from `App/Models.swift` into DocuScanAI's `Models.swift`

#### 8.2 Resolve naming conflicts

The following types exist in BOTH DocuScanAI and PDFGenius and will conflict:

| Type | DocuScanAI version | PDFGenius version | Resolution |
|---|---|---|---|
| `SubscriptionManager` | RevenueCat, docuscan products | RevenueCat, pdfgenius products | **Keep DocuScanAI's.** Remove references to PDFGenius's SubscriptionManager from copied files. |
| `SubscriptionTier` | Local enum in SubscriptionManager.swift | Local enum in SubscriptionManager.swift | **Keep DocuScanAI's.** Already identical (.free/.pro). |
| `EntitlementID` | `"pro"` | `"pro"` | **Keep DocuScanAI's.** Same value. |
| `ProductID` | docuscan products | pdfgenius products | **Keep DocuScanAI's.** Add pdfgenius product IDs if cross-app restore is needed. |
| `ProFeature` | 8 cases (scanner features) | 10 cases (PDF features) | **Merge:** Add PDFGenius's 10 cases into DocuScanAI's ProFeature enum. |
| `FeatureGate` | Singleton in ProFeature.swift | Singleton in ProFeature.swift | **Keep DocuScanAI's.** Already has same interface. |
| `ProBadgeOverlay` | In ProFeature.swift | In ProFeature.swift | **Keep DocuScanAI's.** Same UI. |
| `FeatureGatedModifier` | In ProFeature.swift | In ProFeature.swift | **Keep DocuScanAI's.** Same logic. |
| `ProFeatureButton` | In ProFeature.swift | In ProFeature.swift | **Keep DocuScanAI's.** Same interface. |

#### 8.3 Update DocuScanAI's ProFeature enum

Add PDFGenius-specific features to DocuScanAI's `ProFeature` enum in `Subscription/ProFeature.swift`:

```swift
enum ProFeature: String, CaseIterable, Identifiable {
    // Existing scanner features
    case ocrExtraction = "ocr"
    case aiSummary = "ai_summary"
    case autoTitle = "auto_title"
    case fieldExtraction = "field_extraction"
    case askAI = "ask_ai"
    case searchInDocuments = "search_documents"
    case noWatermark = "no_watermark"
    case cloudSync = "cloud_sync"

    // NEW: PDF features (from PDFGenius)
    case signatures = "signatures"
    case drawing = "drawing"
    case mergeSplit = "merge_split"
    case aiContractAnalysis = "ai_contract_analysis"
    case passwordProtection = "password_protection"
    case convertToImages = "convert_to_images"

    // ... add displayName, description, icon, color for each new case
}
```

Note: `aiSummary`, `ocrExtraction`, `noWatermark` already exist in both enums with the same raw values, so no duplication.

#### 8.4 Update the copied PDFGenius views

In each copied view/viewmodel, replace:
- `SubscriptionManager.shared` references -> keep as-is (DocuScanAI's SubscriptionManager has the same interface)
- `ProFeature.signatures` etc. -> ensure the new merged ProFeature enum has matching cases
- `PDFAppState` references -> replace with DocuScanAI's `AppState`
- Remove any `import RevenueCat` that is not needed (it's only needed in SubscriptionManager.swift)

#### 8.5 Add "PDF Tools" tab to ContentView

Modify `Apps/DocuScanAI/DocuScanAI/App/ContentView.swift` to add the PDF Tools tab (see [Section 7](#7-target-tab-structure)).

#### 8.6 Update Info.plist

Add these keys from PDFGenius's Info.plist to DocuScanAI's Info.plist:

```xml
<!-- PDF document type handler -->
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>PDF</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.adobe.pdf</string>
        </array>
    </dict>
</array>

<!-- Enable file sharing and open-in-place -->
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UIFileSharingEnabled</key>
<true/>

<!-- Photo Library Add (for exporting PDF pages as images) -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>DocuScan AI needs access to save exported PDF pages as images to your Photos library.</string>
```

#### 8.7 Add PDFGenius files to Xcode project

Add all copied files to the DocuScanAI Xcode target. This means opening `Apps/DocuScanAI/DocuScanAI.xcodeproj` and ensuring the new files are included in the DocuScanAI target's "Compile Sources" build phase.

#### 8.8 Test Phase 1

- [ ] App compiles without errors
- [ ] All 4 tabs visible (Documents, Scan, PDF Tools, Settings)
- [ ] Can open/view a PDF file
- [ ] Can add annotations (highlight, underline, text)
- [ ] Can draw on PDF
- [ ] Can add signature to PDF
- [ ] Merge PDFs works
- [ ] Split PDF works
- [ ] PDF AI assistant works (summary, contract analysis, ask AI)
- [ ] Pro features are properly gated
- [ ] Paywall shows when tapping locked features
- [ ] Existing DocuScanAI features still work (scan, OCR, AI insights)

---

## 9. Phase 2: Merge Invoice Features into DocuScanAI

### Step-by-step instructions

#### 9.1 Copy files

Copy from `Apps/InvoiceFlowAI/InvoiceFlowAI/` into `Apps/DocuScanAI/DocuScanAI/`:

**Models (into DocuScanAI/App/ or new DocuScanAI/Models/ directory):**
1. The entire contents of `App/Models.swift` -- this is the big one with Invoice, Client, LineItem, Payment, etc.
   - **Rename to `InvoiceModels.swift`** to avoid conflict with DocuScanAI's `Models.swift`

**Views (into DocuScanAI/Views/Invoice/):**
1. `Views/InvoiceListView.swift`
2. `Views/CreateInvoiceView.swift`
3. `Views/InvoiceDetailView.swift`
4. `Views/ClientsView.swift`
5. `Views/ItemsView.swift`
6. `Views/VoiceToInvoiceView.swift`
7. `Views/ScanReceiptView.swift`
8. `Views/DashboardView.swift`
9. `Views/InvoiceSettingsView.swift` (will be refactored -- see 9.4)
10. `Views/EstimateListView.swift`
11. `Views/CreateEstimateView.swift`
12. `Views/EstimateDetailView.swift`
13. `Views/ExportDataView.swift`
14. `Views/LateFeeSettingsView.swift`
15. `Views/SignatureView.swift` -- **Rename to `InvoiceSignatureView.swift`** to avoid conflict with PDFGenius's SignatureView
16. `Views/CloudSyncSettingsView.swift`

**ViewModels (into DocuScanAI/ViewModels/):**
1. `ViewModels/InvoiceListViewModel.swift`
2. `ViewModels/CreateInvoiceViewModel.swift`
3. `ViewModels/ClientsViewModel.swift`
4. `ViewModels/ScanReceiptViewModel.swift`
5. `ViewModels/VoiceToInvoiceViewModel.swift`
6. `ViewModels/EstimateListViewModel.swift`
7. `ViewModels/CreateEstimateViewModel.swift`

**Services (into DocuScanAI/Services/):**
1. `Services/CSVExporter.swift`
2. `Services/ClientPortalGenerator.swift`
3. `Services/CloudSyncManager.swift`
4. `Services/NetworkMonitor.swift`
5. `Services/PDFTemplateGenerator.swift`
6. `Services/SearchAdsAttribution.swift`
7. `Services/FacebookSDKManager.swift`

#### 9.2 Resolve naming conflicts

| Type | Conflict | Resolution |
|---|---|---|
| `SignatureView` | Exists in both PDFGenius and InvoiceFlowAI | Rename InvoiceFlowAI's to `InvoiceSignatureView` |
| `InvoiceAppState` | Has `freeInvoiceLimit`, `canCreateInvoice` | Merge these properties into DocuScanAI's `AppState` |
| `WatermarkService` | DocuScanAI has local version in Services/ | Keep DocuScanAI's (they may reference different branding text) |

#### 9.3 Update DocuScanAI's ProFeature enum (again)

Add invoice-specific features:

```swift
enum ProFeature: String, CaseIterable, Identifiable {
    // ... existing scanner + PDF features ...

    // NEW: Invoice features (from InvoiceFlowAI)
    case unlimitedInvoices = "unlimited_invoices"
    case clientDatabase = "client_database"
    case itemTemplates = "item_templates"
    case recurringInvoices = "recurring_invoices"
    case taxCalculation = "tax_calculation"
    case logoUpload = "logo_upload"
    case paymentTracking = "payment_tracking"
    case voiceToInvoice = "voice_to_invoice"
    case receiptScan = "receipt_scan"

    // ... add displayName, description, icon, color for each new case
}
```

#### 9.4 Refactor InvoiceSettingsView

`InvoiceSettingsView.swift` is ~1600 lines and contains its own paywall (`InvoiceFlowPaywallView`). You need to:

1. **Remove `InvoiceFlowPaywallView`** from this file entirely
2. **Replace paywall references** with DocuScanAI's RevenueCat-based paywall
3. **Move invoice-specific settings** (business info, payment details, invoice numbering, recurring invoices, late fees, notifications) into a sub-section of DocuScanAI's Settings tab, e.g., a NavigationLink "Invoice Settings" that opens a dedicated view
4. **Replace `StoreKitManager` references** with `SubscriptionManager.shared` (RevenueCat)

#### 9.5 Update DocuScanAI's AppState

```swift
class AppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false

    // NEW: Invoice state (from InvoiceAppState)
    @Published var invoicesThisMonth: Int = 0
    let freeInvoiceLimit = 3

    var canCreateInvoice: Bool {
        isProUser || invoicesThisMonth < freeInvoiceLimit
    }

    // ... existing init/checkSubscription
}
```

#### 9.6 Create InvoiceNavigationView

Create a new wrapper view for the Invoices tab that provides internal navigation:

```swift
struct InvoiceNavigationView: View {
    var body: some View {
        NavigationStack {
            InvoiceListView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            NavigationLink("Clients") { ClientsView() }
                            NavigationLink("Items") { ItemsView() }
                            NavigationLink("Dashboard") { DashboardView() }
                            NavigationLink("Estimates") { EstimateListView() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}
```

#### 9.7 Handle Facebook SDK

InvoiceFlowAI initializes the Facebook SDK in its app entry point. Decide whether to:

**Option A (Recommended for now):** Remove Facebook SDK from the merged app. The SDK was for InvoiceFlow Pro attribution only, and with <10 downloads, the ROI is negligible.

**Option B:** Keep it. If so, add to DocuScanAIApp.swift:
```swift
init() {
    FacebookSDKManager.shared.initialize()
    Task { await SearchAdsAttribution.shared.fetchAttribution() }
}
```
And add all Facebook SDK Info.plist keys to DocuScanAI's Info.plist.

#### 9.8 Update Info.plist

Add these permissions to DocuScanAI's Info.plist:

```xml
<!-- Microphone for voice-to-invoice -->
<key>NSMicrophoneUsageDescription</key>
<string>DocuScan AI needs microphone access for the voice-to-invoice feature</string>

<!-- Speech recognition for voice-to-invoice -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>DocuScan AI uses speech recognition for the voice-to-invoice feature</string>
```

Update the existing camera and photo library descriptions to cover both scanning and receipt import:

```xml
<key>NSCameraUsageDescription</key>
<string>DocuScan AI needs camera access to scan documents and receipts</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>DocuScan AI needs photo library access to import documents and receipts</string>
```

#### 9.9 Add iCloud Entitlements

Create or update entitlements for DocuScanAI. The merged app needs iCloud for cloud sync. You may need to create `DocuScanAI.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.documentintelligence.docuscan</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudDocuments</string>
    </array>
    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.com.documentintelligence.docuscan</string>
    </array>
</dict>
</plist>
```

**NOTE:** The container identifier changes from `iCloud.com.documentintelligence.invoiceflow` to `iCloud.com.documentintelligence.docuscan`. Data from InvoiceFlow's iCloud container will NOT automatically migrate. Given <10 downloads, this is acceptable.

#### 9.10 Add Speech and Charts frameworks

Ensure the DocuScanAI Xcode project links:
- `Speech.framework` (for VoiceToInvoiceViewModel)
- `Charts` framework (for DashboardView -- available in iOS 16+, already part of SwiftUI Charts)
- `AVFoundation` (for AVAudioEngine in voice recording)
- `UserNotifications` (for NotificationManager)

#### 9.11 Test Phase 2

- [ ] App compiles without errors
- [ ] All 5 tabs visible (Scan, Documents, PDF Tools, Invoices, Settings)
- [ ] Can create an invoice manually
- [ ] Can add line items with tax calculation
- [ ] Can add/edit clients
- [ ] Can add/edit item templates
- [ ] Can create invoice from voice (Pro)
- [ ] Can scan receipt and extract expense data (Pro)
- [ ] Dashboard shows charts
- [ ] Can create/manage estimates
- [ ] Invoice PDF generation works (with watermark for free, without for Pro)
- [ ] Business info settings save correctly
- [ ] Payment details settings work
- [ ] Recurring invoices can be created
- [ ] Export data works
- [ ] ALL Phase 1 features still work
- [ ] ALL original DocuScanAI features still work
- [ ] Pro features gated correctly across all tabs

---

## 10. Phase 3: Sunset Old Apps

### 10.1 Update InvoiceFlow Pro

Push an update to InvoiceFlow Pro that shows a message directing users to DocuScanAI:

```swift
// Replace InvoiceContentView with a migration notice
struct InvoiceContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("InvoiceFlow Pro has moved!")
                .font(.title.bold())
            Text("All invoice features are now available in DocuScan AI, along with document scanning, PDF editing, and more.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Link("Get DocuScan AI", destination: URL(string: "https://apps.apple.com/app/idXXXXXXXXXX")!)
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding()
    }
}
```

### 10.2 Update All-in-One PDF

Same approach for PDFGenius app.

### 10.3 Timeline

- Keep old listings live for 3-6 months
- Eventually "Remove from Sale" in App Store Connect
- Do NOT delete the apps -- just hide them

---

## 11. Paywall / Subscription Integration

### Current State (confusing -- needs cleanup)

There are **three separate subscription systems** in the codebase:

1. **DocumentCore's `StoreKitManager`** (StoreKit 2)
   - Product IDs: `com.documentintelligence.docuscan.pro.monthly`, `com.documentintelligence.pdfgenius.pro.monthly`, `com.documentintelligence.invoiceflow.pro.monthly`
   - Used by: InvoiceFlowAI's paywall only

2. **DocuScanAI's `SubscriptionManager`** (RevenueCat)
   - API Key: `appl_GLZeYTvGYnnLQktoQgmqDInOsNW`
   - Product IDs: `docuscan_pro_monthly`, `docuscan_pro_annual`, `docuscan_pro_lifetime`
   - Entitlement: `"pro"`

3. **PDFGenius's `SubscriptionManager`** (RevenueCat)
   - API Key: `appl_GtPahdnIplNbumCJhqbsscYRlpj`
   - Product IDs: `pdfgenius_pro_monthly`, `pdfgenius_pro_annual`, `pdfgenius_pro_lifetime`
   - Entitlement: `"pro"`

### Target State

**Use DocuScanAI's RevenueCat `SubscriptionManager` as the single source of truth.**

- API Key: `appl_GLZeYTvGYnnLQktoQgmqDInOsNW` (DocuScanAI's)
- Product IDs: `docuscan_pro_monthly`, `docuscan_pro_annual`, `docuscan_pro_lifetime`
- Entitlement: `"pro"`
- One Pro tier unlocks ALL features (scanning, PDF editing, invoicing)

### What to do

1. **Keep** `Apps/DocuScanAI/DocuScanAI/Subscription/SubscriptionManager.swift` as-is
2. **Keep** `Apps/DocuScanAI/DocuScanAI/Subscription/PaywallView.swift` as-is (update feature list to include all three apps' features)
3. **Expand** `Apps/DocuScanAI/DocuScanAI/Subscription/ProFeature.swift` to include all features from all three apps
4. **Do NOT use** PDFGenius's SubscriptionManager or API key
5. **Do NOT use** DocumentCore's StoreKitManager (remove references from copied InvoiceFlowAI code)
6. **Update** the paywall's feature list to showcase all three verticals:
   - "Scan & OCR: Extract text, AI summaries, auto-titles"
   - "PDF Tools: Edit, annotate, sign, merge/split PDFs"
   - "Invoices: Unlimited invoices, voice input, receipt scanning"

### RevenueCat Product Configuration

In RevenueCat dashboard, ensure the `docuscan_pro_monthly/annual/lifetime` products grant the `"pro"` entitlement. This single entitlement unlocks everything.

### Cross-app subscriber migration

If any PDFGenius or InvoiceFlow Pro users have active subscriptions, they will NOT automatically get Pro in DocuScanAI (different bundle ID, different RevenueCat project). Given <50 total downloads across both apps and likely zero paid subscribers, this is acceptable. If needed later, RevenueCat supports transferring entitlements via their API.

---

## 12. Info.plist Permissions -- Merged App

The final DocuScanAI Info.plist should contain ALL of these:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Identity -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>DocuScan AI</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DocuScanAI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>

    <!-- Encryption -->
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>

    <!-- Camera (scanning docs + receipts) -->
    <key>NSCameraUsageDescription</key>
    <string>DocuScan AI needs camera access to scan documents and receipts</string>

    <!-- Photo Library (import docs + receipts) -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>DocuScan AI needs photo library access to import documents and receipts</string>

    <!-- Photo Library Add (export PDF pages as images) -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>DocuScan AI needs access to save exported PDF pages as images to your Photos library</string>

    <!-- Microphone (voice-to-invoice) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>DocuScan AI needs microphone access for the voice-to-invoice feature</string>

    <!-- Speech Recognition (voice-to-invoice) -->
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>DocuScan AI uses speech recognition to convert voice input into invoices</string>

    <!-- User Tracking (attribution) -->
    <key>NSUserTrackingUsageDescription</key>
    <string>This allows us to provide you with a better, personalized experience and measure the effectiveness of our ads.</string>

    <!-- PDF Document Type Handler (from PDFGenius) -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>PDF</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.adobe.pdf</string>
            </array>
        </dict>
    </array>

    <!-- File Sharing (from PDFGenius) -->
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
    <key>UIFileSharingEnabled</key>
    <true/>

    <!-- Launch Screen -->
    <key>UILaunchScreen</key>
    <dict>
        <key>UIColorName</key>
        <string>LaunchBackground</string>
    </dict>

    <!-- Orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
```

**NOTE on Microphone + Speech Recognition:** Apple will ask during App Review why these permissions are needed. The app metadata / "Notes for Reviewer" should explain: "Microphone and Speech Recognition are used for the voice-to-invoice feature, which allows users to dictate invoice details." Make sure to demonstrate this feature in the review notes.

---

## 13. Data Model and Storage

### Two independent storage systems

The merged app will have TWO storage systems running side by side:

1. **Core Data via `DocumentStore` (from DocumentCore)**
   - Container name: `"DocumentCore"`
   - Entities: `DocumentEntity`, `FolderEntity`
   - Used for: Scanned documents, folders, OCR text, AI summaries
   - Persistent store: SQLite in app's Application Support directory

2. **UserDefaults via `InvoiceStorage` (from InvoiceFlowAI)**
   - Keys: invoices, clients, items, estimates, business info, payment details, etc.
   - Used for: All invoice data
   - Persistent store: UserDefaults plist

### Why not merge them?

The two systems store fundamentally different data types. Merging them into one Core Data store would require:
- Creating new Core Data entities for Invoice, Client, LineItem, Payment, etc.
- Migrating InvoiceStorage from UserDefaults to Core Data
- Rewriting all InvoiceFlowAI ViewModels to use Core Data

This is a significant refactor with no user-facing benefit. **Keep them separate for now.** A future version can unify storage.

### Core Data Model (programmatic)

DocumentCore defines entities programmatically (no .xcdatamodeld file):

**DocumentEntity:**
- `id: UUID`
- `title: String?`
- `type: String?` (scan, import, pdf)
- `fileURL: String?`
- `thumbnailData: Data?`
- `ocrText: String?`
- `aiSummary: String?`
- `aiTitle: String?`
- `tags: String?` (comma-separated)
- `createdAt: Date?`
- `updatedAt: Date?`
- `pageCount: Int16`
- `fileSize: Int64`
- `folder: FolderEntity?` (to-one)

**FolderEntity:**
- `id: UUID`
- `name: String?`
- `color: String?`
- `createdAt: Date?`
- `documents: Set<DocumentEntity>` (to-many, cascade delete)

### InvoiceStorage (UserDefaults)

`InvoiceStorage` is a singleton class defined in `InvoiceFlowAI/App/Models.swift`. It saves/loads all invoice data to UserDefaults using JSON encoding. Key methods:
- `saveInvoices(_:)`, `loadInvoices() -> [Invoice]`
- `saveClients(_:)`, `loadClients() -> [Client]`
- `saveItemTemplates(_:)`, `loadItemTemplates() -> [ItemTemplate]`
- `saveEstimates(_:)`, `loadEstimates() -> [Estimate]`
- `saveBusinessInfo(_:)`, `loadBusinessInfo() -> BusinessInfo?`
- `savePaymentDetails(_:)`, `loadPaymentDetails() -> PaymentDetails?`
- `saveInvoiceNumberSettings(_:)`, `loadInvoiceNumberSettings() -> InvoiceNumberSettings`
- `saveCurrency(_:)`, `loadCurrency() -> Currency`
- `saveTaxRate(_:)`, `loadTaxRate() -> Double`

---

## 14. AI Service and API Key Concerns

### Architecture

All AI features go through `DocumentCore/Sources/AI/AIService.swift`, which is a proxy-based architecture:

```
App -> AIService.swift -> GCP Cloud Run Proxy -> OpenAI GPT-4
```

### Proxy Details

- **Proxy URL:** `https://docint-proxy-917362189743.us-central1.run.app`
- **App API Key:** `docint-f8a3b2c1-4d5e-6f7a-8b9c-0d1e2f3a4b5c`
- **Verification:** Bundle ID sent in `X-Bundle-ID` header

### Security Assessment

- **GOOD:** OpenAI API key is NOT in client code; it's on the proxy server
- **CONCERN:** The app API key (`docint-f8a3b2c1-...`) is hardcoded in the Swift source. This is a minor risk since it only authenticates with the proxy (not OpenAI directly), and the proxy also checks bundle ID
- **CONCERN:** The proxy verifies `Bundle.main.bundleIdentifier`. Since we're keeping `com.documentintelligence.docuscan`, this should work. But verify the proxy's allowed bundle ID list includes this bundle ID (it likely does since DocuScanAI already uses it)

### Bundle ID Consideration

The proxy sends `X-Bundle-ID` with the request. Since the merged app uses `com.documentintelligence.docuscan`, which is the same bundle ID DocuScanAI already uses, no proxy configuration changes are needed.

### AI Features Used by Each App

| Feature | Used By | AI Endpoint | Prompt From |
|---|---|---|---|
| Document Summary | DocuScanAI, PDFGenius | `chatCompletion` | `Prompts.summarize` |
| Auto-Title | DocuScanAI | `analyzeDocument(.title)` | `Prompts.autoTitle` |
| Field Extraction | DocuScanAI | `chatCompletion` | `Prompts.fieldExtraction` |
| Ask AI | DocuScanAI, PDFGenius | `askQuestion` | `Prompts.questionAnswering` |
| Contract Analysis | PDFGenius | `chatCompletion` | `Prompts.contractAnalysis` |
| Key Points | PDFGenius | `chatCompletion` | `Prompts.keyPoints` |
| Categorize | DocuScanAI | `analyzeDocument(.categorize)` | `Prompts.categorize` |
| Invoice Field Extraction | InvoiceFlowAI (receipt scan) | `chatCompletion` | `Prompts.invoiceExtraction` |
| Receipt Field Extraction | InvoiceFlowAI (receipt scan) | `chatCompletion` | `Prompts.receiptExtraction` |
| Voice-to-Invoice Parsing | InvoiceFlowAI | `extractStructuredData` | Custom system prompt in VoiceToInvoiceViewModel |

---

## 15. Naming Conflicts and Resolution Strategy

### Critical: Type Name Collisions

When all three apps' code is compiled in one target, these types will collide:

| Type Name | Defined In | Resolution |
|---|---|---|
| `SubscriptionManager` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. Do not copy PDFGenius's. |
| `SubscriptionTier` (local) | DocuScanAI + PDFGenius (both, in SubscriptionManager.swift) | Keep DocuScanAI's only. |
| `EntitlementID` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. |
| `ProductID` (local) | DocuScanAI + PDFGenius (both, in SubscriptionManager.swift) | Keep DocuScanAI's only. |
| `ProFeature` | DocuScanAI + PDFGenius (both) | Merge all cases into one enum. |
| `FeatureGate` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. |
| `ProBadgeOverlay` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. |
| `FeatureGatedModifier` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. |
| `ProFeatureButton` | DocuScanAI + PDFGenius (both) | Keep DocuScanAI's only. |
| `SignatureView` | PDFGenius + InvoiceFlowAI (both) | Rename InvoiceFlowAI's to `InvoiceSignatureView`. |
| `AppState` / `PDFAppState` / `InvoiceAppState` | All three apps | Merge into DocuScanAI's `AppState`. |
| `ContentView` / `PDFContentView` / `InvoiceContentView` | All three apps | Keep only DocuScanAI's (rewritten). |
| `WatermarkService` | DocuScanAI (local) + DocumentCore (shared) | Keep DocuScanAI's local version (has app-specific branding). |

### Also Watch For

- `Package` extension (in both SubscriptionManager files) -- only include once
- `SubscriptionTier` in DocumentCore vs local definitions -- the DocumentCore one is `public` and will be visible; the local ones will shadow it. Since we are removing PDFGenius's SubscriptionManager entirely and replacing InvoiceFlow's paywall, this should resolve naturally.

---

## 16. Third-Party Dependencies

### Currently Used

| Dependency | Used By | How Included | Notes |
|---|---|---|---|
| **RevenueCat** (`Purchases`) | DocuScanAI, PDFGenius | SPM package dependency in Xcode project | Keep for merged app |
| **Facebook SDK** | InvoiceFlowAI | SPM or CocoaPods (check project) | Consider removing |
| **DocumentCore** | All three | Local SPM package | Already shared |

### Framework Dependencies (Apple)

| Framework | Used By | Needed For |
|---|---|---|
| `VisionKit` | DocuScanAI, InvoiceFlowAI | Document/receipt camera scanning |
| `Vision` | DocumentCore | OCR (VNRecognizeTextRequest), edge detection (VNDetectRectanglesRequest) |
| `PDFKit` | DocumentCore, PDFGenius | PDF viewing, editing, annotations |
| `CoreImage` | DocumentCore | Image filters, perspective correction |
| `CoreData` | DocumentCore | Document/folder storage |
| `StoreKit` | DocumentCore | StoreKit 2 (secondary, mostly unused) |
| `Speech` | InvoiceFlowAI | SFSpeechRecognizer for voice-to-invoice |
| `AVFoundation` | InvoiceFlowAI | AVAudioEngine for voice recording |
| `Charts` | InvoiceFlowAI | SwiftUI Charts for dashboard |
| `UserNotifications` | InvoiceFlowAI | Payment reminder notifications |
| `Network` | InvoiceFlowAI | NWPathMonitor for network reachability |
| `UniformTypeIdentifiers` | PDFGenius | UTType.pdf for file importer |

---

## 17. Testing Checklist

### Build Verification

- [ ] DocuScanAI target compiles with zero errors
- [ ] DocuScanAI target compiles with zero warnings (or only expected deprecation warnings)
- [ ] App launches without crash on iOS 16 simulator
- [ ] App launches without crash on iOS 17+ simulator

### Tab Navigation

- [ ] All 5 tabs render correctly
- [ ] Tab switching is smooth with no state loss
- [ ] Each tab has proper navigation bar title

### Scan Tab (existing)

- [ ] Camera opens
- [ ] Auto-edge detection works
- [ ] Can capture single page
- [ ] Can capture multi-page
- [ ] Filters apply correctly (B&W, color, contrast)
- [ ] PDF generated from scanned pages
- [ ] Document saves to Documents tab

### Documents Tab (existing)

- [ ] Document list loads
- [ ] Folders work
- [ ] Search works
- [ ] Sort options work
- [ ] Tapping document opens detail view
- [ ] AI Insights button works (Pro)
- [ ] OCR extraction works (Pro)
- [ ] AI summary works (Pro)
- [ ] Auto-title works (Pro)
- [ ] Field extraction works (Pro)
- [ ] Export with watermark (free)
- [ ] Export without watermark (Pro)

### PDF Tools Tab (Phase 1)

- [ ] PDF Tools grid displays all tools
- [ ] Can import PDF from Files
- [ ] PDF viewer loads and scrolls
- [ ] Highlight annotation works
- [ ] Underline annotation works
- [ ] Text annotation works
- [ ] Drawing/ink annotation works
- [ ] Undo/redo for annotations works
- [ ] Signature view opens
- [ ] Can draw and save signature
- [ ] Signature applied to PDF
- [ ] Merge PDFs works
- [ ] Split PDF works
- [ ] Compress PDF works
- [ ] Convert to images works
- [ ] Password protection works (Pro)
- [ ] OCR from PDF works (Pro)
- [ ] AI Summary from PDF works (Pro)
- [ ] AI Contract Analysis works (Pro)
- [ ] AI Ask Questions works (Pro)

### Invoices Tab (Phase 2)

- [ ] Invoice list displays
- [ ] Can create invoice manually
- [ ] Client selection works
- [ ] Line items add/edit/delete
- [ ] Tax calculation correct
- [ ] Discount calculation correct
- [ ] Invoice total correct
- [ ] Invoice PDF generation works
- [ ] Invoice PDF has watermark (free, after 3/month limit)
- [ ] Invoice PDF has no watermark (Pro)
- [ ] Can send invoice (share sheet)
- [ ] Clients view works (add, edit, delete)
- [ ] Items view works (add, edit, delete)
- [ ] Voice-to-invoice works (Pro)
  - [ ] Microphone permission prompt
  - [ ] Speech recognition permission prompt
  - [ ] Transcription displays
  - [ ] Extracted invoice data populates
- [ ] Receipt scanning works (Pro)
  - [ ] Camera opens for receipt
  - [ ] Receipt data extracted correctly
- [ ] Dashboard shows charts
- [ ] Estimates work
- [ ] Recurring invoices can be created
- [ ] Payment tracking works

### Settings Tab (merged)

- [ ] Subscription status displays correctly
- [ ] Paywall opens and shows all features
- [ ] Purchase flow works (sandbox)
- [ ] Restore purchases works
- [ ] Invoice settings section present
  - [ ] Business info saves
  - [ ] Logo upload works
  - [ ] Payment details save
  - [ ] Invoice numbering works
  - [ ] Currency selection works
  - [ ] Tax rate saves
- [ ] Cloud sync settings present
- [ ] Export data works
- [ ] About section present

### Subscription / Paywall

- [ ] Free user sees Pro badges on locked features
- [ ] Tapping locked feature opens paywall
- [ ] Paywall lists all features across all three verticals
- [ ] Purchase (monthly) works in sandbox
- [ ] Purchase (annual) works in sandbox
- [ ] Purchase (lifetime) works in sandbox
- [ ] After purchase, all Pro features unlock immediately
- [ ] After purchase, Pro badges disappear
- [ ] Restore purchases works
- [ ] Subscription status persists across app restart

### Edge Cases

- [ ] No crash when accessing AI features without internet
- [ ] Graceful error when AI proxy is unreachable
- [ ] PDF tools handle corrupted PDFs gracefully
- [ ] Voice-to-invoice handles denied microphone permission
- [ ] Voice-to-invoice handles denied speech recognition permission
- [ ] App handles denied camera permission for scanning
- [ ] Invoice limit (3/month) correctly enforced for free users
- [ ] Free user can still view existing invoices after hitting limit

---

## 18. Risk Assessment

| Risk | Level | Mitigation |
|---|---|---|
| PDF merge (Phase 1) | **Low** | PDFGenius views already use DocumentCore. Should compile with minimal changes. |
| Invoice merge (Phase 2) | **Medium** | InvoiceFlowAI has more complex models and its own storage system. Careful integration needed. |
| Naming conflicts | **Medium** | Well-documented above. Follow resolution strategy in Section 15. |
| Voice permissions (Microphone + Speech) | **Medium** | Apple may reject or ask questions. Prepare review notes explaining the voice-to-invoice feature. |
| Subscription migration (existing users) | **Low** | <50 total downloads across all apps. Essentially zero paid subscribers. |
| AI proxy bundle ID verification | **Low** | Merged app keeps `com.documentintelligence.docuscan` which is already authorized. |
| Core Data + UserDefaults coexistence | **Low** | They store different data types and do not interact. No migration needed. |
| InvoiceSettingsView size (~1600 lines) | **Medium** | Consider breaking it into smaller files during integration. |
| Facebook SDK in merged app | **Low** | Recommend removing it. If kept, ensure proper Info.plist configuration. |
| RevenueCat vs StoreKit 2 confusion | **Medium** | Stick with RevenueCat exclusively. Remove all StoreKitManager references from copied code. |

---

## 19. Quick Reference: Key File Paths

### Files You Will MODIFY

| File | What to Change |
|---|---|
| `Apps/DocuScanAI/DocuScanAI/App/ContentView.swift` | Add PDF Tools and Invoices tabs (5-tab layout) |
| `Apps/DocuScanAI/DocuScanAI/App/DocuScanAIApp.swift` | Possibly add Facebook SDK init, SearchAds attribution |
| `Apps/DocuScanAI/DocuScanAI/App/Models.swift` | Add `PDFDocumentItem` struct |
| `Apps/DocuScanAI/DocuScanAI/Subscription/ProFeature.swift` | Add PDF + Invoice pro feature cases |
| `Apps/DocuScanAI/DocuScanAI/Subscription/PaywallView.swift` | Update feature list to show all three verticals |
| `Apps/DocuScanAI/DocuScanAI/Views/SettingsView.swift` | Add invoice settings section, expand for all features |
| `Apps/DocuScanAI/DocuScanAI/Resources/Info.plist` | Add Microphone, Speech, PDF handler, File Sharing permissions |

### Files You Will CREATE

| New File | Source | Notes |
|---|---|---|
| `Apps/DocuScanAI/DocuScanAI/App/InvoiceModels.swift` | Copy from `InvoiceFlowAI/App/Models.swift` | Rename to avoid conflict |
| `Apps/DocuScanAI/DocuScanAI/Views/PDF/PDFEditorView.swift` | Copy from PDFGenius | Update references |
| `Apps/DocuScanAI/DocuScanAI/Views/PDF/PDFToolsView.swift` | Copy from PDFGenius | Update references |
| `Apps/DocuScanAI/DocuScanAI/Views/PDF/PDFAIAssistantView.swift` | Copy from PDFGenius | Update references |
| `Apps/DocuScanAI/DocuScanAI/Views/PDF/SignatureView.swift` | Copy from PDFGenius | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/PDFEditorViewModel.swift` | Copy from PDFGenius | Update references |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/PDFDocumentListViewModel.swift` | Copy from PDFGenius | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/InvoiceListView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/CreateInvoiceView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/InvoiceDetailView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/ClientsView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/ItemsView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/VoiceToInvoiceView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/ScanReceiptView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/DashboardView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/InvoiceSettingsView.swift` | Copy from InvoiceFlowAI | Remove paywall, refactor |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/InvoiceNavigationView.swift` | New | Wrapper for Invoices tab |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/EstimateListView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/CreateEstimateView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/EstimateDetailView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/ExportDataView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/LateFeeSettingsView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/InvoiceSignatureView.swift` | Copy from InvoiceFlowAI | Renamed from SignatureView |
| `Apps/DocuScanAI/DocuScanAI/Views/Invoice/CloudSyncSettingsView.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/InvoiceListViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/CreateInvoiceViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/ClientsViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/ScanReceiptViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/VoiceToInvoiceViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/EstimateListViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/ViewModels/CreateEstimateViewModel.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/CSVExporter.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/ClientPortalGenerator.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/CloudSyncManager.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/NetworkMonitor.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/PDFTemplateGenerator.swift` | Copy from InvoiceFlowAI | |
| `Apps/DocuScanAI/DocuScanAI/Services/SearchAdsAttribution.swift` | Copy from InvoiceFlowAI | Optional |
| `Apps/DocuScanAI/DocuScanAI/Services/FacebookSDKManager.swift` | Copy from InvoiceFlowAI | Optional, recommend removing |
| `Apps/DocuScanAI/DocuScanAI/Resources/DocuScanAI.entitlements` | New | iCloud entitlements |

### Files You Will NOT Touch

| Path | Why |
|---|---|
| `DocumentCore/` (entire package) | Shared SDK works as-is. No changes needed. |
| `Apps/PDFGenius/` (entire app) | Source for copying, but do not modify in place. |
| `Apps/InvoiceFlowAI/` (entire app) | Source for copying, but do not modify in place (until Phase 3 sunset). |

---

## End of Handoff Document

This document was generated by analyzing all 80+ Swift files across the monorepo. A Claude worker starting from this document should be able to begin Phase 1 implementation immediately without further codebase exploration.
