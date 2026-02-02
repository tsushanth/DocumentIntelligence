import SwiftUI

// MARK: - Invoice

struct Invoice: Identifiable {
    let id = UUID()
    var invoiceNumber: String = ""
    var clientName: String
    var clientEmail: String?
    var clientAddress: String?
    var date: Date = Date()
    var dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    var lineItems: [LineItem]
    var taxRate: Double
    var notes: String?
    var status: Status = .draft
    
    enum Status: String {
        case draft
        case sent
        case paid
        case overdue
        
        var color: Color {
            switch self {
            case .draft: return .gray
            case .sent: return .blue
            case .paid: return .green
            case .overdue: return .red
            }
        }
    }
    
    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }
    
    var tax: Double {
        subtotal * (taxRate / 100)
    }
    
    var total: Double {
        subtotal + tax
    }
    
    var formattedSubtotal: String { formatCurrency(subtotal) }
    var formattedTax: String { formatCurrency(tax) }
    var formattedTotal: String { formatCurrency(total) }
    var formattedDate: String { date.formatted(date: .abbreviated, time: .omitted) }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Line Item

struct LineItem: Identifiable {
    let id = UUID()
    var description: String
    var quantity: Double
    var unitPrice: Double
    
    var amount: Double {
        quantity * unitPrice
    }
    
    var formattedUnitPrice: String { formatCurrency(unitPrice) }
    var formattedAmount: String { formatCurrency(amount) }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Client

struct Client: Identifiable {
    let id = UUID()
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Item Template

struct ItemTemplate: Identifiable {
    let id = UUID()
    var name: String
    var itemDescription: String?
    var price: Double
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}
