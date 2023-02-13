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
        }.key(at: ProductResolver.getProduct1) {
            Argument("id", at: \.id)
        }.key(at: ProductResolver.getProduct2) {
            Argument("sku", at: \.sku)
            Argument("package", at: \.package)
        }.key(at: ProductResolver.getProduct3) {
            Argument("sku", at: \.sku)
            Argument("variation", at: \.variation)
        }
        
        Type(DeprecatedProduct.self) {
            Field("sku", at: \.sku)
            Field("package", at: \.package)
            Field("reason", at: \.reason)
            Field("createdBy", at: \.createdBy)
        }.key(at: ProductResolver.getDeprecatedProduct) {
            Argument("sku", at: \.sku)
            Argument("package", at: \.package)
        }
        
        Type(ProductVariation.self) {
            Field("id", at: \.id)
        }
        
        Type(ProductResearch.self) {
            Field("study", at: \.study)
            Field("outcome", at: \.outcome)
        }.key(at: ProductResolver.getProductResearch) {
            Argument("study", at: \.study)
        }
        
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
        }.key(at: ProductResolver.getUser) {
            Argument("email", at: \.email)
        }
    }
}
