package com.tramdoc.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tramdoc.entity.Book;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.web.util.UriComponentsBuilder;

@Service
public class GoogleBooksService {

    @Value("${google.books.api.url}")
    private String apiUrl;

    @Value("${google.books.api.key:}")
    private String apiKey;

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public GoogleBooksService() {
        this.webClient = WebClient.builder().build();
        this.objectMapper = new ObjectMapper();
    }

    public List<Book> searchBooks(String query, int maxResults) {
        try {
            String uri = UriComponentsBuilder.fromHttpUrl(apiUrl)
                    .queryParam("q", query)
                    .queryParam("maxResults", maxResults)
                    .queryParamIfPresent("key", Optional.ofNullable(apiKey).filter(k -> !k.isEmpty()))
                    .build()
                    .toUriString();

            String response = webClient.get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            return parseSearchResponse(response);
        } catch (Exception e) {
            System.err.println("Error searching books: " + e.getMessage());
            if (e instanceof org.springframework.web.reactive.function.client.WebClientResponseException) {
                System.err.println("Response body: " +
                        ((org.springframework.web.reactive.function.client.WebClientResponseException) e)
                                .getResponseBodyAsString());
            }
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    public Book getBookByIsbn(String isbn) {
        try {
            String uri = UriComponentsBuilder.fromHttpUrl(apiUrl)
                    .queryParam("q", "isbn:" + isbn)
                    .queryParamIfPresent("key", Optional.ofNullable(apiKey).filter(k -> !k.isEmpty()))
                    .build()
                    .toUriString();

            String response = webClient.get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            List<Book> books = parseSearchResponse(response);
            return books.isEmpty() ? null : books.get(0);
        } catch (Exception e) {
            System.err.println("Error fetching book by ISBN: " + e.getMessage());
            if (e instanceof org.springframework.web.reactive.function.client.WebClientResponseException) {
                System.err.println("Response body: " +
                        ((org.springframework.web.reactive.function.client.WebClientResponseException) e)
                                .getResponseBodyAsString());
            }
            e.printStackTrace();
            return null;
        }
    }

    private List<Book> parseSearchResponse(String jsonResponse) {
        List<Book> books = new ArrayList<>();
        try {
            JsonNode root = objectMapper.readTree(jsonResponse);
            JsonNode items = root.path("items");

            if (items.isArray()) {
                for (JsonNode item : items) {
                    Book book = parseBookItem(item);
                    if (book != null) {
                        books.add(book);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return books;
    }

    private Book parseBookItem(JsonNode item) {
        try {
            JsonNode volumeInfo = item.path("volumeInfo");

            String title = volumeInfo.path("title").asText("");
            JsonNode authorsNode = volumeInfo.path("authors");
            String author = authorsNode.isArray() && authorsNode.size() > 0
                    ? authorsNode.get(0).asText("")
                    : "";

            JsonNode industryIdentifiers = volumeInfo.path("industryIdentifiers");
            String isbn = "";
            for (JsonNode identifier : industryIdentifiers) {
                String type = identifier.path("type").asText("");
                if (type.equals("ISBN_13") || type.equals("ISBN_10")) {
                    isbn = identifier.path("identifier").asText("");
                    break;
                }
            }

            String description = volumeInfo.path("description").asText("");
            String publisher = volumeInfo.path("publisher").asText("");
            String publishedDate = volumeInfo.path("publishedDate").asText("");
            Integer pageCount = volumeInfo.path("pageCount").asInt(0);

            JsonNode imageLinks = volumeInfo.path("imageLinks");
            String coverImageUrl = imageLinks.path("thumbnail").asText("")
                    .replace("http://", "https://");

            String category = "";
            JsonNode categories = volumeInfo.path("categories");
            if (categories.isArray() && categories.size() > 0) {
                category = categories.get(0).asText("");
            }

            LocalDate publishedDateParsed = null;
            if (!publishedDate.isEmpty()) {
                try {
                    if (publishedDate.length() == 4) {
                        publishedDateParsed = LocalDate.parse(publishedDate + "-01-01");
                    } else {
                        publishedDateParsed = LocalDate.parse(publishedDate,
                                DateTimeFormatter.ISO_DATE);
                    }
                } catch (Exception e) {
                    // Ignore date parsing errors
                }
            }

            return Book.builder()
                    .title(title)
                    .author(author)
                    .isbn(isbn)
                    .description(description)
                    .publisher(publisher)
                    .publishedDate(publishedDateParsed)
                    .pageCount(pageCount)
                    .coverImageUrl(coverImageUrl)
                    .category(category)
                    .googleBooksId(item.path("id").asText(""))
                    .language("vi")
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
