import Foundation

class UserSettings {

    /// Stores all `UserSettings` keys.
    ///
    /// The additional level of indirection allows these keys to be retrieved from tests.
    ///
    /// **IMPORTANT NOTE:**
    ///
    /// Any change to these keys is a breaking change without some kind of migration.
    /// It's probably best never to change them.
    struct Keys {
        static let crashLoggingOptOutKey = "crashlytics_opt_out"
        static let forceCrashLoggingKey = "force-crash-logging"
        static let defaultDotComUUIDKey = "AccountDefaultDotcomUUID"
    }

    @objc
    @UserDefault(Keys.crashLoggingOptOutKey, defaultValue: false)
    static var userHasOptedOutOfCrashLogging: Bool

    @objc
    @UserDefault(Keys.forceCrashLoggingKey, defaultValue: false)
    static var userHasForcedCrashLoggingEnabled: Bool

    @objc
    @EraseableUserDefault(Keys.defaultDotComUUIDKey)
    static var defaultDotComUUID: String?
}

/// A property wrapper for UserDefaults access
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

/// A property wrapper for optional UserDefaults that return `nil` by default
@propertyWrapper
struct EraseableUserDefault<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T? {
        get {
            return UserDefaults.standard.object(forKey: key) as? T
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
