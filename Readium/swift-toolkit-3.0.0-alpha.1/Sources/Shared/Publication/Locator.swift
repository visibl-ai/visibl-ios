//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import ReadiumInternal

/// https://github.com/readium/architecture/tree/master/locators
public struct Locator: Hashable, CustomStringConvertible, Loggable {
    /// The URI of the resource that the Locator Object points to.
    public var href: String // URI

    /// The media type of the resource that the Locator Object points to.
    public var type: String

    /// The title of the chapter or section which is more relevant in the context of this locator.
    public var title: String?

    /// One or more alternative expressions of the location.
    public var locations: Locations

    /// Textual context of the locator.
    public var text: Text

    public init(href: String, type: String, title: String? = nil, locations: Locations = .init(), text: Text = .init()) {
        self.href = href
        self.type = type
        self.title = title
        self.locations = locations
        self.text = text
    }

    public init?(json: Any?, warnings: WarningLogger? = nil) throws {
        if json == nil {
            return nil
        }
        guard let jsonObject = json as? [String: Any],
              let href = jsonObject["href"] as? String,
              let type = jsonObject["type"] as? String
        else {
            warnings?.log("`href` and `type` required", model: Self.self, source: json)
            throw JSONError.parsing(Self.self)
        }

        try self.init(
            href: href,
            type: type,
            title: jsonObject["title"] as? String,
            locations: Locations(json: jsonObject["locations"], warnings: warnings),
            text: Text(json: jsonObject["text"], warnings: warnings)
        )
    }

    public init?(jsonString: String, warnings: WarningLogger? = nil) throws {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
        } catch {
            warnings?.log("Invalid Locator object: \(error)", model: Self.self)
            throw JSONError.parsing(Self.self)
        }

