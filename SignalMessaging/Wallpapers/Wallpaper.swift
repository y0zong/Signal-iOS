//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public enum Wallpaper: String, CaseIterable {
    public static let wallpaperDidChangeNotification = NSNotification.Name("wallpaperDidChangeNotification")

    // Solid
    case blush
    case copper
    case zorba
    case envy
    case sky
    case wildBlueYonder
    case lavender
    case shocking
    case gray
    case eden
    case violet
    case eggplant

    // Gradient
    case starshipGradient
    case woodsmokeGradient
    case coralGradient
    case ceruleanGradient
    case roseGradient
    case aquamarineGradient
    case tropicalGradient
    case blueGradient
    case bisqueGradient

    // Custom
    case photo

    public static var defaultWallpapers: [Wallpaper] { allCases.filter { $0 != .photo } }

    public static func warmCaches() {
        owsAssertDebug(!Thread.isMainThread)

        let photoURLs: [URL]
        do {
            photoURLs = try OWSFileSystem.recursiveFilesInDirectory(wallpaperDirectory.path).map { URL(fileURLWithPath: $0) }
        } catch {
            owsFailDebug("Failed to enumerate wallpaper photos \(error)")
            return
        }

        guard !photoURLs.isEmpty else { return }

        var keysToCache = [String]()
        var orphanedKeys = [String]()

        SDSDatabaseStorage.shared.read { transaction in
            for url in photoURLs {
                guard let key = url.lastPathComponent.removingPercentEncoding else {
                    owsFailDebug("Failed to remove percent encoding in key")
                    continue
                }
                guard case .photo = get(for: key, transaction: transaction) else {
                    orphanedKeys.append(key)
                    continue
                }
                keysToCache.append(key)
            }
        }

        if !orphanedKeys.isEmpty {
            Logger.info("Cleaning up \(orphanedKeys.count) orphaned wallpaper photos")
            for key in orphanedKeys {
                do {
                    try cleanupPhotoIfNecessary(for: key)
                } catch {
                    owsFailDebug("Failed to cleanup orphaned wallpaper photo \(key) \(error)")
                }
            }
        }

        for key in keysToCache {
            do {
                try photo(for: key)
            } catch {
                owsFailDebug("Failed to cache wallpaper photo \(key) \(error)")
            }
        }
    }

    public static func clear(for thread: TSThread? = nil, transaction: SDSAnyWriteTransaction) throws {
        owsAssertDebug(!Thread.isMainThread)

        enumStore.removeValue(forKey: key(for: thread), transaction: transaction)
        dimmingStore.removeValue(forKey: key(for: thread), transaction: transaction)
        try OWSFileSystem.deleteFileIfExists(url: photoURL(for: thread))

        transaction.addAsyncCompletion {
            NotificationCenter.default.post(name: wallpaperDidChangeNotification, object: thread?.uniqueId)
        }
    }

    public static func resetAll(transaction: SDSAnyWriteTransaction) throws {
        owsAssertDebug(!Thread.isMainThread)

        enumStore.removeAll(transaction: transaction)
        dimmingStore.removeAll(transaction: transaction)
        try OWSFileSystem.deleteFileIfExists(url: wallpaperDirectory)

        transaction.addAsyncCompletion {
            NotificationCenter.default.post(name: wallpaperDidChangeNotification, object: nil)
        }
    }

    public static func setBuiltIn(_ wallpaper: Wallpaper, for thread: TSThread? = nil, transaction: SDSAnyWriteTransaction) throws {
        owsAssertDebug(!Thread.isMainThread)

        owsAssertDebug(wallpaper != .photo)

        try set(wallpaper, for: thread, transaction: transaction)
    }

    public static func setPhoto(_ photo: UIImage, for thread: TSThread? = nil, transaction: SDSAnyWriteTransaction) throws {
        owsAssertDebug(Thread.current != .main)

        try set(.photo, photo: photo, for: thread, transaction: transaction)
    }

    public static func exists(for thread: TSThread? = nil, transaction: SDSAnyReadTransaction) -> Bool {
        guard get(for: thread, transaction: transaction) != nil else {
            if thread != nil { return exists(transaction: transaction) }
            return false
        }
        return true
    }

    public static func dimInDarkMode(for thread: TSThread? = nil, transaction: SDSAnyReadTransaction) -> Bool {
        guard let dimInDarkMode = getDimInDarkMode(for: thread, transaction: transaction) else {
            if thread != nil { return self.dimInDarkMode(transaction: transaction) }
            return true
        }
        return dimInDarkMode
    }

    public static func view(for thread: TSThread? = nil,
                            maskDataSource: WallpaperMaskDataSource?,
                            transaction: SDSAnyReadTransaction) -> WallpaperView? {
        AssertIsOnMainThread()

        guard let wallpaper: Wallpaper = {
            if let wallpaper = get(for: thread, transaction: transaction) {
                return wallpaper
            } else if thread != nil, let wallpaper = get(for: nil, transaction: transaction) {
                return wallpaper
            } else {
                return nil
            }
        }() else { return nil }

        let photo: UIImage? = {
            guard case .photo = wallpaper else { return nil }
            if let photo = try? self.photo(for: thread) {
                return photo
            } else if thread != nil, let photo = try? self.photo(for: nil) {
                return photo
            } else {
                return nil
            }
        }()

        if case .photo = wallpaper, photo == nil {
            owsFailDebug("Missing photo for wallpaper \(wallpaper)")
            return nil
        }

        let shouldDim = (Theme.isDarkThemeEnabled &&
                            dimInDarkMode(for: thread, transaction: transaction))

        guard let view = view(for: wallpaper,
                              maskDataSource: maskDataSource,
                              photo: photo,
                              shouldDim: shouldDim) else {
            return nil
       }

        return view
    }

    public static func shouldDim(thread: TSThread?,
                                 transaction: SDSAnyReadTransaction) -> Bool {
        (Theme.isDarkThemeEnabled &&
            dimInDarkMode(for: thread, transaction: transaction))
    }

    public static func view(for wallpaper: Wallpaper,
                            maskDataSource: WallpaperMaskDataSource?,
                            photo: UIImage? = nil,
                            shouldDim: Bool) -> WallpaperView? {
        AssertIsOnMainThread()

        guard let mode = { () -> WallpaperView.Mode? in
            if let solidColor = wallpaper.solidColor {
                return .solidColor(solidColor: solidColor)
            } else if let gradientView = wallpaper.gradientView {
                return .gradientView(gradientView: gradientView)
            } else if case .photo = wallpaper {
                guard let photo = photo else {
                    owsFailDebug("Missing photo for wallpaper \(wallpaper)")
                    return nil
                }
                return .image(image: photo)
            } else {
                owsFailDebug("Unexpected wallpaper type \(wallpaper)")
                return nil
            }
        }() else {
            return nil
        }
        return WallpaperView(mode: mode,
                             maskDataSource: maskDataSource,
                             shouldDim: shouldDim)
    }
}

