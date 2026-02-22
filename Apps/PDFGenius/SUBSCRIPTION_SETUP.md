# PDFGenius Subscription Setup Guide

## Overview

This guide covers setting up in-app purchases for PDFGenius using RevenueCat for subscription management and Apple Search Ads attribution tracking.

---

## Part 1: App Store Connect Setup

### Step 1: Create Your App (if not already done)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: PDF Genius
   - **Primary Language**: English (US)
   - **Bundle ID**: `com.documentintelligence.pdfgenius`
   - **SKU**: `pdfgenius001`

### Step 2: Create In-App Purchases

Go to **Your App** → **Monetization** → **In-App Purchases**

#### Create 3 Products:

**1. Monthly Subscription**
| Field | Value |
|-------|-------|
| Reference Name | PDFGenius Pro Monthly |
| Product ID | `pdfgenius_pro_monthly` |
| Type | Auto-Renewable Subscription |
| Price | $4.99 USD |
| Duration | 1 Month |
| Subscription Group | PDFGenius Pro |

**2. Annual Subscription**
| Field | Value |
|-------|-------|
| Reference Name | PDFGenius Pro Annual |
| Product ID | `pdfgenius_pro_annual` |
| Type | Auto-Renewable Subscription |
| Price | $39.99 USD |
| Duration | 1 Year |
| Subscription Group | PDFGenius Pro |

**3. Lifetime Purchase**
| Field | Value |
|-------|-------|
| Reference Name | PDFGenius Pro Lifetime |
| Product ID | `pdfgenius_pro_lifetime` |
| Type | Non-Consumable |
| Price | $79.99 USD |

### Step 3: Configure Subscription Group

1. Create a Subscription Group named **"PDFGenius Pro"**
2. Add both Monthly and Annual subscriptions to this group
3. Set the **Subscription Group Level**:
   - Level 1: Annual (higher tier)
   - Level 2: Monthly (lower tier)

### Step 4: Add Localization

For each product, add localized metadata:

**Display Name**: PDFGenius Pro
**Description**: Unlock all features including signatures, AI analysis, merge/split PDFs, and more.

### Step 5: App Store Connect API Key (for RevenueCat)

1. Go to **Users and Access** → **Integrations** → **App Store Connect API**
2. Click **Generate API Key**
3. Name: `RevenueCat Integration`
4. Access: **Admin** (recommended) or **App Manager**
5. Download the `.p8` file and note:
   - **Issuer ID**
   - **Key ID**
   - **Private Key** (the .p8 file contents)

---

## Part 2: RevenueCat Setup

### Step 1: Create RevenueCat Account

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Sign up / Log in
3. Create a new project: **PDFGenius**

### Step 2: Connect to App Store

1. In RevenueCat → **Project Settings** → **Apps** → **+ New App**
2. Select **Apple App Store**
3. Enter:
   - **App Name**: PDFGenius
   - **Bundle ID**: `com.documentintelligence.pdfgenius`
4. Add the **App Store Connect API credentials**:
   - Issuer ID
   - Key ID
   - Private Key (paste the .p8 contents)

### Step 3: Create Products in RevenueCat

Go to **Products** → **+ New Product**

Create these products (they mirror App Store Connect):

| Identifier | App Store Product ID |
|------------|---------------------|
| `pdfgenius_pro_monthly` | `pdfgenius_pro_monthly` |
| `pdfgenius_pro_annual` | `pdfgenius_pro_annual` |
| `pdfgenius_pro_lifetime` | `pdfgenius_pro_lifetime` |

### Step 4: Create Entitlements

Go to **Entitlements** → **+ New Entitlement**

| Entitlement ID | Display Name |
|----------------|--------------|
| `pro` | Pro Access |

Then attach ALL 3 products to the `pro` entitlement.

### Step 5: Create Offerings

Go to **Offerings** → **+ New Offering**

**Default Offering**:
| Field | Value |
|-------|-------|
| Identifier | `default` |
| Display Name | Default |
| Current | Yes (make this the current offering) |

