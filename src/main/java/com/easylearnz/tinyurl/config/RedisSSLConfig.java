package com.easylearnz.tinyurl.config;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.SslOptions;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;

import javax.net.ssl.TrustManagerFactory;
import java.io.InputStream;
import java.security.KeyStore;

@Configuration
@RequiredArgsConstructor
public class RedisSSLConfig {
    @Value("${redis.host}")
    private String host;
    @Value("${redis.port}")
    private int port;
    @Value("${redis.ssl.enabled:false}")
    private boolean sslEnabled;
    @Value("${redis.ssl.trust-store}")
    private Resource trustStore;
    @Value("${redis.ssl.trust-store-password}")
    private String trustStorePassword;
    private final ResourceLoader resourceLoader;

    @Bean
    RedisConnectionFactory redisConnectionFactory() throws Exception {
        // Implement RedisConnectionFactory creation with SSL configuration
        // using the provided properties.
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration(host, port);
        LettuceClientConfiguration.LettuceClientConfigurationBuilder builder = LettuceClientConfiguration.builder();
        if (sslEnabled) {
            TrustManagerFactory tmf = createTrustManagerFactory(trustStore, trustStorePassword);
            SslOptions sslOptions = SslOptions.builder()
                    .trustManager(tmf)
                    .build();
            ClientOptions clientOptions = ClientOptions.builder()
                    .sslOptions(sslOptions)
                    .build();
            builder.clientOptions(clientOptions).useSsl();
        }
        LettuceClientConfiguration lettuceClientConfiguration = builder.build();
        return new LettuceConnectionFactory(config, lettuceClientConfiguration);
    }
    private TrustManagerFactory createTrustManagerFactory(Resource resource, String password) throws Exception {
        KeyStore ks = KeyStore.getInstance("JKS");
        try (InputStream is = resource.getInputStream()) {
            ks.load(is, password.toCharArray());
        }
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(ks);
        return tmf;
    }
}
