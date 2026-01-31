# Document Intelligence Platform

A suite of AI-powered document management iOS apps sharing a common SDK (DocumentCore).

## Apps

### 1. DocuScan AI - Smart Document Scanner
The scanner that understands your documents.

**Free Features:**
- Scan with auto edge detection
- Basic filters (B&W, color, contrast)
- Multi-page PDF generation
- Document storage & folders
- Export with watermark

**Pro Features ($4.99/month):**
- OCR text extraction
- AI summaries
- Auto-title documents
- Extract key fields
- Search inside documents
- Remove watermark
- Cloud sync

### 2. PDFGenius - AI-Powered PDF Editor
The simple PDF editor that actually helps you understand documents.

**Free Features:**
- View PDFs
- Basic annotations (highlight, underline)
- Fill simple forms

**Pro Features ($5.99/month):**
- Add signature
- Edit text in PDF
- Merge/split PDFs
- AI summaries
- Smart form fill
- Highlight key clauses
- Password protect

### 3. InvoiceFlow AI - Intelligent Invoice Maker
The fastest invoice app — just talk or scan.

**Free Features:**
- Create invoices manually
- Add clients & line items
- Generate PDF (watermarked)
- 3 invoices/month limit

**Pro Features ($6.99/month):**
- Unlimited invoices
- Scan receipt → auto expense
- Voice to invoice
- Client database
- Item templates
- Recurring invoices
- Tax calculation
- Logo upload
- Payment tracking
- Remove branding

## Architecture

```
DocumentIntelligence/
├── DocumentCore/                 # Shared Swift Package (SDK)
│   ├── Package.swift
│   └── Sources/
│       ├── Camera/              # Camera & edge detection
│       ├── PDFEngine/           # PDF generation, viewing, editing
│       ├── OCR/                 # Text extraction (Vision framework)
│       ├── Storage/             # Document storage & Core Data
│       ├── AI/                  # OpenAI integration
│       ├── Paywall/             # StoreKit 2 subscriptions
│       ├── Models/              # Shared data models
│       └── Invoice/             # Invoice-specific features
│
└── Apps/
    ├── DocuScanAI/              # Scanner App
    ├── InvoiceFlowAI/           # Invoice App
    └── PDFGenius/               # PDF Editor App
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Camera/Scanning | VisionKit, AVFoundation |
| OCR | Vision Framework |
| PDF | PDFKit, Core Graphics |
| Storage | Core Data + iCloud |
| AI | OpenAI API (GPT-4) |
| Payments | StoreKit 2 |
| Speech | Speech Framework |
| Architecture | MVVM |
| Min iOS | iOS 16.0 |

## DocumentCore SDK Modules

### Camera Module
- **EdgeDetector**: Vision-based document edge detection
- **ImageProcessor**: Image filters and enhancement
- **DocumentScanner**: VNDocumentCameraViewController wrapper

### PDFEngine Module
- **PDFGenerator**: Create PDFs from images
- **PDFViewer**: PDFKit wrapper for viewing
- **PDFEditor**: Annotations and signatures
- **PDFMerger**: Merge and split operations
- **WatermarkService**: Add/remove watermarks

### OCR Module
- **TextRecognizer**: Vision framework OCR
- **TextBlock**: Recognized text with bounding boxes
- Field extraction (dates, amounts, emails, phone numbers)

### Storage Module
- **DocumentStore**: Core Data stack
- **Document**: Document entity with metadata
- **Folder**: Folder organization
- **CloudSync**: iCloud synchronization

### AI Module
- **AIService**: OpenAI API client
- **DocumentAnalyzer**: Summarize and categorize documents
- **AutoTitler**: Generate smart titles
- **FieldExtractor**: Extract structured data
- **ContractAnalyzer**: Analyze contracts for key clauses

### Paywall Module
- **StoreKitManager**: StoreKit 2 wrapper
- **PaywallView**: Subscription UI
- **FeatureGate**: Feature access control

## AI Capabilities

The AI module provides intelligent document understanding:

- **Auto-Title**: "Invoice - Acme Corp - Jan 2026"
- **Summarization**: Generate concise summaries
- **Field Extraction**: Extract dates, amounts, vendor names
- **Categorization**: Auto-categorize documents
- **Question Answering**: Ask questions about documents
- **Contract Analysis**: Extract key clauses and obligations
- **Receipt Parsing**: Auto-create expenses from receipts
- **Voice-to-Invoice**: Create invoices by speaking

## Development Setup

1. Clone the repository
2. Open `DocumentIntelligence.xcworkspace`
3. Configure OpenAI API key in each app's settings
4. Configure StoreKit products in App Store Connect
5. Build and run individual apps

## Requirements

- macOS 13.0+ (for Xcode)
- Xcode 15.0+
- iOS 16.0+ (target)
- Swift 5.9+
- OpenAI API key

## Configuration

### OpenAI API Key
Add your OpenAI API key in the app's settings or configuration file:

```swift
AIService.shared.configure(apiKey: "your-api-key")
```

### StoreKit Products
Configure these product IDs in App Store Connect:
- `com.documentintelligence.docuscan.pro.monthly`
- `com.documentintelligence.pdfgenius.pro.monthly`
- `com.documentintelligence.invoiceflow.pro.monthly`

## Building for Production

1. Update bundle identifiers
2. Configure signing certificates
3. Add OpenAI API key (secure storage)
4. Configure StoreKit products
5. Test subscription flows in sandbox
6. Submit to App Store

## Project Status

### Phase 1: Foundation ✓
- [x] Project structure
- [x] DocumentCore Swift Package
- [x] Camera module
- [x] PDF Engine module
- [x] OCR module
- [x] Storage module
- [x] AI module
- [x] Paywall module

### Phase 2: DocuScan AI (Next)
- [ ] App scaffolding
- [ ] Scanner UI
- [ ] Document management
- [ ] AI insights view
- [ ] Paywall integration

### Phase 3: PDFGenius
- [ ] PDF viewer
- [ ] Annotation tools
- [ ] Signature capture
- [ ] AI assistant

### Phase 4: InvoiceFlow AI
- [ ] Invoice builder
- [ ] Client management
- [ ] Voice input
- [ ] Receipt scanning

## License

Proprietary - All Rights Reserved

## Contact

For questions or support, please contact: [Your Contact Info]

---

**Built with Claude Code** 🤖
