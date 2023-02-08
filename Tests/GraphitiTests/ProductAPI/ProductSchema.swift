import Foundation
import Graphiti

// Implementing Product Schema from https://github.com/apollographql/apollo-federation-subgraph-compatibility/blob/main/COMPATIBILITY.md

final class ProductSchema: PartialSchema<ProductResolver, ProductContext> {
    @TypeDefinitions
    override var types: Types {
        Scalar(Float.self)

        Type(Product.self) {
            Field("id", at: \.id)
            Field("sku", at: \.sku)
            Field("package", at: \.package)
            Field("variation", at: \.variation)
            Field("dimensions", at: \.dimensions)
            Field("createdBy", at: \.createdBy)
            Field("notes", at: \.notes)
            Field("research", at: \.research)
        }
        .key(Product.EntityKey1.self)
        .key(Product.EntityKey2.self)
        .key(Product.EntityKey3.self)

        Type(DeprecatedProduct.self) {
            Field("sku", at: \.sku)
            Field("package", at: \.package)
            Field("reason", at: \.reason)
            Field("createdBy", at: \.createdBy)
        }
        .key(DeprecatedProduct.EntityKey.self)

        Type(ProductVariation.self) {
            Field("id", at: \.id)
        }
        
        Type(ProductResearch.self) {
            Field("study", at: \.study)
            Field("outcome", at: \.outcome)
        }
        .key(ProductResearch.EntityKey.self)

        Type(CaseStudy.self) {
            Field("caseNumber", at: \.caseNumber)
            Field("description", at: \.description)
        }

        Type(ProductDimension.self) {
            Field("size", at: \.size)
            Field("weight", at: \.weight)
            Field("unit", at: \.unit)
        }

        Type(ProductUser.self, as: "User") {
            Field("email", at: \.email)
            Field("name", at: \.name)
            Field("totalProductsCreated", at: \.totalProductsCreated)
            Field("yearsOfEmployment", at: \.yearsOfEmployment)
            Field("averageProductsCreatedPerYear", at: \.averageProductsCreatedPerYear)
        }
        .key(ProductUser.EntityKey.self)
    }

    @FieldDefinitions
    override var query: Fields {
        Field("product", at: ProductResolver.product) {
            Argument("id", at: \.id)
        }

        Field("deprecatedProduct", at: ProductResolver.deprecatedProduct) {
            Argument("sku", at: \.sku)
            Argument("package", at: \.package)
        }
        .deprecationReason("Use product query instead")
    }
}