// MARK: -

fileprivate extension Wallpaper {
    static func key(for thread: TSThread?) -> String {
        return thread?.uniqueId ?? "global"
    }
}

// MARK: -

fileprivate extension Wallpaper {
    private static let enumStore = SDSKeyValueStore(collection: "Wallpaper+Enum")

    static func set(_ wallpaper: Wallpaper?, photo: UIImage? = nil, for thread: TSThread?, transaction: SDSAnyWriteTransaction) throws {
        owsAssertDebug(photo == nil || wallpaper == .photo)

        try cleanupPhotoIfNecessary(for: thread)

        if let photo = photo { try setPhoto(photo, for: thread) }

        enumStore.setString(wallpaper?.rawValue, key: key(for: thread), transaction: transaction)

        transaction.addAsyncCompletion {
            NotificationCenter.default.post(name: wallpaperDidChangeNotification, object: thread?.uniqueId)
        }
    }

    static func get(for thread: TSThread?, transaction: SDSAnyReadTransaction) -> Wallpaper? {
        return get(for: key(for: thread), transaction: transaction)
    }

    static func get(for key: String, transaction: SDSAnyReadTransaction) -> Wallpaper? {
        guard let rawValue = enumStore.getString(key, transaction: transaction) else {
            return nil
        }
        guard let wallpaper = Wallpaper(rawValue: rawValue) else {
            owsFailDebug("Unexpectedly wallpaper \(rawValue)")
            return nil
        }
        return wallpaper
    }
}

// MARK: -

extension Wallpaper {
    private static let dimmingStore = SDSKeyValueStore(collection: "Wallpaper+Dimming")

