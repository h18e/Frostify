import Foundation
import os

/// Fragt Open Food Facts nach einem Barcode.
///
/// ## Rolle in der App
///
/// Der **eigene Katalog hat immer Vorrang**. Open Food Facts wird nur befragt,
/// wenn ein Code dort noch nicht steht. Was du danach im Formular anpasst, landet
/// beim Sichern in deinem Katalog – ab dem zweiten Scan desselben Produkts fragt
/// die App gar nicht mehr nach.
///
/// ## Umgang mit Fehlern
///
/// Jeder Fehler – kein Netz, Zeitüberschreitung, Produkt unbekannt, Dienst
/// überlastet – führt zum leeren Formular, nie zu einer Sackgasse. Der Grund wird
/// unterschieden, damit im Formular der passende Hinweis stehen kann.
///
/// ## Gegenüber dem Dienst
///
/// Open Food Facts bittet um eine aussagekräftige `User-Agent`-Kennung und
/// begrenzt die Last, nicht die vernünftige Nutzung. Ein Scan löst genau eine
/// Abfrage aus, und nur bei unbekannten Codes.
enum OpenFoodFactsService {
    enum LookupResult: Equatable {
        case found(ProductSuggestion)
        /// Der Dienst kennt den Code nicht.
        case notFound
        /// Kein Netz, Zeitüberschreitung oder der Dienst antwortet nicht.
        case unavailable
    }

    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "OpenFoodFacts")
    private static let host = "world.openfoodfacts.org"
    private static let fields = "product_name,product_name_de,product_name_fr,brands,quantity,categories_tags"
    private static let timeout: TimeInterval = 8

    static func lookup(barcode: String, session: URLSession = .shared) async -> LookupResult {
        let code = barcode.filter { $0.isLetter || $0.isNumber }
        guard !code.isEmpty, let url = makeURL(code: code) else { return .notFound }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 404 { return .notFound }
                guard http.statusCode == 200 else {
                    logger.info("Open Food Facts antwortet mit \(http.statusCode).")
                    return .unavailable
                }
            }
            guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
                  let suggestion = payload.product?.suggestion
            else {
                return .notFound
            }
            return .found(suggestion)
        } catch {
            logger.info("Open Food Facts nicht erreichbar: \(error.localizedDescription)")
            return .unavailable
        }
    }

    private static func makeURL(code: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/api/v2/product/\(code).json"
        components.queryItems = [URLQueryItem(name: "fields", value: fields)]
        return components.url
    }

    /// Open Food Facts bittet darum, dass sich Anwendungen zu erkennen geben.
    private static var userAgent: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Frostify/\(version) (iOS; https://github.com/h18e/Frostify)"
    }

    // MARK: - Antwort

    /// Bewusst ohne das Feld `status`: Dessen Typ ist über die Jahre nicht
    /// einheitlich geblieben, und ein einziges unerwartetes Feld liesse sonst die
    /// ganze Antwort scheitern. Ob etwas gefunden wurde, zeigt das Produkt selbst.
    private struct Payload: Decodable {
        let product: Product?
    }

    private struct Product: Decodable {
        let productName: String?
        let productNameDe: String?
        let productNameFr: String?
        let brands: String?
        let quantity: String?
        let categoriesTags: [String]?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case productNameDe = "product_name_de"
            case productNameFr = "product_name_fr"
            case brands
            case quantity
            case categoriesTags = "categories_tags"
        }

        /// Deutsch zuerst, dann der allgemeine Name, dann Französisch.
        var suggestion: ProductSuggestion? {
            let candidates = [productNameDe, productName, productNameFr]
            guard let name = candidates
                .compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
                .first(where: { !$0.isEmpty })
            else { return nil }

            let parsed = QuantityTextParser.parse(quantity)
            let brand = brands?
                .split(separator: ",")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return ProductSuggestion(
                name: name,
                brand: (brand?.isEmpty == false) ? brand : nil,
                quantity: parsed?.value,
                unit: parsed?.unit,
                category: FoodCategoryGuesser.category(fromTags: categoriesTags ?? [])
            )
        }
    }
}