        try self.init(json: json, warnings: warnings)
    }

    /// Creates a ``Locator`` from its legacy JSON representation.
    ///
    /// Only use this API when you are upgrading to Readium 3.x and migrating
    /// the ``Locator`` objects stored in your database. See the migration guide
    /// for more information.
    public init?(legacyJSONString: String, warnings: WarningLogger? = nil) throws {
        try self.init(jsonString: legacyJSONString, warnings: warnings)

        guard let url = AnyURL(legacyHREF: href) else {
            return nil
        }
        href = url.string
    }

    @available(*, unavailable, message: "This may create an incorrect `Locator` if the link `type` is missing. Use `publication.locate(Link)` instead.")
    public init(link: Link) { fatalError() }

    public var json: [String: Any] {
        makeJSON([
            "href": href,
            "type": type,
            "title": encodeIfNotNil(title),
            "locations": encodeIfNotEmpty(locations.json),
            "text": encodeIfNotEmpty(text.json),
        ])
    }

    public var jsonString: String? {
        serializeJSONString(json)
    }

    public var description: String {
        jsonString ?? "{}"
    }

    /// Makes a copy of the `Locator`, after modifying some of its components.
    public func copy(href: String? = nil, type: String? = nil, title: String?? = nil, locations transformLocations: ((inout Locations) -> Void)? = nil, text transformText: ((inout Text) -> Void)? = nil) -> Locator {
        var locations = locations
        var text = text
        transformLocations?(&locations)
        transformText?(&text)
        return Locator(
            href: href ?? self.href,
            type: type ?? self.type,
            title: title ?? self.title,
            locations: locations,
            text: text
        )
    }

    /// One or more alternative expressions of the location.
    /// https://github.com/readium/architecture/tree/master/models/locators#the-location-object
    ///
    /// Properties are mutable for convenience when making a copy, but the `locations` property
    /// is immutable in `Locator`, for safety.
    public struct Locations: Hashable, Loggable, WarningLogger {
        /// Contains one or more fragment in the resource referenced by the `Locator`.
        public var fragments: [String]
        /// Progression in the resource expressed as a percentage (between 0 and 1).
        public var progression: Double?
        /// Progression in the publication expressed as a percentage (between 0 and 1).
        public var totalProgression: Double?
        /// An index in the publication (>= 1).
        public var position: Int?

        /// Additional locations for extensions.
        public var otherLocations: [String: Any] {
            get { otherLocationsJSON.json }
            set { otherLocationsJSON = JSONDictionary(newValue) ?? JSONDictionary() }
        }

        // Trick to keep the struct equatable despite [String: Any]
        private var otherLocationsJSON: JSONDictionary

        public init(fragments: [String] = [], progression: Double? = nil, totalProgression: Double? = nil, position: Int? = nil, otherLocations: [String: Any] = [:]) {
            self.fragments = fragments
            self.progression = progression
            self.totalProgression = totalProgression
            self.position = position
            otherLocationsJSON = JSONDictionary(otherLocations) ?? JSONDictionary()
        }

        public init(json: Any?, warnings: WarningLogger? = nil) throws {
            if json == nil {
                self.init()
                return
            }
            guard var jsonObject = JSONDictionary(json) else {
                warnings?.log("Invalid Locations object", model: Self.self, source: json)
                throw JSONError.parsing(Self.self)
            }
            var fragments = (jsonObject.pop("fragments") as? [String]) ?? []
            if let fragment = jsonObject.pop("fragment") as? String {
                fragments.append(fragment)
            }
            self.init(
                fragments: fragments,
                progression: jsonObject.pop("progression") as? Double,
                totalProgression: jsonObject.pop("totalProgression") as? Double,
                position: jsonObject.pop("position") as? Int,
                otherLocations: jsonObject.json
            )
        }

        public init(jsonString: String, warnings: WarningLogger? = nil) {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                try self.init(json: json, warnings: warnings)
            } catch {
                warnings?.log("Invalid Locations object: \(error)", model: Self.self)
                self.init()
            }
        }

        public var isEmpty: Bool { json.isEmpty }

        public var json: [String: Any] {
            makeJSON([
                "fragments": encodeIfNotEmpty(fragments),
                "progression": encodeIfNotNil(progression),
                "totalProgression": encodeIfNotNil(totalProgression),
                "position": encodeIfNotNil(position),
            ], additional: otherLocations)
        }

        public var jsonString: String? { serializeJSONString(json) }

        /// Syntactic sugar to access the `otherLocations` values by subscripting `Locations` directly.
        /// locations["cssSelector"] == locations.otherLocations["cssSelector"]
        public subscript(key: String) -> Any? { otherLocations[key] }
    }

    public struct Text: Hashable, Loggable {
        public var after: String?
        public var before: String?
        public var highlight: String?

        public init(after: String? = nil, before: String? = nil, highlight: String? = nil) {
            self.after = after
            self.before = before
            self.highlight = highlight
        }

        public init(json: Any?, warnings: WarningLogger? = nil) throws {
            if json == nil {
                self.init()
                return
            }
            guard let jsonObject = json as? [String: Any] else {
                warnings?.log("Invalid Text object", model: Self.self, source: json)
                throw JSONError.parsing(Self.self)
            }
            self.init(
                after: jsonObject["after"] as? String,
                before: jsonObject["before"] as? String,
                highlight: jsonObject["highlight"] as? String
            )
        }

        public init(jsonString: String, warnings: WarningLogger? = nil) {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                try self.init(json: json, warnings: warnings)
            } catch {
                warnings?.log("Invalid Text object", model: Self.self)
                self.init()
            }
        }

        public var json: [String: Any] {
            makeJSON([
                "after": encodeIfNotNil(after),
                "before": encodeIfNotNil(before),
                "highlight": encodeIfNotNil(highlight),
            ])
        }

        public var jsonString: String? { serializeJSONString(json) }

        /// Returns a copy of this text after sanitizing its content for user display.
        public func sanitized() -> Locator.Text {
            Locator.Text(
                after: after?.coalescingWhitespaces().removingSuffix(" "),
                before: before?.coalescingWhitespaces().removingPrefix(" "),
                highlight: highlight?.coalescingWhitespaces()
            )
        }

        /// Returns a copy of this text after highlighting a sub-range in the `highlight` property.
        ///
        /// The bounds of the range must be valid indices of the `highlight` property.
        public subscript(range: Range<String.Index>) -> Text {
            guard
                let highlight = highlight,
                !highlight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                preconditionFailure("highlight is nil")
            }

            let range = range
                .clamped(to: highlight.startIndex ..< highlight.endIndex)

            var before = before ?? ""
            var after = after ?? ""
            let newHighlight = highlight[range]
            before = before + highlight[..<range.lowerBound]
            after = highlight[range.upperBound...] + after

            return Locator.Text(
                after: Optional(after).takeIf { !$0.isEmpty },
                before: Optional(before).takeIf { !$0.isEmpty },
                highlight: String(newHighlight)
            )
        }
    }
}

