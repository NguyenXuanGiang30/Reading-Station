package com.tramdoc.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tramdoc.entity.Book;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
public class OpenLibraryService {
    private static final Logger log = LoggerFactory.getLogger(OpenLibraryService.class);
    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public OpenLibraryService() {
        this.webClient = WebClient.builder().baseUrl("https://openlibrary.org/api").build();
        this.objectMapper = new ObjectMapper();
    }

    public Book getBookByIsbn(String isbn) {
        try {
            String response = webClient.get()
                    .uri(uriBuilder -> uriBuilder.path("/books")
                            .queryParam("bibkeys", "ISBN:" + isbn)
                            .queryParam("format", "json")
                            .queryParam("jscmd", "data")
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            JsonNode bookData = root.path("ISBN:" + isbn);

            if (bookData.isMissingNode() || bookData.isNull()) {
                return null;
            }

            String title = bookData.path("title").asText("");
            
            String author = "";
            JsonNode authorsNode = bookData.path("authors");
            if (authorsNode.isArray() && authorsNode.size() > 0) {
                author = authorsNode.get(0).path("name").asText("");
            }

            String publisher = "";
            JsonNode publishersNode = bookData.path("publishers");
            if (publishersNode.isArray() && publishersNode.size() > 0) {
                publisher = publishersNode.get(0).path("name").asText("");
            }

            String description = bookData.path("notes").asText("");
            if (description.isEmpty()) {
                // sometimes notes is an object in OpenLibrary
                JsonNode notesNode = bookData.path("notes");
                if (notesNode.isObject() && notesNode.has("value")) {
                    description = notesNode.path("value").asText("");
                }
            }
            
            String coverImageUrl = "";
            JsonNode coverNode = bookData.path("cover");
            if (!coverNode.isMissingNode() && !coverNode.isNull()) {
                coverImageUrl = coverNode.path("large").asText(
                                coverNode.path("medium").asText(""));
            }

            Integer pageCount = bookData.path("number_of_pages").asInt(0);

            String category = "";
            JsonNode subjectsNode = bookData.path("subjects");
            if (subjectsNode.isArray() && subjectsNode.size() > 0) {
                category = subjectsNode.get(0).path("name").asText("");
            }

            return Book.builder()
                    .title(title)
                    .author(author)
                    .isbn(isbn)
                    .description(description)
                    .publisher(publisher)
                    .pageCount(pageCount)
                    .coverImageUrl(coverImageUrl)
                    .category(category)
                    .language("vi")
                    .build();

        } catch (Exception e) {
            log.warn("OpenLibrary ISBN lookup failed for {}", isbn, e);
            return null;
        }
    }
}
