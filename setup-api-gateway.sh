#!/bin/bash

# ─────────────────────────────────────────────
#  StyleKart — API Gateway Setup Script
#  Run from: /home/ayush/stylekart/
#  Usage: bash setup-api-gateway.sh
# ─────────────────────────────────────────────

set -e

BASE="api-gateway/src/main/java/com/stylekart/apigateway"
RESOURCES="api-gateway/src/main/resources"

echo "📁 Creating package directories..."
mkdir -p $BASE/filter
mkdir -p $BASE/config

# ─────────────────────────────────────────────
# Fix main application class
# ─────────────────────────────────────────────
echo "📝 Fixing main application class..."
mkdir -p $BASE
cat > $BASE/ApiGatewayApplication.java << 'EOF'
package com.stylekart.apigateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
EOF

# Remove old main class from zip artifact
rm -rf api-gateway/src/main/java/com/stylekart/api_gateway 2>/dev/null || true

# ─────────────────────────────────────────────
# application.yml
# ─────────────────────────────────────────────
echo "📝 Writing application.yml..."
rm -f $RESOURCES/application.properties
cat > $RESOURCES/application.yml << 'EOF'
server:
  port: 8080

spring:
  application:
    name: api-gateway
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: http://localhost:8081
          predicates:
            - Path=/api/auth/**
          filters:
            - StripPrefix=0

        - id: product-service
          uri: http://localhost:8082
          predicates:
            - Path=/api/products/**, /api/categories/**
          filters:
            - StripPrefix=0

      globalcors:
        corsConfigurations:
          '[/**]':
            allowedOrigins: "http://localhost:3000"
            allowedMethods:
              - GET
              - POST
              - PUT
              - DELETE
              - OPTIONS
            allowedHeaders: "*"
            allowCredentials: true

jwt:
  secret: 404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970

logging:
  level:
    org.springframework.cloud.gateway: DEBUG
EOF

# ─────────────────────────────────────────────
# filter/JwtAuthFilter.java
# ─────────────────────────────────────────────
echo "📝 Writing filter/JwtAuthFilter.java..."
cat > $BASE/filter/JwtAuthFilter.java << 'EOF'
package com.stylekart.apigateway.filter;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.Key;
import java.util.List;

@Component
public class JwtAuthFilter implements GlobalFilter, Ordered {

    @Value("${jwt.secret}")
    private String secret;

    // Public endpoints that do not require a token
    private static final List<String> PUBLIC_PATHS = List.of(
            "/api/auth/register",
            "/api/auth/login"
    );

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        String method = exchange.getRequest().getMethod().name();

        // Allow public auth endpoints
        if (PUBLIC_PATHS.stream().anyMatch(path::startsWith)) {
            return chain.filter(exchange);
        }

        // Allow public GET on products and categories
        if (method.equals("GET") &&
                (path.startsWith("/api/products") || path.startsWith("/api/categories"))) {
            return chain.filter(exchange);
        }

        // All other requests need a valid JWT
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        String token = authHeader.substring(7);

        try {
            Jwts.parserBuilder()
                    .setSigningKey(getSignKey())
                    .build()
                    .parseClaimsJws(token);
        } catch (JwtException e) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1;
    }

    private Key getSignKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
EOF

# ─────────────────────────────────────────────
# filter/LoggingFilter.java
# ─────────────────────────────────────────────
echo "📝 Writing filter/LoggingFilter.java..."
cat > $BASE/filter/LoggingFilter.java << 'EOF'
package com.stylekart.apigateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class LoggingFilter implements GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(LoggingFilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String method = exchange.getRequest().getMethod().name();
        String path = exchange.getRequest().getURI().getPath();

        log.info("Incoming request: {} {}", method, path);

        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            int statusCode = exchange.getResponse().getStatusCode() != null
                    ? exchange.getResponse().getStatusCode().value()
                    : 0;
            log.info("Response status: {} for {} {}", statusCode, method, path);
        }));
    }

    @Override
    public int getOrder() {
        return -2;
    }
}
EOF

# ─────────────────────────────────────────────
# pom.xml — add jjwt + spring cloud dependencies
# ─────────────────────────────────────────────
echo "📝 Updating pom.xml..."

# Add jjwt dependencies
sed -i 's|</dependencies>|  <dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-api</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-impl</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-jackson</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t</dependencies>|' api-gateway/pom.xml

# Add spring cloud dependency management
sed -i 's|</dependencyManagement>|  <dependency>\n\t\t\t<groupId>org.springframework.cloud</groupId>\n\t\t\t<artifactId>spring-cloud-dependencies</artifactId>\n\t\t\t<version>2023.0.0</version>\n\t\t\t<type>pom</type>\n\t\t\t<scope>import</scope>\n\t\t</dependency>\n\t\t</dependencies>\n\t</dependencyManagement>|' api-gateway/pom.xml 2>/dev/null || \
cat >> api-gateway/pom.xml << 'POMEOF'

<!-- Spring Cloud BOM added by setup script -->
POMEOF

echo ""
echo "✅ API Gateway setup complete!"
echo ""
echo "Next steps:"
echo "  1. Make sure user-service  is running on :8081"
echo "  2. Make sure product-service is running on :8082"
echo "  3. cd api-gateway && ./mvnw spring-boot:run"
echo "  4. All requests now go through :8080"
echo ""
echo "Test routes:"
echo "  POST http://localhost:8080/api/auth/register"
echo "  POST http://localhost:8080/api/auth/login"
echo "  GET  http://localhost:8080/api/products"
