import Foundation
import Graphiti

struct ProductAPI: API {
    let resolver: ProductResolver
    let schema: Schema<ProductResolver, ProductContext>
}
