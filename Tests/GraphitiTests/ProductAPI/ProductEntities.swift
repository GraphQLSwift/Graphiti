import Foundation

struct Product: Codable {
    let id: String
    let sku: String?
    let package: String?
    let variation: ProductVariation?
    let dimensions: ProductDimension?
    let createdBy: ProductUser?
    let notes: String?
    let research: [ProductResearch]
}

struct DeprecatedProduct: Codable {
    let sku: String
    let package: String
    let reason: String?
    let createdBy: ProductUser?
}

struct ProductVariation: Codable {
    let id: String
}

struct ProductResearch: Codable {
    let study: CaseStudy
    let outcome: String?
}

struct CaseStudy: Codable {
    let caseNumber: String
    let description: String?
}

struct ProductDimension: Codable {
    let size: String?
    let weight: Float?
    let unit: String?
}

struct ProductUser: Codable {
    let email: String
    let name: String?
    let totalProductsCreated: Int?
    let yearsOfEmployment: Int

    var averageProductsCreatedPerYear: Int? {
        guard let totalProductsCreated = totalProductsCreated else { return nil }
        return totalProductsCreated / yearsOfEmployment
    }
}
