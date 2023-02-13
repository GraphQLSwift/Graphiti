import Foundation
import Graphiti

// Implementing Product Schema from https://github.com/apollographql/apollo-federation-subgraph-compatibility/blob/main/COMPATIBILITY.md

final class ProductSchema: PartialSchema<ProductResolver, ProductContext> {
    @TypeDefinitions
    override var types: Types {
        Scalar(Float.self)
        
        Type(
            Product.self,
            keys: {
                Key(at: ProductResolver.getProduct1) {
                    Argument("id", at: \.id)
                }
                Key(at: ProductResolver.getProduct2) {
                    Argument("sku", at: \.sku)
                    Argument("package", at: \.package)
                }
                Key(at: ProductResolver.getProduct3) {
                    Argument("sku", at: \.sku)
                    Argument("variation", at: \.variation)
                }
            }
        ) {
            Field("id", at: \.id)
            Field("sku", at: \.sku)
            Field("package", at: \.package)
            Field("variation", at: \.variation)
            Field("dimensions", at: \.dimensions)
            Field("createdBy", at: \.createdBy)
            Field("notes", at: \.notes)
            Field("research", at: \.research)
        }
        
        Type(DeprecatedProduct.self,
            keys: {
                Key(at: ProductResolver.getDeprecatedProduct) {
                    Argument("sku", at: \.sku)
                    Argument("package", at: \.package)
                }
            }
        ) {
            Field("sku", at: \.sku)
            Field("package", at: \.package)
            Field("reason", at: \.reason)
            Field("createdBy", at: \.createdBy)
        }
        
        Type(ProductVariation.self) {
            Field("id", at: \.id)
        }
        
        Type(
            ProductResearch.self,
            keys: {
                Key(at: ProductResolver.getProductResearch) {
                    Argument("study", at: \.study)
                }
            }
        ) {
            Field("study", at: \.study)
            Field("outcome", at: \.outcome)
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
        
        Type(
            ProductUser.self,
            as: "User",
            keys: {
                Key(at: ProductResolver.getUser) {
                    Argument("email", at: \.email)
                }
            }
        ) {
            Field("email", at: \.email)
            Field("name", at: \.name)
            Field("totalProductsCreated", at: \.totalProductsCreated)
            Field("yearsOfEmployment", at: \.yearsOfEmployment)
            Field("averageProductsCreatedPerYear", at: \.averageProductsCreatedPerYear)
        }
    }
}
