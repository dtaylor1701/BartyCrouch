import Foundation
import MungoHealer
import Toml

enum Translator: String {
  case microsoftTranslator
  case deepL
}

struct TranslateOptions {
  let paths: [String]
  let subpathsToIgnore: [String]
  let secret: Secret
  let sourceLocale: String
}

extension TranslateOptions: TomlCodable {
  static func make(toml: Toml) throws -> TranslateOptions {
    let update: String = "update"
    let translate: String = "translate"

    if let secretString: String = toml.string(update, translate, "secret") {
      let translator = toml.string(update, translate, "translator") ?? ""
      let paths = toml.filePaths(update, translate, singularKey: "path", pluralKey: "paths")
      let subpathsToIgnore = toml.array(update, translate, "subpathsToIgnore") ?? Constants.defaultSubpathsToIgnore
      let sourceLocale: String = toml.string(update, translate, "sourceLocale") ?? "en"
      let secret: Secret
      switch Translator(rawValue: translator) {
      case .microsoftTranslator, .none:
        secret = .microsoftTranslator(secret: secretString)

      case .deepL:
        secret = .deepL(secret: secretString)
      }

      return TranslateOptions(
        paths: paths,
        subpathsToIgnore: subpathsToIgnore,
        secret: secret,
        sourceLocale: sourceLocale
      )
    }
    else {
      throw MungoError(
        source: .invalidUserInput,
        message: "Incomplete [update.translate] options provided, ignoring them all."
      )
    }
  }

  func tomlContents() -> String {
    var lines: [String] = ["[update.translate]"]

    lines.append("paths = \(paths)")
    lines.append("subpathsToIgnore = \(subpathsToIgnore)")
    switch secret {
    case let .deepL(secret):
      lines.append("secret = \"\(secret)\"")

    case let .microsoftTranslator(secret):
      lines.append("secret = \"\(secret)\"")
    }

    lines.append("sourceLocale = \"\(sourceLocale)\"")

    return lines.joined(separator: "\n")
  }
}
