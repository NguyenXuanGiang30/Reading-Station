package com.tramdoc.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Data
@Configuration
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    private String name = "Tram Doc";
    private final OAuth2 oauth2 = new OAuth2();
    private final Security security = new Security();
    private final Storage storage = new Storage();
    private final Firebase firebase = new Firebase();
    private final Notifications notifications = new Notifications();

    @Data
    public static class OAuth2 {
        private List<String> authorizedRedirectUris = new ArrayList<>();
    }

    @Data
    public static class Security {
        private boolean swaggerEnabled = true;
    }

    @Data
    public static class Storage {
        private Provider provider = Provider.LOCAL;
        private String localDirectory = "uploads";
        private long maxFileSizeBytes = 10 * 1024 * 1024L;
        private List<String> allowedContentTypes = List.of("image/jpeg", "image/png", "image/webp");
        private String publicBaseUrl;
        private final S3 s3 = new S3();

        public enum Provider {
            LOCAL,
            S3
        }

        @Data
        public static class S3 {
            private String endpoint;
            private String region;
            private String bucket;
            private String accessKey;
            private String secretKey;
            private boolean pathStyleAccess = true;
        }
    }

    @Data
    public static class Firebase {
        private boolean enabled;
        private String projectId;
        private String credentialsBase64;
    }

    @Data
    public static class Notifications {
        private String scheduleCron = "0 * * * * *";
        private String deliveryCron = "15 * * * * *";
    }
}
