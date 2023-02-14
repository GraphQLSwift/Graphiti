import Foundation

struct ProductContext {
    static let dimensions = [
        ProductDimension(
            size: "small",
            weight: 1,
            unit: "kg"
        )
    ]

    static let users = [
        ProductUser(
            email: "support@apollographql.com",
            name: "Jane Smith",
            totalProductsCreated: 1337,
            yearsOfEmployment: 10
        ),
    ]

    static let deprecatedProducts = [
        DeprecatedProduct(
            sku: "apollo-federation-v1",
            package: "@apollo/federation-v1",
            reason: "Migrate to Federation V2",
            createdBy: users[0]
        ),
    ]

    static let productsResearch = [
        ProductResearch(
            study: CaseStudy(
                caseNumber: "1234",
                description: "Federation Study"
            ),
            outcome: nil
        ),
        ProductResearch(
            study: CaseStudy(
                caseNumber: "1235",
                description: "Studio Study"
            ),
            outcome: nil),
    ]

    static let products = [
        Product(
            id: "apollo-federation",
            sku: "federation",
            package: "@apollo/federation",
            variation: ProductVariation(
                id: "OSS"
            ),
            dimensions: dimensions[0],
            createdBy: users[0],
            notes: nil,
            research: [productsResearch[0]]
        ),
        Product(
            id: "apollo-studio",
            sku: "studio",
            package: "",
            variation: ProductVariation(
                id: "platform"
            ),
            dimensions: dimensions[0],
            createdBy: users[0],
            notes: nil,
            research: [productsResearch[1]]
        ),
    ]
}
