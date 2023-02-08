import Foundation
import Graphiti
import NIO

struct ProductResolver {
    var sdl: String

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

extension ProductResolver: FederationResolver {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
    static let entityKeys: [(entity: FederationEntity.Type, keys: [FederationEntityKey.Type])] = [
        (Product.self, [Product.EntityKey1.self, Product.EntityKey2.self, Product.EntityKey3.self]),
        (DeprecatedProduct.self, [DeprecatedProduct.EntityKey.self]),
        (ProductResearch.self, [ProductResearch.EntityKey.self]),
        (ProductUser.self, [ProductUser.EntityKey.self]),
    ]

    func entity(context: ProductContext, key: FederationEntityKey, group: EventLoopGroup) -> EventLoopFuture<FederationEntity?> {
        var entity: FederationEntity? = nil

        switch key {
        case let key as Product.EntityKey1:
            entity = context.getProduct(id: key.id)
        case let key as Product.EntityKey2:
            entity = context.getProduct(sku: key.sku, package: key.package)
        case let key as Product.EntityKey3:
            entity = context.getProduct(sku: key.sku, variationID: key.variation.id)
        case let key as DeprecatedProduct.EntityKey:
            entity = context.getDeprecatedProduct(sku: key.sku, package: key.package)
        case let key as ProductResearch.EntityKey:
            entity = context.getProductResearch(studyCaseNumber: key.study.caseNumber)
        case let key as ProductUser.EntityKey:
            entity = context.getUser(email: key.email)
        default:
            break
        }

        return group.next().makeSucceededFuture(entity)
    }
}
