package com.tramdoc.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tramdoc.dto.request.AddUserBookRequest;
import com.tramdoc.dto.request.ChatRequest;
import com.tramdoc.dto.response.ActionResult;
import com.tramdoc.dto.response.ChatResponse;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.entity.Note;
import com.tramdoc.entity.UserBook;
import com.tramdoc.repository.NoteRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class OllamaService {

    private static final Logger log = LoggerFactory.getLogger(OllamaService.class);

    private final WebClient webClient;
    private final ObjectMapper objectMapper;
    private final NoteRepository noteRepository;

    @Autowired
    private BookService bookService;

    @Autowired
    private UserBookService userBookService;

    @Value("${ollama.model:qwen2.5:3b}")
    private String model;

    @Value("${ollama.timeout:60000}")
    private long timeoutMs;

    private static final String TOOL_SYSTEM_PROMPT = """
            Bạn là trợ lý đọc sách thân thiện tên "Trạm Đọc AI". Hãy trả lời bằng tiếng Việt, ngắn gọn và hữu ích.

            Nhiệm vụ chính:
            - Gợi ý sách hay cho người dùng
            - Trò chuyện về sách, đọc sách, văn học
            - Giúp quản lý thư viện sách cá nhân

            Khi người dùng muốn TÌM KIẾM sách cụ thể theo tên, hãy dùng lệnh:
            <<<TOOL_CALL>>>{"tool":"search_book_name","params":{"query":"tên sách"}}<<<END_TOOL>>>

            Khi người dùng cung cấp mã ISBN, hãy dùng lệnh:
            <<<TOOL_CALL>>>{"tool":"search_book_isbn","params":{"isbn":"mã isbn"}}<<<END_TOOL>>>

            Khi người dùng muốn THÊM sách vào thư viện (cần có bookId), hãy dùng lệnh:
            <<<TOOL_CALL>>>{"tool":"add_book_to_library","params":{"bookId":123}}<<<END_TOOL>>>

            Lưu ý: Chỉ dùng lệnh khi thực sự cần thiết. Với các câu hỏi thông thường như gợi ý sách, hỏi về nội dung sách, hoặc trò chuyện, hãy trả lời trực tiếp bằng văn bản bình thường.
            """;

    public OllamaService(
            @Value("${ollama.base-url:http://localhost:11434}") String baseUrl,
            ObjectMapper objectMapper,
            NoteRepository noteRepository) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .build();
        this.objectMapper = objectMapper;
        this.noteRepository = noteRepository;
    }

    // ── Public API ─────────────────────────────────────────────────

    public boolean isAvailable() {
        try {
            String response = webClient.get()
                    .uri("/api/tags")
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(5))
                    .block();
            return response != null;
        } catch (Exception e) {
            log.warn("Ollama is not available: {}", e.getMessage());
            return false;
        }
    }

    public String getModel() {
        return model;
    }

    /**
     * Chat with AI using tool calling — the main agent method
     */
    public ChatResponse chatWithTools(ChatRequest request, Long userId) {
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", TOOL_SYSTEM_PROMPT));

        // Add history
        if (request.getHistory() != null) {
            for (ChatRequest.ChatMessage msg : request.getHistory()) {
                messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", request.getMessage()));

        // Step 1: Get AI response (may contain tool call)
        String aiReply = callOllamaChat(messages);
        List<ActionResult> actions = new ArrayList<>();

        // Step 2: Check for tool call
        if (aiReply.contains("<<<TOOL_CALL>>>")) {
            try {
                String toolJson = extractToolCall(aiReply);
                JsonNode toolNode = objectMapper.readTree(toolJson);
                String toolName = toolNode.path("tool").asText();
                JsonNode params = toolNode.path("params");

                // Execute tool
                ActionResult result = executeTool(toolName, params, userId);
                actions.add(result);

                // Step 3: Send tool result back to AI for natural language response
                messages.add(Map.of("role", "assistant", "content", aiReply));
                messages.add(Map.of("role", "user", "content",
                        "Kết quả hành động: " + objectMapper.writeValueAsString(result) +
                        "\nHãy tóm tắt kết quả bằng tiếng Việt thân thiện cho người dùng. KHÔNG dùng <<<TOOL_CALL>>> nữa."));

                aiReply = callOllamaChat(messages);
            } catch (Exception e) {
                log.error("Tool execution error: {}", e.getMessage());
                // Remove tool call markers from reply
                aiReply = aiReply.replaceAll("<<<TOOL_CALL>>>.*<<<END_TOOL>>>", "").trim();
                if (aiReply.isEmpty()) {
                    aiReply = "Xin lỗi, tôi không thể thực hiện hành động này. Vui lòng thử lại.";
                }
            }
        }

        // Clean any remaining tool markers
        aiReply = aiReply.replaceAll("<<<TOOL_CALL>>>.*<<<END_TOOL>>>", "").trim();

        return ChatResponse.builder()
                .reply(aiReply)
                .model(model)
                .actions(actions.isEmpty() ? null : actions)
                .build();
    }

    /**
     * Simple chat without tools (backward compatible)
     */
    public ChatResponse chat(ChatRequest request) {
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content",
                "Bạn là trợ lý đọc sách thông minh của ứng dụng Trạm Đọc. " +
                "Hãy trả lời ngắn gọn, thân thiện bằng tiếng Việt."));

        if (request.getHistory() != null) {
            for (ChatRequest.ChatMessage msg : request.getHistory()) {
                messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", request.getMessage()));

        String reply = callOllamaChat(messages);
        return ChatResponse.builder().reply(reply).model(model).build();
    }

    // ── Tool Execution ─────────────────────────────────────────────

    private ActionResult executeTool(String toolName, JsonNode params, Long userId) {
        try {
            return switch (toolName) {
                case "search_book_isbn" -> executeSearchByIsbn(params);
                case "search_book_name" -> executeSearchByName(params);
                case "add_book_to_library" -> executeAddToLibrary(params, userId);
                default -> ActionResult.builder()
                        .tool(toolName).success(false)
                        .message("Tool không được hỗ trợ: " + toolName)
                        .build();
            };
        } catch (Exception e) {
            log.error("Tool {} failed: {}", toolName, e.getMessage());
            return ActionResult.builder()
                    .tool(toolName).success(false)
                    .message("Lỗi: " + e.getMessage())
                    .build();
        }
    }

    private ActionResult executeSearchByIsbn(JsonNode params) {
        String isbn = params.path("isbn").asText("");
        if (isbn.isEmpty()) {
            return ActionResult.builder()
                    .tool("search_book_isbn").success(false)
                    .message("Thiếu mã ISBN").build();
        }

        try {
            Book book = bookService.getBookByIsbn(isbn);
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("bookId", book.getId());
            data.put("title", book.getTitle());
            data.put("author", book.getAuthor());
            data.put("isbn", book.getIsbn());
            data.put("pageCount", book.getPageCount());
            data.put("publisher", book.getPublisher());
            data.put("coverImageUrl", book.getCoverImageUrl());
            data.put("description", book.getDescription());
            data.put("category", book.getCategory());

            return ActionResult.builder()
                    .tool("search_book_isbn").success(true)
                    .message("Tìm thấy sách: " + book.getTitle())
                    .data(data).build();
        } catch (Exception e) {
            return ActionResult.builder()
                    .tool("search_book_isbn").success(false)
                    .message("Không tìm thấy sách với ISBN: " + isbn)
                    .build();
        }
    }

    private ActionResult executeSearchByName(JsonNode params) {
        String query = params.path("query").asText("");
        if (query.isEmpty()) {
            return ActionResult.builder()
                    .tool("search_book_name").success(false)
                    .message("Thiếu từ khóa tìm kiếm").build();
        }

        List<Book> books = bookService.searchBooks(query);
        if (books.isEmpty()) {
            return ActionResult.builder()
                    .tool("search_book_name").success(false)
                    .message("Không tìm thấy sách với từ khóa: " + query)
                    .build();
        }

        List<Map<String, Object>> bookList = new ArrayList<>();
        for (Book book : books.subList(0, Math.min(books.size(), 5))) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("bookId", book.getId());
            item.put("title", book.getTitle());
            item.put("author", book.getAuthor());
            item.put("isbn", book.getIsbn());
            item.put("coverImageUrl", book.getCoverImageUrl());
            item.put("pageCount", book.getPageCount());
            bookList.add(item);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("books", bookList);
        data.put("totalFound", books.size());

        return ActionResult.builder()
                .tool("search_book_name").success(true)
                .message("Tìm thấy " + books.size() + " cuốn sách")
                .data(data).build();
    }

    private ActionResult executeAddToLibrary(JsonNode params, Long userId) {
        long bookId = params.path("bookId").asLong(0);
        if (bookId == 0) {
            return ActionResult.builder()
                    .tool("add_book_to_library").success(false)
                    .message("Thiếu bookId. Hãy tìm sách trước.").build();
        }

        try {
            Book book = bookService.getBookById(bookId);
            AddUserBookRequest addRequest = new AddUserBookRequest();
            addRequest.setBookId(bookId);
            addRequest.setStatus(UserBook.BookStatus.WANT_TO_READ);

            userBookService.addUserBook(addRequest, userId);

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("bookId", book.getId());
            data.put("title", book.getTitle());
            data.put("author", book.getAuthor());
            data.put("status", "WANT_TO_READ");

            return ActionResult.builder()
                    .tool("add_book_to_library").success(true)
                    .message("Đã thêm \"" + book.getTitle() + "\" vào thư viện")
                    .data(data).build();
        } catch (Exception e) {
            return ActionResult.builder()
                    .tool("add_book_to_library").success(false)
                    .message("Không thể thêm sách: " + e.getMessage())
                    .build();
        }
    }

    // ── Flashcard & Summarize (unchanged) ──────────────────────────

    public List<FlashcardResponse> generateFlashcardsFromNote(Long noteId, int count) {
        Note note = noteRepository.findById(noteId)
                .orElseThrow(() -> new RuntimeException("Note not found: " + noteId));

        String noteContent = note.getContent();
        String noteTitle = note.getTitle() != null ? note.getTitle() : "";

        String prompt = String.format(
                "Dựa trên ghi chú sau đây, hãy tạo %d flashcard (thẻ ghi nhớ) để ôn tập. " +
                "Mỗi flashcard gồm một câu hỏi (question) và câu trả lời (answer). " +
                "Trả về KẾT QUẢ DƯỚI DẠNG JSON ARRAY duy nhất, không thêm text nào khác. " +
                "Format: [{\"question\":\"...\",\"answer\":\"...\"}]\n\n" +
                "Tiêu đề: %s\n" +
                "Nội dung: %s",
                count, noteTitle, noteContent
        );

        return callOllamaForFlashcards(prompt, note.getBook().getId());
    }

    public List<FlashcardResponse> generateFlashcardsFromBook(Long bookId, Long userId, int count) {
        List<Note> notes = noteRepository.findByBook_IdOrderByPageNumberAsc(bookId);
        notes = notes.stream()
                .filter(n -> n.getUser().getId().equals(userId))
                .collect(Collectors.toList());

        if (notes.isEmpty()) {
            throw new RuntimeException("Không tìm thấy ghi chú nào cho cuốn sách này.");
        }

        StringBuilder combined = new StringBuilder();
        for (Note note : notes) {
            if (note.getTitle() != null) {
                combined.append("## ").append(note.getTitle()).append("\n");
            }
            combined.append(note.getContent()).append("\n\n");
        }

        String prompt = String.format(
                "Dựa trên các ghi chú sau đây, hãy tạo %d flashcard để ôn tập. " +
                "Trả về JSON ARRAY: [{\"question\":\"...\",\"answer\":\"...\"}]\n\n" +
                "Ghi chú:\n%s",
                count, combined
        );

        return callOllamaForFlashcards(prompt, bookId);
    }

    public String summarizeNotes(Long bookId, Long userId) {
        List<Note> notes = noteRepository.findByBook_IdOrderByPageNumberAsc(bookId);
        notes = notes.stream()
                .filter(n -> n.getUser().getId().equals(userId))
                .collect(Collectors.toList());

        if (notes.isEmpty()) {
            throw new RuntimeException("Không tìm thấy ghi chú nào cho cuốn sách này.");
        }

        StringBuilder combined = new StringBuilder();
        for (Note note : notes) {
            if (note.getTitle() != null) {
                combined.append("## ").append(note.getTitle()).append("\n");
            }
            combined.append(note.getContent()).append("\n\n");
        }

        String prompt = "Hãy tóm tắt các ghi chú sau thành key takeaways ngắn gọn bằng tiếng Việt.\n\n" +
                "Ghi chú:\n" + combined;

        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("prompt", prompt);
        body.put("stream", false);

        try {
            String response = webClient.post()
                    .uri("/api/generate")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofMillis(timeoutMs))
                    .block();

            JsonNode root = objectMapper.readTree(response);
            return root.path("response").asText("Không thể tóm tắt.");
        } catch (Exception e) {
            log.error("Ollama summarize error: {}", e.getMessage());
            throw new RuntimeException("Không thể kết nối với AI.");
        }
    }

    // ── Private helpers ────────────────────────────────────────────

    private String callOllamaChat(List<Map<String, String>> messages) {
        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("messages", messages);
        body.put("stream", false);

        try {
            String response = webClient.post()
                    .uri("/api/chat")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofMillis(timeoutMs))
                    .block();

            JsonNode root = objectMapper.readTree(response);
            return root.path("message").path("content").asText("");
        } catch (Exception e) {
            log.error("Ollama chat error: {}", e.getMessage());
            throw new RuntimeException("Không thể kết nối với AI. Vui lòng kiểm tra Ollama đang chạy.");
        }
    }

    private List<FlashcardResponse> callOllamaForFlashcards(String prompt, Long bookId) {
        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("prompt", prompt);
        body.put("stream", false);

        try {
            String response = webClient.post()
                    .uri("/api/generate")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofMillis(timeoutMs))
                    .block();

            JsonNode root = objectMapper.readTree(response);
            String aiOutput = root.path("response").asText("");
            String jsonArray = extractJsonArray(aiOutput);
            List<Map<String, String>> cards = objectMapper.readValue(
                    jsonArray, new TypeReference<List<Map<String, String>>>() {});

            List<FlashcardResponse> result = new ArrayList<>();
            for (Map<String, String> card : cards) {
                result.add(FlashcardResponse.builder()
                        .bookId(bookId)
                        .question(card.getOrDefault("question", ""))
                        .answer(card.getOrDefault("answer", ""))
                        .deckName("AI Generated")
                        .build());
            }
            return result;
        } catch (Exception e) {
            log.error("Ollama flashcard generation error: {}", e.getMessage());
            throw new RuntimeException("Không thể tạo flashcard bằng AI.");
        }
    }

    private String extractToolCall(String text) {
        int start = text.indexOf("<<<TOOL_CALL>>>") + "<<<TOOL_CALL>>>".length();
        int end = text.indexOf("<<<END_TOOL>>>");
        if (start > 14 && end > start) {
            return text.substring(start, end).trim();
        }
        throw new RuntimeException("Invalid tool call format");
    }

    private String extractJsonArray(String text) {
        int start = text.indexOf('[');
        int end = text.lastIndexOf(']');
        if (start != -1 && end != -1 && end > start) {
            return text.substring(start, end + 1);
        }
        throw new RuntimeException("AI không trả về đúng format JSON.");
    }
}
