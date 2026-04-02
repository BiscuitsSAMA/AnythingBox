import Foundation

// MARK: - 消息结构（用于 LLM 调用，独立于 SwiftData 模型）
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: ChatRole
    var content: String

    init(role: ChatRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
}

// MARK: - 分析任务类型
enum AnalysisTask {
    case proofread          // 文字校对
    case autoTitle          // 自动生成标题
    case suggestCategory    // 建议分类
    case summarize          // 摘要
    case sentiment          // 情绪分析
    case wordStats          // 字数/词频统计（本地完成，不需要 LLM）

    var systemPrompt: String {
        switch self {
        case .proofread:
            return "你是一个专业的文字编辑。请对用户输入的文字进行校对，指出错别字、语法问题，并给出修改建议。用简洁的格式回复。"
        case .autoTitle:
            return "请根据内容生成一个简短有力的标题（10字以内），只输出标题本身，不要有任何额外说明。"
        case .suggestCategory:
            return "请根据内容判断它最适合哪个分类：日记、工作、想法、收藏、学习，或给出其他建议。只输出分类名称，不要解释。"
        case .summarize:
            return "请用2-3句话简洁地总结以下内容的核心要点。"
        case .sentiment:
            return "请分析以下内容的情绪倾向，用1-2句话描述，并给出一个代表情绪的 emoji。"
        case .wordStats:
            return ""
        }
    }
}

// MARK: - LLM 服务协议
protocol LLMServiceProtocol: ObservableObject {
    var isAvailable: Bool { get }
    var modelName: String { get }
    var isLoading: Bool { get }

    /// 流式对话，返回 AsyncStream 逐字输出
    func chat(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error>

    /// 单次分析任务
    func analyze(text: String, task: AnalysisTask) async throws -> String

    /// 加载模型
    func loadModel() async throws
}

// MARK: - LLM 错误
enum LLMError: LocalizedError {
    case modelNotLoaded
    case modelNotFound(String)
    case inferenceError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "模型未加载，请先在设置中下载并加载模型"
        case .modelNotFound(let name): return "找不到模型：\(name)"
        case .inferenceError(let msg): return "推理出错：\(msg)"
        case .cancelled: return "已取消"
        }
    }
}

// MARK: - Mock 实现（开发调试用）
@MainActor
final class MockLLMService: LLMServiceProtocol {
    @Published var isAvailable: Bool = true
    @Published var isLoading: Bool = false
    let modelName: String = "Mock-LLM (调试模式)"

    private let responses: [String] = [
        "我理解你的感受。每天记录生活中的点滴，是一种很好的自我关照方式。",
        "听起来今天发生了不少事情呢。能分享更多吗？",
        "你的想法很有趣！我觉得这个角度值得深入探索。",
        "谢谢你愿意把这些告诉我。你最近还好吗？",
        "这件事确实需要好好思考。我们可以一起分析一下。",
        "你写得很好！文字流畅，情感真实。继续保持这种写作习惯。",
    ]

    func chat(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error> {
        let response = responses.randomElement() ?? "嗯，我在听。"
        return AsyncThrowingStream { continuation in
            Task {
                for char in response {
                    try? await Task.sleep(nanoseconds: 40_000_000) // 40ms per char
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }

    func analyze(text: String, task: AnalysisTask) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        switch task {
        case .proofread:
            return "✅ 文字通顺，未发现明显错误。\n\n**建议**：第2句可以考虑拆分，增加可读性。"
        case .autoTitle:
            return String(text.prefix(12))
        case .suggestCategory:
            return "日记"
        case .summarize:
            return "这段文字记录了作者的日常思考和感受，表达了对生活的观察与感悟。"
        case .sentiment:
            return "😊 整体情绪积极，带有一丝思考和反省。"
        case .wordStats:
            return ""
        }
    }

    func loadModel() async throws {
        isLoading = true
        try await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
}

// MARK: - Ollama 实现（本地运行 Ollama 服务时使用）
// 用法：在终端运行 `ollama run qwen2.5:4b`，然后在 App 设置中选择 Ollama 模式
@MainActor
final class OllamaLLMService: LLMServiceProtocol {
    @Published var isAvailable: Bool = false
    @Published var isLoading: Bool = false

    var modelName: String
    var baseURL: String

    init(modelName: String = "qwen2.5:4b", baseURL: String = "http://localhost:11434") {
        self.modelName = modelName
        self.baseURL = baseURL
    }

    func loadModel() async throws {
        // 检查 Ollama 是否在运行
        guard let url = URL(string: "\(baseURL)/api/tags") else { return }
        let (_, response) = try await URLSession.shared.data(from: url)
        isAvailable = (response as? HTTPURLResponse)?.statusCode == 200
    }

    func chat(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw LLMError.modelNotLoaded
        }

        let body: [String: Any] = [
            "model": modelName,
            "stream": true,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard !line.isEmpty,
                              let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let content = message["content"] as? String else { continue }
                        continuation.yield(content)
                        if json["done"] as? Bool == true { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func analyze(text: String, task: AnalysisTask) async throws -> String {
        let messages = [
            ChatMessage(role: .system, content: task.systemPrompt),
            ChatMessage(role: .user, content: text)
        ]
        var result = ""
        for try await chunk in try await chat(messages: messages) {
            result += chunk
        }
        return result
    }
}
