import Foundation
@testable import Graphiti
import GraphQL
import Testing

struct ScalarTests {
    // MARK: Test UUID converts to String as expected

    @Test func uuidOutput() async throws {
        struct UUIDOutput {
            let value: UUID
        }

        struct TestResolver {
            func uuid(context _: NoContext, arguments _: NoArguments) -> UUIDOutput {
                return UUIDOutput(value: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(UUID.self, as: "UUID")
            Type(UUIDOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("uuid", at: TestResolver.uuid)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                uuid {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "uuid": [
                        "value": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                    ],
                ])
        )
    }

    @Test func uuidArg() async throws {
        struct UUIDOutput {
            let value: UUID
        }

        struct Arguments: Codable {
            let value: UUID
        }

        struct TestResolver {
            func uuid(context _: NoContext, arguments: Arguments) -> UUIDOutput {
                return UUIDOutput(value: arguments.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(UUID.self, as: "UUID")
            Type(UUIDOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("uuid", at: TestResolver.uuid) {
                    Argument("value", at: \.value)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                uuid (value: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "uuid": [
                        "value": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                    ],
                ])
        )
    }

    @Test func uuidInput() async throws {
        struct UUIDOutput {
            let value: UUID
        }

        struct UUIDInput: Codable {
            let value: UUID
        }

        struct Arguments: Codable {
            let input: UUIDInput
        }

        struct TestResolver {
            func uuid(context _: NoContext, arguments: Arguments) -> UUIDOutput {
                return UUIDOutput(value: arguments.input.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(UUID.self, as: "UUID")
            Type(UUIDOutput.self) {
                Field("value", at: \.value)
            }
            Input(UUIDInput.self) {
                InputField("value", at: \.value)
            }
            Query {
                Field("uuid", at: TestResolver.uuid) {
                    Argument("input", at: \.input)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                uuid (input: {value: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"}) {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "uuid": [
                        "value": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                    ],
                ])
        )
    }

    // MARK: Test Date scalars convert to String using ISO8601 encoders

    @Test func dateOutput() async throws {
        struct DateOutput {
            let value: Date
        }

        struct TestResolver {
            func date(context _: NoContext, arguments _: NoArguments) -> DateOutput {
                return DateOutput(value: Date(timeIntervalSinceReferenceDate: 0))
            }
        }

        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            Scalar(Date.self, as: "Date")
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                date {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "date": [
                        "value": "2001-01-01T00:00:00Z",
                    ],
                ])
        )
    }

    @Test func dateArg() async throws {
        struct DateOutput {
            let value: Date
        }

        struct Arguments: Codable {
            let value: Date
        }

        struct TestResolver {
            func date(context _: NoContext, arguments: Arguments) -> DateOutput {
                return DateOutput(value: arguments.value)
            }
        }

        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            Scalar(Date.self, as: "Date")
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date) {
                    Argument("value", at: \.value)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                date (value: "2001-01-01T00:00:00Z") {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "date": [
                        "value": "2001-01-01T00:00:00Z",
                    ],
                ])
        )
    }

    @Test func dateInput() async throws {
        struct DateOutput {
            let value: Date
        }

        struct DateInput: Codable {
            let value: Date
        }

        struct Arguments: Codable {
            let input: DateInput
        }

        struct TestResolver {
            func date(context _: NoContext, arguments: Arguments) -> DateOutput {
                return DateOutput(value: arguments.input.value)
            }
        }

        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            Scalar(Date.self, as: "Date")
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Input(DateInput.self) {
                InputField("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date) {
                    Argument("input", at: \.input)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                date (input: {value: "2001-01-01T00:00:00Z"}) {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "date": [
                        "value": "2001-01-01T00:00:00Z",
                    ],
                ])
        )
    }

    // MARK: Test a scalar that converts to a single-value Map (StringCodedCoordinate -> String)

    @Test func stringCoordOutput() async throws {
        struct CoordinateOutput {
            let value: StringCodedCoordinate
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments _: NoArguments) -> CoordinateOutput {
                return CoordinateOutput(value: StringCodedCoordinate(latitude: 0.0, longitude: 0.0))
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(StringCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                coord {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "coord": [
                        "value": "(0.0, 0.0)",
                    ],
                ])
        )
    }

    @Test func stringCoordArg() async throws {
        struct CoordinateOutput {
            let value: StringCodedCoordinate
        }

        struct Arguments: Codable {
            let value: StringCodedCoordinate
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments: Arguments) -> CoordinateOutput {
                return CoordinateOutput(value: arguments.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(StringCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord) {
                    Argument("value", at: \.value)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                coord (value: "(0.0, 0.0)") {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "coord": [
                        "value": "(0.0, 0.0)",
                    ],
                ])
        )
    }

    @Test func stringCoordInput() async throws {
        struct CoordinateOutput {
            let value: StringCodedCoordinate
        }

        struct CoordinateInput: Codable {
            let value: StringCodedCoordinate
        }

        struct Arguments: Codable {
            let input: CoordinateInput
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments: Arguments) -> CoordinateOutput {
                return CoordinateOutput(value: arguments.input.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(StringCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Input(CoordinateInput.self) {
                InputField("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord) {
                    Argument("input", at: \.input)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                coord (input: {value: "(0.0, 0.0)"}) {
                value
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "coord": [
                        "value": "(0.0, 0.0)",
                    ],
                ])
        )
    }

    // MARK: Test a scalar that converts to a multi-value Map (Coordinate -> Dict)

    @Test func dictCoordOutput() async throws {
        struct CoordinateOutput {
            let value: DictCodedCoordinate
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments _: NoArguments) -> CoordinateOutput {
                return CoordinateOutput(value: DictCodedCoordinate(latitude: 0, longitude: 0))
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(DictCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        // Test individual fields because we can't be confident we'll match the ordering of Map's OrderedDictionary
        let result = try await api.execute(
            request: """
            query {
              coord {
                value
              }
            }
            """,
            context: NoContext()
        )

        let value = result.data?.dictionary?["coord"]?.dictionary?["value"]?.dictionary

        #expect(
            value?["longitude"] ==
                .number(0.0)
        )
        #expect(
            value?["latitude"] ==
                .number(0.0)
        )
    }

    @Test func dictCoordArg() async throws {
        struct CoordinateOutput {
            let value: DictCodedCoordinate
        }

        struct Arguments: Codable {
            let value: DictCodedCoordinate
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments: Arguments) -> CoordinateOutput {
                return CoordinateOutput(value: arguments.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(DictCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord) {
                    Argument("value", at: \.value)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        // Test individual fields because we can't be confident we'll match the ordering of Map's OrderedDictionary
        let result = try await api.execute(
            request: """
            query {
              coord (value: {latitude: 0.0, longitude: 0.0}) {
                value
              }
            }
            """,
            context: NoContext()
        )

        let value = result.data?.dictionary?["coord"]?.dictionary?["value"]?.dictionary

        #expect(
            value?["longitude"] ==
                .number(0.0)
        )
        #expect(
            value?["latitude"] ==
                .number(0.0)
        )
    }

    @Test func dictCoordInput() async throws {
        struct CoordinateOutput {
            let value: DictCodedCoordinate
        }

        struct CoordinateInput: Codable {
            let value: DictCodedCoordinate
        }

        struct Arguments: Codable {
            let input: CoordinateInput
        }

        struct TestResolver {
            func coord(context _: NoContext, arguments: Arguments) -> CoordinateOutput {
                return CoordinateOutput(value: arguments.input.value)
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Scalar(DictCodedCoordinate.self, as: "Coordinate")
            Type(CoordinateOutput.self) {
                Field("value", at: \.value)
            }
            Input(CoordinateInput.self) {
                InputField("value", at: \.value)
            }
            Query {
                Field("coord", at: TestResolver.coord) {
                    Argument("input", at: \.input)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        // Test individual fields because we can't be confident we'll match the ordering of Map's OrderedDictionary
        let result = try await api.execute(
            request: """
            query {
              coord (input: {value: {latitude: 0.0, longitude: 0.0}}) {
                value
              }
            }
            """,
            context: NoContext()
        )

        let value = result.data?.dictionary?["coord"]?.dictionary?["value"]?.dictionary

        #expect(
            value?["longitude"] ==
                .number(0.0)
        )
        #expect(
            value?["latitude"] ==
                .number(0.0)
        )
    }
}

private class TestAPI<Resolver: Sendable, ContextType: Sendable>: API {
    let resolver: Resolver
    let schema: Schema<Resolver, ContextType>

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}

struct StringCodedCoordinate: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ string: String) throws {
        let range = NSRange(location: 0, length: string.utf8.count)
        let regex = try NSRegularExpression(pattern: "\\((.*), (.*)\\)")
        guard let match = regex.firstMatch(in: string, options: .init(), range: range) else {
            throw GraphQLError(message: "Coordinate string didn't match expected value")
        }

        guard
            let latitudeRange = Range(match.range(at: 1), in: string),
            let longitudeRange = Range(match.range(at: 2), in: string)
        else {
            throw GraphQLError(message: "Coordinate regex failure")
        }

        let latitudeString = String(string[latitudeRange])
        let longitudeString = String(string[longitudeRange])

        guard
            let latitude = Double(latitudeString),
            let longitude = Double(longitudeString)
        else {
            throw GraphQLError(message: "Couldn't parse string values to doubles")
        }

        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        try self.init(string)
    }

    func toString() -> String {
        return "(\(latitude), \(longitude))"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toString())
    }
}

struct DictCodedCoordinate: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
