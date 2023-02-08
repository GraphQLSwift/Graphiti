import Foundation

struct ProductResolver {
    struct ProductArguments: Codable {
        let id: String
    }

    func product(context: ProductContext, arguments: ProductArguments) -> Product? {
        context.getProduct(id: arguments.id)
    }

    struct DeprecatedProductArguments: Codable {
        let sku: String
        let package: String
    }

    func deprecatedProduct(context: ProductContext, arguments: DeprecatedProductArguments) -> DeprecatedProduct? {
        context.getDeprecatedProduct(sku: arguments.sku, package: arguments.package)
    }
}