    public static func setDimInDarkMode(_ dimInDarkMode: Bool, for thread: TSThread?, transaction: SDSAnyWriteTransaction) throws {
        dimmingStore.setBool(dimInDarkMode, key: key(for: thread), transaction: transaction)

        transaction.addAsyncCompletion {
            NotificationCenter.default.post(name: wallpaperDidChangeNotification, object: thread?.uniqueId)
        }
    }

    fileprivate static func getDimInDarkMode(for thread: TSThread?, transaction: SDSAnyReadTransaction) -> Bool? {
        return dimmingStore.getBool(key(for: thread), transaction: transaction)
    }
}

// MARK: - Photo management

fileprivate extension Wallpaper {
    static let appSharedDataDirectory = URL(fileURLWithPath: OWSFileSystem.appSharedDataDirectoryPath())
    static let wallpaperDirectory = URL(fileURLWithPath: "Wallpapers", isDirectory: true, relativeTo: appSharedDataDirectory)
    static let cache = NSCache<NSString, UIImage>()

    static func ensureWallpaperDirectory() throws {
        guard OWSFileSystem.ensureDirectoryExists(wallpaperDirectory.path) else {
            throw OWSAssertionError("Failed to create ensure wallpaper directory")
        }
    }

    static func setPhoto(_ photo: UIImage, for thread: TSThread?) throws {
        owsAssertDebug(!Thread.isMainThread)

        cache.setObject(photo, forKey: key(for: thread) as NSString)

        guard let data = photo.jpegData(compressionQuality: 0.8) else {
            throw OWSAssertionError("Failed to get jpg data for wallpaper photo")
        }
        guard !OWSFileSystem.fileOrFolderExists(url: try photoURL(for: thread)) else { return }
        try ensureWallpaperDirectory()
        try data.write(to: try photoURL(for: thread), options: .atomic)
    }

    static func photo(for thread: TSThread?) throws -> UIImage? {
        return try photo(for: key(for: thread))
    }

    @discardableResult
    static func photo(for key: String) throws -> UIImage? {
        if let photo = cache.object(forKey: key as NSString) { return photo }

        guard OWSFileSystem.fileOrFolderExists(url: try photoURL(for: key)) else { return nil }

        let data = try Data(contentsOf: try photoURL(for: key))

        guard let photo = UIImage(data: data) else {
            owsFailDebug("Failed to initialize wallpaper photo from data")
            try cleanupPhotoIfNecessary(for: key)
            return nil
        }

        cache.setObject(photo, forKey: key as NSString)

        return photo
    }

    static func cleanupPhotoIfNecessary(for thread: TSThread?) throws {
        try cleanupPhotoIfNecessary(for: key(for: thread))
    }

    static func cleanupPhotoIfNecessary(for key: String) throws {
        owsAssertDebug(!Thread.isMainThread)

        cache.removeObject(forKey: key as NSString)
        try OWSFileSystem.deleteFileIfExists(url: try photoURL(for: key))
    }

    static func photoURL(for thread: TSThread?) throws -> URL {
        return try photoURL(for: key(for: thread))
    }

    static func photoURL(for key: String) throws -> URL {
        guard let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw OWSAssertionError("Failed to percent encode filename")
        }
        return URL(fileURLWithPath: filename, relativeTo: wallpaperDirectory)
    }
}

// MARK: -

public struct WallpaperMaskBuilder {

    fileprivate let maskPath = UIBezierPath()
    public let referenceView: UIView
    fileprivate let isAnimating: Bool

    public func append(blurPath: UIBezierPath) {
        maskPath.append(blurPath)
    }

