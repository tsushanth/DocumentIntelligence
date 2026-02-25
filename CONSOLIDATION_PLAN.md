# DocuScanAI Consolidation Plan

## Objective
Merge three published iOS apps into one unified app under the **DocuScanAI** brand:
- **DocuScanAI** (document scanning + OCR) — 206 impressions, 10 downloads
- **InvoiceFlow Pro** (invoice creation) — 333 impressions, 10 downloads
- **All-in-One PDF** (PDF editing) — 4.86K impressions, 50 downloads

All three currently live in the `InvoiceFlow/` monorepo with a shared SDK.

## Current Architecture

```
InvoiceFlow/
├── DocumentCore/          # Shared SDK (Swift Package)
│   ├── Camera/            # Edge detection, document scanning (VisionKit)
│   ├── PDFEngine/         # PDF generation, viewing, editing, merging, watermarking
│   ├── OCR/               # Text recognition (Vision framework), field extraction
│   ├── Storage/           # Core Data + iCloud sync
│   ├── AI/                # OpenAI integration (summaries, auto-title, field extraction)
│   ├── Paywall/           # StoreKit 2 subscription management
│   ├── Invoice/           # Invoice-specific features
│   └── Models/            # Shared data structures
├── Apps/
│   ├── DocuScanAI/        # Bundle: com.documentintelligence.docuscan (v1.0.0 build 2)
│   ├── InvoiceFlowAI/     # Bundle: com.documentintelligence.invoiceflow (v1.0.0 build 2)
│   └── PDFGenius/         # Bundle: com.documentintelligence.pdfgenius (v1.0.0 build 1)
```

## Target State

Single app: **DocuScanAI** (`com.documentintelligence.docuscan`)

### Feature Set (merged from all three apps):

**From DocuScanAI (keep as base):**
- Document scanning with auto edge detection
- Basic filters (B&W, color, contrast)
- Multi-page PDF generation
- Document storage & folders
- Export with watermark (free)
- Pro: OCR text extraction, AI summaries, auto-title, field extraction, search, cloud sync

**From All-in-One PDF / PDFGenius (absorb):**
- PDF viewing
- Annotations (highlight, underline)
- Form filling
- Pro: Signatures, text editing, merge/split PDFs, AI summaries, smart form fill, password protection

**From InvoiceFlow Pro (absorb):**
- Invoice creation with clients & line items
- PDF generation (watermarked free, 3/month limit)
- Pro: Unlimited invoices, receipt scanning → auto expense, voice-to-invoice, client database, item templates, recurring invoices, tax calc, logo upload, payment tracking

### Proposed Tab Structure:
1. **Scan** — Document scanning (camera)
2. **Documents** — All scanned docs, folders, search
3. **PDF Tools** — Open/edit/merge/split PDFs, signatures
4. **Invoices** — Create/manage invoices, client database
5. **Settings** — Subscription, cloud sync, preferences

### Subscription:
- Combine into single Pro tier
- Keep existing DocuScanAI bundle ID and subscription group
- Migrate InvoiceFlow and PDFGenius subscribers (if any) via receipt validation

## Implementation Steps

### Phase 1: Merge PDF features into DocuScanAI
1. Add PDFGenius views/viewmodels to DocuScanAI target
2. Add "PDF Tools" tab to DocuScanAI navigation
3. Wire up PDF editing, merge/split, signatures, annotations
4. Gate Pro features behind existing paywall
5. Test all PDF operations
6. Update App Store description

### Phase 2: Merge Invoice features into DocuScanAI
1. Add InvoiceFlowAI views/viewmodels to DocuScanAI target
2. Add "Invoices" tab to navigation
3. Wire up invoice creation, client database, templates
4. Add receipt scanning → auto expense flow
5. Add voice-to-invoice (requires Speech framework permission)
6. Gate Pro features behind paywall
7. Test full invoice workflow
8. Update App Store description

### Phase 3: Sunset old apps
1. Push update to InvoiceFlow Pro pointing users to DocuScanAI
2. Push update to All-in-One PDF pointing users to DocuScanAI
3. Keep old listings live for 3-6 months for existing users
4. Eventually remove from sale

## Key Technical Notes

- **Shared SDK already exists** — `DocumentCore` package has all the plumbing. The merge is mostly about wiring up the UI in one app target.
- **All three apps use the same Core Data store** — migration should be straightforward since they share the Storage module.
- **AI module uses OpenAI GPT-4** — API key management needs attention (check if hardcoded like CodeReader Pro).
- **Permissions needed for merged app:** Camera, Photo Library, Microphone (voice-to-invoice), Speech Recognition (voice-to-invoice), iCloud.
- **Current DocuScanAI bundle ID** (`com.documentintelligence.docuscan`) is already live — no App Store submission complications.

## Risk Assessment

- **Low risk:** PDF merge — PDFGenius and DocuScanAI already share DocumentCore, so views should just work
- **Medium risk:** Invoice merge — InvoiceFlow has its own invoice-specific module and templates that need careful integration
- **Medium risk:** Voice-to-invoice adds microphone + speech permissions — Apple may ask about usage
- **Low risk:** Existing user impact — all three apps have <50 downloads total, minimal migration concern

## Files to Reference

- Shared SDK: `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/DocumentCore/`
- DocuScanAI app: `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/DocuScanAI/`
- PDFGenius app: `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/PDFGenius/`
- InvoiceFlow app: `/Users/sushanthtiruvaipati/Documents/GitHub/InvoiceFlow/Apps/InvoiceFlowAI/`

## Archived Repos (for reference)

Cherry-pickable features from archived prototypes in `/Users/sushanthtiruvaipati/Documents/GitHub/_archived/`:
- `CodeReaderPro-swiftscan/` — Has polished document scanning UI, e-signatures, multi-cloud export (iCloud, Dropbox, Google Drive, OneDrive)
- `DocuScanAI-standalone/` — Has NFC scanning (not needed for this channel, goes to CodeReader Pro)
