import Foundation
import Graphiti

struct Product: Codable {
    let id: String
    let sku: String?
    let package: String?
    let variation: ProductVariation?
    let dimensions: ProductDimension?
    let createdBy: ProductUser?
    let notes: String?
    let research: [ProductResearch]

    struct EntityKey1: Codable {
        let id: String
    }

    struct EntityKey2: Codable {
        let sku: String
        let package: String
    }

    struct EntityKey3: Codable {
        let sku: String
        let variation: VariationKey

        struct VariationKey: Codable {
            let id: String
        }
    }
}

struct DeprecatedProduct: Codable {
    let sku: String
    let package: String
    let reason: String?
    let createdBy: ProductUser?

    struct EntityKey: Codable {
        let sku: String
        let package: String
    }
}

struct ProductVariation: Codable {
    let id: String
}

struct ProductResearch: Codable {
    let study: CaseStudy
    let outcome: String?

    struct EntityKey: Codable {
        let study: CaseStudyKey

        struct CaseStudyKey: Codable {
            let caseNumber: String
        }
    }
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

    static let typename: String = "User"

    struct EntityKey: Codable {
        let email: String
    }
}