Add 3 packages to this offering:
| Package | Product |
|---------|---------|
| `$rc_monthly` | pdfgenius_pro_monthly |
| `$rc_annual` | pdfgenius_pro_annual |
| `$rc_lifetime` | pdfgenius_pro_lifetime |

### Step 6: Get API Keys

Go to **Project Settings** → **API Keys**

Copy the **Public SDK Key** (starts with `appl_...`)

---

## Part 3: Xcode Setup

### Step 1: Add RevenueCat SDK

1. Open PDFGenius.xcodeproj in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter URL: `https://github.com/RevenueCat/purchases-ios.git`
4. Select version: **5.0.0** or later
5. Add **RevenueCat** to PDFGenius target

### Step 2: Update API Key

Open `PDFGenius/Subscription/SubscriptionManager.swift`

Replace the placeholder API key:
```swift
private static let apiKey = "appl_YOUR_ACTUAL_KEY_HERE"
```

### Step 3: Enable In-App Purchase Capability

1. Select PDFGenius target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **In-App Purchase**

---

## Part 4: Apple Search Ads Integration

### Step 1: Set Up Apple Search Ads Account

1. Go to [Apple Search Ads](https://searchads.apple.com)
2. Create an account or sign in
3. Add your app (once published)

### Step 2: RevenueCat Attribution (Already Configured)

The SubscriptionManager already enables automatic Apple Search Ads attribution:

```swift
Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
```

This automatically:
- Collects AdServices attribution tokens
- Sends them to RevenueCat
- Tracks which keywords/campaigns drove conversions

### Step 3: View Attribution Data

In RevenueCat Dashboard:
1. Go to **Charts** → **Attribution**
2. Filter by **Apple Search Ads**
3. See which campaigns/keywords drive the most revenue

---

## Part 5: Testing

### Test in Sandbox

1. Create a Sandbox Apple ID in App Store Connect:
   - **Users and Access** → **Sandbox** → **Testers**
   - Add a new tester email

2. On your test device:
   - Sign out of App Store
   - Sign in with Sandbox account when prompted during purchase

3. Sandbox subscriptions renew quickly:
   - 1 month = 5 minutes
   - 1 year = 1 hour

### RevenueCat Sandbox Testing

1. In RevenueCat Dashboard, go to **Customers**
2. Search for your Sandbox tester
3. Verify:
   - Purchases appear
   - Entitlements are granted
   - Subscription status is correct

---

## Part 6: Launch Checklist

### Before Submitting to App Store:

- [ ] All 3 products created in App Store Connect
- [ ] Products have screenshots and descriptions
- [ ] Subscription Terms of Use URL added
- [ ] Privacy Policy URL added
- [ ] Products linked in RevenueCat
- [ ] `pro` entitlement created and linked
- [ ] Default offering configured
- [ ] API key updated in code
- [ ] In-App Purchase capability enabled
- [ ] Tested purchases in Sandbox
- [ ] Terms of Service and Privacy Policy links work in paywall

### App Store Review Notes:

Add this to your review notes:
```
In-App Purchases Testing:
- Sandbox account: [your sandbox email]
- To test Pro features, subscribe to any plan
- Features gated behind Pro: Signatures, AI Analysis, Merge/Split, OCR, Password Protection
```

---

## Pricing Summary

| Plan | Price | RevenueCat Fee (1%) | Apple Fee (15-30%) | Your Revenue |
|------|-------|---------------------|-------------------|--------------|
| Monthly | $4.99 | $0.05 | $0.75-1.50 | $3.44-4.19 |
| Annual | $39.99 | $0.40 | $6.00-12.00 | $27.59-33.59 |
| Lifetime | $79.99 | $0.80 | $12.00-24.00 | $55.19-67.19 |

*Apple takes 30% for Year 1, then 15% for subscribers >1 year (Small Business Program: 15% if <$1M revenue)*

---

## Support Links

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Apple Search Ads](https://searchads.apple.com/help)
- [StoreKit Testing](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
