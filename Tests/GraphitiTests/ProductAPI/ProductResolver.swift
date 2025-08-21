import Foundation
import Graphiti
import GraphQL

struct ProductResolver {
    var sdl: String

    func getProduct1(context: ProductContext, arguments: Product.EntityKey1) -> Product? {
        type(of: context).products.first { $0.id == arguments.id }
    }

    func getProduct2(context: ProductContext, arguments: Product.EntityKey2) -> Product? {
        type(of: context).products
            .first { $0.sku == arguments.sku && $0.package == arguments.package }
    }

    func getProduct3(context: ProductContext, arguments: Product.EntityKey3) -> Product? {
        type(of: context).products
            .first { $0.sku == arguments.sku && $0.variation?.id == arguments.variation.id }
    }

    func getDeprecatedProduct(
        context: ProductContext,
        arguments: DeprecatedProduct.EntityKey
    ) -> DeprecatedProduct? {
        type(of: context).deprecatedProducts
            .first { $0.sku == arguments.sku && $0.package == arguments.package }
    }

    func getProductResearch(
        context: ProductContext,
        arguments: ProductResearch.EntityKey
    ) -> ProductResearch? {
        type(of: context).productsResearch
            .first { $0.study.caseNumber == arguments.study.caseNumber }
    }

    func getUser(context: ProductContext, arguments: ProductUser.EntityKey) -> ProductUser? {
        type(of: context).users.first { $0.email == arguments.email }
    }
}