    public func append(blurView: UIView?) {
        guard let blurView = blurView else {
            Logger.warn("Missing blurView.")
            return
        }
//        Logger.verbose("---- blurView.frame: \(blurView.frame), \(blurView.layer.frame), " +
//                        " bounds: \(blurView.bounds), \(blurView.layer.bounds).")
//        if let presentation = blurView.layer.presentation() {
//            Logger.verbose("---- presentation.frame: \(presentation.frame), " +
//                            " bounds: \(presentation.bounds)")
//        }
        let blurFrame1 = referenceView.convert(blurView.bounds, from: blurView)
        let blurFrame2 = referenceView.layer.convert(blurView.bounds, from: blurView.layer)

//        let blurFrame3 = dstLayer.convert(srcLayer.bounds, from: srcLayer)
//        let blurFrame = isAnimating ? blurFrame3 : blurFrame1

        let blurFrame: CGRect
        if isAnimating,
           let srcLayer = blurView.layer.presentation(),
           let dstLayer = referenceView.layer.presentation() {
            blurFrame = dstLayer.convert(srcLayer.bounds, from: srcLayer)
        } else {
            blurFrame = referenceView.convert(blurView.bounds, from: blurView)
        }

//        let blurFrame3 = referenceView.layer.convert(blurView.bounds, from: blurView)
//        Logger.verbose("---- blurFrame: \(blurFrame), blurFrame1: \(blurFrame1), blurFrame2: \(blurFrame2), blurFrame3: \(blurFrame3)")
//        Logger.verbose("---- blurFrame: \(blurFrame), blurFrame1: \(blurFrame1), blurFrame3: \(blurFrame3)")
        Logger.verbose("---- blurFrame: \(blurFrame), blurFrame1: \(blurFrame1)")
        Logger.verbose("---- isAnimating: \(isAnimating)")
        let blurPath: UIBezierPath = {
            return UIBezierPath(roundedRect: blurFrame,
                                byRoundingCorners: blurView.layer.maskedCorners.asUIRectCorner,
                                cornerRadii: .square(blurView.layer.cornerRadius))
        }()
        append(blurPath: blurPath)
    }
}

// MARK: -

public protocol WallpaperMaskDataSource: class {
    func buildWallpaperMask(_ wallpaperMaskBuilder: WallpaperMaskBuilder)
    var isWallpaperPreview: Bool { get }
}

// MARK: -

public class WallpaperView {
    fileprivate enum Mode {
        case solidColor(solidColor: UIColor)
        case gradientView(gradientView: UIView)
        case image(image: UIImage)
    }

    private var _blurView: BlurView?

    public var blurView: UIView? { _blurView }

    public private(set) var contentView: UIView?

    public private(set) var dimmingView: UIView?

    private let mode: Mode

    fileprivate init(mode: Mode,
                     maskDataSource: WallpaperMaskDataSource?,
                     shouldDim: Bool) {
        self.mode = mode

        configure(maskDataSource: maskDataSource, shouldDim: shouldDim)
    }

    @available(swift, obsoleted: 1.0)
    required init(name: String) {
        owsFail("Do not use this initializer.")
    }

    public enum PreviewMode {
        case all
        case blur
        case contentAndDimming

        fileprivate var showContentAndDimming: Bool {
            switch self {
            case .all, .contentAndDimming:
                return true
            case .blur:
                return false
            }
        }

        fileprivate var showBlur: Bool {
            switch self {
            case .all, .contentAndDimming:
                return false
            case .blur:
                return true
            }
        }
    }

    public func asPreviewView(mode: PreviewMode) -> UIView {
        let previewView = UIView.container()
        if mode.showContentAndDimming,
           let contentView = self.contentView {
            previewView.addSubview(contentView)
            contentView.autoPinEdgesToSuperviewEdges()
        }
        if mode.showContentAndDimming,
           let dimmingView = self.dimmingView {
            previewView.addSubview(dimmingView)
            dimmingView.autoPinEdgesToSuperviewEdges()
        }
        if mode.showBlur,
           let blurView = self.blurView {
            previewView.addSubview(blurView)
            blurView.autoPinEdgesToSuperviewEdges()
        }
        return previewView
    }

    private func configure(maskDataSource: WallpaperMaskDataSource?,
                           shouldDim: Bool) {
        let contentView: UIView = {
            switch mode {
            case .solidColor(let solidColor):
                let isWallpaperPreview = maskDataSource?.isWallpaperPreview ?? false
                 if isWallpaperPreview {
                    let contentView = OWSLayerView(frame: .zero) { [weak self] _ in
                        self?.updateBlurContentAndMask()
                    }
                    contentView.backgroundColor = solidColor
                    return contentView
                } else {
                    let contentView = UIView()
                    contentView.backgroundColor = solidColor
                    return contentView
                }
            case .gradientView(let gradientView):
                return gradientView
            case .image(let image):
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                return imageView
            }
        }()
        self.contentView = contentView

        addBlurView(contentView: contentView, maskDataSource: maskDataSource)

        if shouldDim {
            let dimmingView = UIView()
            dimmingView.backgroundColor = .ows_blackAlpha20
            self.dimmingView = dimmingView
        }
    }