public extension Array where Element == Locator {
    /// Parses multiple JSON locators into an array of `Locator`.
    init(json: Any?, warnings: WarningLogger? = nil) {
        self.init()
        guard let json = json as? [Any] else {
            return
        }

        let links = json.compactMap { try? Locator(json: $0, warnings: warnings) }
        append(contentsOf: links)
    }

    var json: [[String: Any]] {
        map(\.json)
    }
}

/// Represents a sequential list of `Locator` objects.
///
/// For example, a search result or a list of positions.
///
/// **WARNING:** This API is experimental and may change or be removed in a future release without
/// notice. Use with caution.
public struct _LocatorCollection: Hashable {
    public var metadata: Metadata
    public var links: [Link]
    public var locators: [Locator]

    public init(metadata: Metadata = Metadata(), links: [Link] = [], locators: [Locator] = []) {
        self.metadata = metadata
        self.links = links
        self.locators = locators
    }

    public init?(json: Any?, warnings: WarningLogger? = nil) {
        if json == nil {
            return nil
        }
        guard let jsonObject = json as? [String: Any] else {
            warnings?.log("Not a JSON object", model: Self.self, source: json)
            return nil
        }
        self.init(
            metadata: Metadata(json: jsonObject["metadata"], warnings: warnings),
            links: [Link](json: jsonObject["links"]),
            locators: [Locator](json: jsonObject["locators"])
        )
    }

    public var json: [String: Any] {
        makeJSON([
            "metadata": encodeIfNotEmpty(metadata.json),
            "links": encodeIfNotEmpty(links.json),
            "locators": locators.json,
        ])
    }

    /// Holds the metadata of a `LocatorCollection`.
    public struct Metadata: Hashable {
        public var localizedTitle: LocalizedString?
        public var title: String? { localizedTitle?.string }

        /// Indicates the total number of locators in the collection.
        public var numberOfItems: Int?

        /// Additional properties for extensions.
        public var otherMetadata: [String: Any] {
            get { otherMetadataJSON.json }
            set { otherMetadataJSON = JSONDictionary(newValue) ?? JSONDictionary() }
        }

        // Trick to keep the struct equatable despite [String: Any]
        private var otherMetadataJSON: JSONDictionary

        public init(
            title: LocalizedStringConvertible? = nil,
            numberOfItems: Int? = nil,
            otherMetadata: [String: Any] = [:]
        ) {
            localizedTitle = title?.localizedString
            self.numberOfItems = numberOfItems
            otherMetadataJSON = JSONDictionary(otherMetadata) ?? JSONDictionary()
        }

        public init(json: Any?, warnings: WarningLogger? = nil) {
            if var json = JSONDictionary(json) {
                localizedTitle = try? LocalizedString(json: json.pop("title"), warnings: warnings)
                numberOfItems = parsePositive(json.pop("numberOfItems"))
                otherMetadataJSON = json
            } else {
                warnings?.log("Not a JSON object", model: Self.self, source: json)
                localizedTitle = nil
                numberOfItems = nil
                otherMetadataJSON = JSONDictionary()
            }
        }

        public var json: [String: Any] {
            makeJSON([
                "title": encodeIfNotNil(localizedTitle?.json),
                "numberOfItems": encodeIfNotNil(numberOfItems),
            ], additional: otherMetadata)
        }
    }
}
