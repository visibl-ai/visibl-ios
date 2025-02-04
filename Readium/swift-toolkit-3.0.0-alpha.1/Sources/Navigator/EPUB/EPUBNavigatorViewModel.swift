//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import ReadiumShared
import UIKit

protocol EPUBNavigatorViewModelDelegate: AnyObject {
    func epubNavigatorViewModel(_ viewModel: EPUBNavigatorViewModel, runScript script: String, in scope: EPUBScriptScope)
    func epubNavigatorViewModelInvalidatePaginationView(_ viewModel: EPUBNavigatorViewModel)
    func epubNavigatorViewModel(_ viewModel: EPUBNavigatorViewModel, didFailToLoadResourceAt href: RelativeURL, withError error: ResourceError)
}

enum EPUBScriptScope {
    case currentResource
    case loadedResources
    case resource(href: String)
}

final class EPUBNavigatorViewModel: Loggable {
    enum Error: Swift.Error {
        case noHTTPServer
    }

    let publication: Publication
    let config: EPUBNavigatorViewController.Configuration
    let editingActions: EditingActionsController
    private let httpServer: HTTPServer?
    private let publicationEndpoint: HTTPServerEndpoint?
    private(set) var publicationBaseURL: HTTPURL!
    let assetsURL: HTTPURL
    weak var delegate: EPUBNavigatorViewModelDelegate?

    let useLegacySettings: Bool

    /// Local file URL associated to the HTTP URL used to serve the file on the
    /// `httpServer`. This is used to serve custom font files, for example.
    @Atomic private var servedFiles: [FileURL: HTTPURL] = [:]

    convenience init(
        publication: Publication,
        config: EPUBNavigatorViewController.Configuration,
        httpServer: HTTPServer
    ) throws {
        let uuidEndpoint: HTTPServerEndpoint = UUID().uuidString
        let publicationEndpoint: HTTPServerEndpoint?
        if publication.baseURL != nil {
            publicationEndpoint = nil
        } else {
            publicationEndpoint = uuidEndpoint
        }

        try self.init(
            publication: publication,
            config: config,
            httpServer: httpServer,
            publicationEndpoint: publicationEndpoint,
            assetsURL: httpServer.serve(
                at: "readium",
                contentsOf: Bundle.module.resourceURL!.fileURL!
                    .appendingPath("Assets/Static", isDirectory: true),
                failureHandler: nil
            ),
            useLegacySettings: false
        )

        if let url = publication.baseURL {
            publicationBaseURL = url
        } else {
            publicationBaseURL = try httpServer.serve(
                at: uuidEndpoint, // serving the chapters endpoint
                publication: publication,
                failureHandler: { [weak self] request, error in
                    guard let self = self, let href = request.href else {
                        return
                    }
                    self.delegate?.epubNavigatorViewModel(self, didFailToLoadResourceAt: href, withError: error)
                }
            )
        }

        if let endpoint = publicationEndpoint {
            try httpServer.transformResources(at: endpoint) { [weak self] in
                self?.injectReadiumCSS(in: $0) ?? $0
            }
        }
    }

    @available(*, unavailable, message: "See the 2.5.0 migration guide to migrate the Settings API")
    convenience init(
        publication: Publication,
        config: EPUBNavigatorViewController.Configuration,
        resourcesServer: ResourcesServer
    ) {
        fatalError()
    }

