import LillyUtilityCLI
import MarkdownGenerator

extension LillyTogetherReleaseType: NestedDocument {
	public var title: String { "LillyTogether Release Types" }
	public var description: String { "This section contains the release types of LillyTogether." }
}

extension LillyTogetherReleaseType: DocumentGeneratable {
    public static func generateTypeContents(type: FileType = .markdown) throws -> String {
        guard type == .markdown else {
            throw FileType.Error.unsupported(type: type)
        }
		var headers = ["Release Type", "App Name", "Store Market", "Purpose", "Xcode Scheme", "Xcode Configuration"]
		var data: [[String]] = [
			LillyTogetherReleaseType.allCases.map { $0.rawValue },
			LillyTogetherReleaseType.allCases.map { $0.name },
			LillyTogetherReleaseType.allCases.map { $0.market.rawValue },
			LillyTogetherReleaseType.allCases.map { $0.purpose.rawValue },
			LillyTogetherReleaseType.allCases.map { $0.scheme },
			LillyTogetherReleaseType.allCases.map { $0.configuration },
		]
		LillyTogetherReleaseType.allBackendServiceTypes.forEach { type in
			headers.append(String(describing: type))
			data.append(
				LillyTogetherReleaseType.allCases.map { 
					if let service = $0.backendService(type: type) {
						return String(describing: service)
					} else {
						return "N/A"
					}
				}
			)
		}
		let table = MarkdownTable(headers: headers, data: transpose(data, defaultValue: ""))
		
		return table.markdown
	}

	// TODO: create a `Matrix` helper class
	private static func transpose<T>(_ input: [[T]], defaultValue: T) -> [[T]] {
		let columns = input.count
		let rows = input.reduce(0) { max($0, $1.count) }

		return (0 ..< rows).reduce(into: []) { result, row in
			result.append((0 ..< columns).reduce(into: []) { result, column in
				result.append(row < input[column].count ? input[column][row] : defaultValue)
			})
		}
	}
}