    private func addBlurView(contentView: UIView,
                             maskDataSource: WallpaperMaskDataSource?) {
        guard let maskDataSource = maskDataSource else {
            return
        }
        let blurView = BlurView(contentView: contentView, maskDataSource: maskDataSource)
        _blurView = blurView
    }

    public func updateBlurContentAndMask(isAnimating: Bool = false) {
        _blurView?.updateContentAndMask(isAnimating: isAnimating)
    }

    public func updateBlurMask(isAnimating: Bool = false) {
        _blurView?.updateMask(isAnimating: isAnimating)
    }

    // MARK: -

    private class BlurView: UIImageView {
        private let contentView: UIView
        private let maskLayer = CAShapeLayer()
        private weak var maskDataSource: WallpaperMaskDataSource?

        init(contentView: UIView, maskDataSource: WallpaperMaskDataSource) {
            self.contentView = contentView
            self.maskDataSource = maskDataSource

            super.init(frame: .zero)

            self.contentMode = .scaleAspectFill
            self.clipsToBounds = true

            self.layer.mask = maskLayer

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(themeDidChange),
                                                   name: .ThemeDidChange,
                                                   object: nil)
        }

        @available(swift, obsoleted: 1.0)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func themeDidChange() {
            updateContent()
        }

        func updateContentAndMask(isAnimating: Bool) {
            updateContent()
            updateMask(isAnimating: isAnimating)
        }

        func updateMask(isAnimating: Bool) {
            guard let maskDataSource = self.maskDataSource else {
                owsFailDebug("Missing maskDataSource.")
                resetMask()
                return
            }
            let builder = WallpaperMaskBuilder(referenceView: self, isAnimating: isAnimating)
            maskDataSource.buildWallpaperMask(builder)
            maskLayer.path = builder.maskPath.cgPath
        }

        private struct ContentToken: Equatable {
            let contentSize: CGSize
            let isDarkThemeEnabled: Bool
        }
        private var contentToken: ContentToken?

        func updateContent() {
            // De-bounce.
            let isDarkThemeEnabled = Theme.isDarkThemeEnabled
            let newContentToken = ContentToken(contentSize: bounds.size,
                                               isDarkThemeEnabled: isDarkThemeEnabled)
            guard contentToken != newContentToken else {
                return
            }

            do {
                guard bounds.width > 0, bounds.height > 0 else {
                    resetContent()
                    return
                }
                guard let contentImage = contentView.renderAsImage() else {
                    owsFailDebug("Could not render contentView.")
                    resetContent()
                    return
                }
                // We approximate the behavior of UIVisualEffectView(effect: UIBlurEffect(style: .regular)).
                let tintColor: UIColor = (isDarkThemeEnabled
                                            ? UIColor.ows_black.withAlphaComponent(0.9)
                                            : .ows_whiteAlpha60)
                let resizeFactor: CGFloat = 8
                let resizeDimension = contentImage.size.largerAxis / resizeFactor
                guard let scaledImage = contentImage.resized(withMaxDimensionPoints: resizeDimension) else {
                    owsFailDebug("Could not resize contentImage.")
                    resetContent()
                    return
                }
                let blurRadius: CGFloat = 32 / resizeFactor
                let blurredImage = try scaledImage.withGausianBlur(radius: blurRadius,
                                                                   tintColor: tintColor)
                self.image = blurredImage
                self.contentToken = newContentToken
            } catch {
                owsFailDebug("Error: \(error).")
                resetContent()
            }
        }

        private func reset() {
            resetContent()
            resetMask()
        }

        private func resetMask() {
            maskLayer.path = nil
        }

        private func resetContent() {
            image = nil
            contentToken = nil
        }
    }
}

// MARK: -

extension CACornerMask {
    var asUIRectCorner: UIRectCorner {
        var corners = UIRectCorner()
        if self.contains(.layerMinXMinYCorner) {
            corners.formUnion(.topLeft)
        }
        if self.contains(.layerMaxXMinYCorner) {
            corners.formUnion(.topRight)
        }
        if self.contains(.layerMinXMaxYCorner) {
            corners.formUnion(.bottomLeft)
        }
        if self.contains(.layerMaxXMaxYCorner) {
            corners.formUnion(.bottomRight)
        }
        return corners
    }
}