    private init(
        publication: Publication,
        config: EPUBNavigatorViewController.Configuration,
        httpServer: HTTPServer?,
        publicationEndpoint: HTTPServerEndpoint?,
        assetsURL: HTTPURL,
        useLegacySettings: Bool
    ) {
        var config = config

        if let fontsDir = Bundle.module.resourceURL?.fileURL?.appendingPath("Assets/Static/fonts", isDirectory: true) {
            config.fontFamilyDeclarations.append(
                CSSFontFamilyDeclaration(
                    fontFamily: .openDyslexic,
                    fontFaces: [
                        CSSFontFace(
                            file: fontsDir.appendingPath("OpenDyslexic-Regular.otf", isDirectory: false),
                            style: .normal, weight: .standard(.normal)
                        ),
                        CSSFontFace(
                            file: fontsDir.appendingPath("OpenDyslexic-Italic.otf", isDirectory: false),
                            style: .italic, weight: .standard(.normal)
                        ),
                        CSSFontFace(
                            file: fontsDir.appendingPath("OpenDyslexic-Bold.otf", isDirectory: false),
                            style: .normal, weight: .standard(.bold)
                        ),
                        CSSFontFace(
                            file: fontsDir.appendingPath("OpenDyslexic-BoldItalic.otf", isDirectory: false),
                            style: .italic, weight: .standard(.bold)
                        ),
                    ]
                ).eraseToAnyHTMLFontFamilyDeclaration()
            )
        }

        self.publication = publication
        self.config = config
        editingActions = EditingActionsController(
            actions: config.editingActions,
            publication: publication
        )
        self.httpServer = httpServer
        self.publicationEndpoint = publicationEndpoint
        self.assetsURL = assetsURL
        self.useLegacySettings = useLegacySettings
        legacyReadingProgression = publication.metadata.effectiveReadingProgression

        preferences = config.preferences
        settings = EPUBSettings(publication: publication, config: config)

        css = ReadiumCSS(
            layout: CSSLayout(),
            rsProperties: config.readiumCSSRSProperties,
            baseURL: assetsURL.appendingPath("readium-css", isDirectory: true),
            fontFamilyDeclarations: config.fontFamilyDeclarations
        )

        css.update(with: settings)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusDidChange),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        if let endpoint = publicationEndpoint {
            try? httpServer?.remove(at: endpoint)
        }
    }

    func url(to link: Link) -> AnyURL? {
        try? link.url(relativeTo: publicationBaseURL)
    }

    private func serveFile(at file: FileURL, baseEndpoint: HTTPServerEndpoint) throws -> HTTPURL {
        if let url = servedFiles[file] {
            return url
        }

        guard let httpServer = httpServer else {
            throw Error.noHTTPServer
        }
        let endpoint = baseEndpoint.addingSuffix("/") + file.lastPathSegment
        let url = try httpServer.serve(at: endpoint, contentsOf: file, failureHandler: nil)
        $servedFiles.write { $0[file] = url }
        return url
    }

    private var needsInvalidatePagination = false
    private func setNeedsInvalidatePagination() {
        guard !needsInvalidatePagination else {
            return
        }
        needsInvalidatePagination = true
        DispatchQueue.main.async { [self] in
            needsInvalidatePagination = false
            delegate?.epubNavigatorViewModelInvalidatePaginationView(self)
        }
    }

    // MARK: - User preferences

    /// Currently applied settings.
    private(set) var settings: EPUBSettings

    /// Last submitted preferences.
    private var preferences: EPUBPreferences

    func submitPreferences(_ preferences: EPUBPreferences) {
        self.preferences = preferences
        applyPreferences()
    }

    private func applyPreferences() {
        let oldSettings = settings
        let newSettings = EPUBSettings(
            preferences: preferences,
            publication: publication,
            config: config
        )

        settings = newSettings
        updateSpread()

        let needsInvalidation: Bool =
            oldSettings.readingProgression != newSettings.readingProgression
                || oldSettings.language != newSettings.language
                || oldSettings.verticalText != newSettings.verticalText
                || oldSettings.scroll != newSettings.scroll
                || oldSettings.spread != newSettings.spread

        // We don't commit the CSS changes if we invalidate the pagination, as
        // the resources will be reloaded anyway.
        updateCSS(with: settings, commitNow: !needsInvalidation)

        if needsInvalidation {
            setNeedsInvalidatePagination()
        }
    }

    func editor(of preferences: EPUBPreferences) -> EPUBPreferencesEditor {
        EPUBPreferencesEditor(
            initialPreferences: preferences,
            metadata: publication.metadata,
            defaults: config.defaults
        )
    }

    var readingProgression: ReadingProgression {
        useLegacySettings
            ? (ReadingProgression(legacyReadingProgression) ?? .ltr)
            : settings.readingProgression
    }

    var legacyReadingProgression: ReadiumShared.ReadingProgression

    var theme: Theme {
        useLegacySettings ? legacyTheme : settings.theme
    }

    private var legacyTheme: Theme {
        guard
            let appearance = config.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.appearance.rawValue) as? Enumerable,
            appearance.values.count > appearance.index
        else {
            return .light
        }
        let value = appearance.values[appearance.index]
        switch value {
        case "readium-night-on":
            return .dark
        case "readium-sepia-on":
            return .sepia
        default:
            return .light
        }
    }

    var scroll: Bool {
        useLegacySettings ? legacyScroll : settings.scroll
    }

    private var legacyScroll: Bool {
        (config.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.scroll.rawValue) as? Switchable)?.on ?? false
    }

    // MARK: Spread

    private(set) var spreadEnabled: Bool = false
    private var viewSize: CGSize?

    func viewSizeWillChange(_ newSize: CGSize) {
        guard viewSize != newSize else {
            return
        }
        viewSize = newSize
        updateSpread()
    }

    private func updateSpread() {
        let size = viewSize ?? .zero
        let isLandscape = size.width > size.height
        let oldEnabled = spreadEnabled

        switch spread {
        case .never:
            spreadEnabled = false
        case .always:
            spreadEnabled = true
        case .auto:
            spreadEnabled = isLandscape
        }

        if oldEnabled != spreadEnabled {
            setNeedsInvalidatePagination()
        }
    }

    private var spread: Spread {
        useLegacySettings ? legacySpread : settings.spread
    }

    private var legacySpread: Spread {
        let columnCount = config.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.columnCount.rawValue) as? Enumerable

        switch columnCount?.index {
        case 0:
            return .auto
        case 1:
            return .never
        case 2:
            return .always
        default:
            return Spread(publication.metadata.presentation.spread) ?? .auto
        }
    }

    // MARK: - Readium CSS

    private var css: ReadiumCSS

    private func serveFont(at file: FileURL) throws -> HTTPURL {
        try serveFile(at: file, baseEndpoint: "custom-fonts/\(UUID().uuidString)")
    }

    func injectReadiumCSS(in resource: Resource) -> Resource {
        let link = resource.link
        guard
            link.mediaType.isHTML,
            publication.metadata.presentation.layout(of: link) == .reflowable
        else {
            return resource
        }

        return resource.mapAsString { [self] content in
            do {
                var content = try css.inject(in: content)
                for ff in config.fontFamilyDeclarations {
                    content = try ff.inject(in: content, servingFile: serveFont)
                }
                return content
            } catch {
                log(.error, error)
                return content
            }
        }
    }

    private func updateCSS(with settings: EPUBSettings, commitNow: Bool) {
        let previous = css
        css.update(with: settings)

        if commitNow {
            commitCSSChange(from: previous, to: css)
        }
    }

    private func commitCSSChange(from previous: ReadiumCSS, to new: ReadiumCSS) {
        var properties: [String: String?] = [:]
        let rsProperties = new.rsProperties.cssProperties()
        if previous.rsProperties.cssProperties() != rsProperties {
            for (k, v) in rsProperties {
                properties[k] = v
            }
        }
        let userProperties = new.userProperties.cssProperties()
        if previous.userProperties.cssProperties() != userProperties {
            for (k, v) in userProperties {
                properties[k] = v
            }
        }
        if !properties.isEmpty {
            guard
                let data = try? JSONSerialization.data(withJSONObject: properties),
                let json = String(data: data, encoding: .utf8)
            else {
                log(.error, "Failed to serialize CSS properties to JSON")
                return
            }

            delegate?.epubNavigatorViewModel(
                self,
                runScript: "readium.setCSSProperties(\(json));",
                in: .loadedResources
            )
        }
    }

    // MARK: - Accessibility

    private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

    @objc private func voiceOverStatusDidChange() {
        // Avoids excessive settings refresh when the status didn't change.
        guard isVoiceOverRunning != UIAccessibility.isVoiceOverRunning else {
            return
        }
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

        // Re-apply preferences to force the scroll mode if needed.
        applyPreferences()
    }
}

private extension EPUBSettings {
    init(
        preferences: EPUBPreferences? = nil,
        publication: Publication,
        config: EPUBNavigatorViewController.Configuration
    ) {
        self.init(
            preferences: preferences ?? config.preferences,
            defaults: config.defaults,
            metadata: publication.metadata
        )

        // Force-enables scroll when VoiceOver is running, because pagination
        // breaks the screen reader.
        if UIAccessibility.isVoiceOverRunning {
            scroll = true
        }
    }
}
