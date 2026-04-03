#!/bin/bash

# ─────────────────────────────────────────────
#  StyleKart — Payment Service Setup Script
#  Run from: /home/ayush/stylekart/
#  Usage: bash setup-payment-service.sh
# ─────────────────────────────────────────────

set -e

BASE="payment-service/src/main/java/com/stylekart/paymentservice"
RESOURCES="payment-service/src/main/resources"

echo "📁 Creating package directories..."
mkdir -p $BASE/controller
mkdir -p $BASE/service
mkdir -p $BASE/repository
mkdir -p $BASE/model
mkdir -p $BASE/dto
mkdir -p $BASE/security
mkdir -p $BASE/exception
mkdir -p $BASE/config
mkdir -p $BASE/client

# ─────────────────────────────────────────────
# Fix main application class
# ─────────────────────────────────────────────
echo "📝 Fixing main application class..."
cat > $BASE/PaymentServiceApplication.java << 'EOF'
package com.stylekart.paymentservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class PaymentServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(PaymentServiceApplication.class, args);
    }
}
EOF

rm -rf payment-service/src/main/java/com/stylekart/payment_service 2>/dev/null || true

# ─────────────────────────────────────────────
# application.yml
# ─────────────────────────────────────────────
echo "📝 Writing application.yml..."
rm -f $RESOURCES/application.properties
cat > $RESOURCES/application.yml << 'EOF'
server:
  port: 8084

spring:
  application:
    name: payment-service
  datasource:
    url: jdbc:postgresql://localhost:5432/stylekart_payments
    username: postgres
    password: postgres
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true

jwt:
  secret: 404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970

services:
  order-service:
    url: http://localhost:8083
EOF

# ─────────────────────────────────────────────
# model/PaymentStatus.java
# ─────────────────────────────────────────────
echo "📝 Writing models..."
cat > $BASE/model/PaymentStatus.java << 'EOF'
package com.stylekart.paymentservice.model;

public enum PaymentStatus {
    PENDING,
    SUCCESS,
    FAILED,
    REFUNDED
}
EOF

# ─────────────────────────────────────────────
# model/PaymentMethod.java
# ─────────────────────────────────────────────
cat > $BASE/model/PaymentMethod.java << 'EOF'
package com.stylekart.paymentservice.model;

public enum PaymentMethod {
    CREDIT_CARD,
    DEBIT_CARD,
    UPI,
    NET_BANKING,
    WALLET
}
EOF

# ─────────────────────────────────────────────
# model/Payment.java
# ─────────────────────────────────────────────
cat > $BASE/model/Payment.java << 'EOF'
package com.stylekart.paymentservice.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String transactionId;

    @Column(nullable = false)
    private Long orderId;

    @Column(nullable = false)
    private String userEmail;

    @Column(nullable = false)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentMethod paymentMethod;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus status;

    @Column
    private String failureReason;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
EOF

# ─────────────────────────────────────────────
# repository/PaymentRepository.java
# ─────────────────────────────────────────────
echo "📝 Writing repository..."
cat > $BASE/repository/PaymentRepository.java << 'EOF'
package com.stylekart.paymentservice.repository;

import com.stylekart.paymentservice.model.Payment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Optional<Payment> findByTransactionId(String transactionId);
    Optional<Payment> findByOrderId(Long orderId);
    List<Payment> findByUserEmailOrderByCreatedAtDesc(String userEmail);
}
EOF

# ─────────────────────────────────────────────
# dto/PaymentRequest.java
# ─────────────────────────────────────────────
echo "📝 Writing DTOs..."
cat > $BASE/dto/PaymentRequest.java << 'EOF'
package com.stylekart.paymentservice.dto;

import com.stylekart.paymentservice.model.PaymentMethod;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PaymentRequest {

    @NotNull(message = "Order ID is required")
    private Long orderId;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;
}
EOF

# ─────────────────────────────────────────────
# dto/PaymentResponse.java
# ─────────────────────────────────────────────
cat > $BASE/dto/PaymentResponse.java << 'EOF'
package com.stylekart.paymentservice.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentResponse {
    private Long id;
    private String transactionId;
    private Long orderId;
    private String userEmail;
    private BigDecimal amount;
    private String paymentMethod;
    private String status;
    private String failureReason;
    private LocalDateTime createdAt;
}
EOF

# ─────────────────────────────────────────────
# dto/OrderResponse.java (internal use)
# ─────────────────────────────────────────────
cat > $BASE/dto/OrderResponse.java << 'EOF'
package com.stylekart.paymentservice.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class OrderResponse {
    private Long id;
    private String userEmail;
    private String status;
    private BigDecimal totalAmount;
}
EOF

# ─────────────────────────────────────────────
# exception classes
# ─────────────────────────────────────────────
echo "📝 Writing exceptions..."
cat > $BASE/exception/PaymentNotFoundException.java << 'EOF'
package com.stylekart.paymentservice.exception;

public class PaymentNotFoundException extends RuntimeException {
    public PaymentNotFoundException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/PaymentAlreadyExistsException.java << 'EOF'
package com.stylekart.paymentservice.exception;

public class PaymentAlreadyExistsException extends RuntimeException {
    public PaymentAlreadyExistsException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/OrderServiceException.java << 'EOF'
package com.stylekart.paymentservice.exception;

public class OrderServiceException extends RuntimeException {
    public OrderServiceException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/GlobalExceptionHandler.java << 'EOF'
package com.stylekart.paymentservice.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(PaymentNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentNotFound(PaymentNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(PaymentAlreadyExistsException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentAlreadyExists(PaymentAlreadyExistsException ex) {
        return buildResponse(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(OrderServiceException.class)
    public ResponseEntity<Map<String, Object>> handleOrderService(OrderServiceException ex) {
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors()
                .stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .findFirst()
                .orElse("Validation failed");
        return buildResponse(HttpStatus.BAD_REQUEST, message);
    }

    private ResponseEntity<Map<String, Object>> buildResponse(HttpStatus status, String message) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", LocalDateTime.now().toString());
        body.put("status", status.value());
        body.put("error", message);
        return new ResponseEntity<>(body, status);
    }
}
EOF

# ─────────────────────────────────────────────
# client/OrderServiceClient.java
# ─────────────────────────────────────────────
echo "📝 Writing OrderServiceClient..."
cat > $BASE/client/OrderServiceClient.java << 'EOF'
package com.stylekart.paymentservice.client;

import com.stylekart.paymentservice.dto.OrderResponse;
import com.stylekart.paymentservice.exception.OrderServiceException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
@RequiredArgsConstructor
public class OrderServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.order-service.url}")
    private String orderServiceUrl;

    public OrderResponse getOrderById(Long orderId, String token) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + token);
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<OrderResponse> response = restTemplate.exchange(
                    orderServiceUrl + "/api/orders/" + orderId,
                    HttpMethod.GET,
                    entity,
                    OrderResponse.class
            );
            return response.getBody();
        } catch (Exception e) {
            throw new OrderServiceException("Failed to fetch order with id: " + orderId);
        }
    }

    public void updateOrderStatus(Long orderId, String status, String token) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + token);
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            restTemplate.exchange(
                    orderServiceUrl + "/api/orders/" + orderId + "/status?status=" + status,
                    HttpMethod.PATCH,
                    entity,
                    Void.class
            );
        } catch (Exception e) {
            // log but don't fail payment if status update fails
        }
    }
}
EOF

# ─────────────────────────────────────────────
# config/RestTemplateConfig.java
# ─────────────────────────────────────────────
echo "📝 Writing config..."
cat > $BASE/config/RestTemplateConfig.java << 'EOF'
package com.stylekart.paymentservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
EOF

# ─────────────────────────────────────────────
# security/JwtUtil.java
# ─────────────────────────────────────────────
echo "📝 Writing security..."
cat > $BASE/security/JwtUtil.java << 'EOF'
package com.stylekart.paymentservice.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.function.Function;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public boolean isTokenValid(String token) {
        try {
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        return claimsResolver.apply(extractAllClaims(token));
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSignKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    private Key getSignKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
EOF

cat > $BASE/security/JwtAuthFilter.java << 'EOF'
package com.stylekart.paymentservice.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String jwt = authHeader.substring(7);

        if (jwtUtil.isTokenValid(jwt) && SecurityContextHolder.getContext().getAuthentication() == null) {
            String username = jwtUtil.extractUsername(jwt);
            UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(username, null,
                            List.of(new SimpleGrantedAuthority("ROLE_USER")));
            SecurityContextHolder.getContext().setAuthentication(authToken);
        }

        filterChain.doFilter(request, response);
    }
}
EOF

# ─────────────────────────────────────────────
# config/SecurityConfig.java
# ─────────────────────────────────────────────
cat > $BASE/config/SecurityConfig.java << 'EOF'
package com.stylekart.paymentservice.config;

import com.stylekart.paymentservice.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
EOF

# ─────────────────────────────────────────────
# service/PaymentService.java
# ─────────────────────────────────────────────
echo "📝 Writing PaymentService..."
cat > $BASE/service/PaymentService.java << 'EOF'
package com.stylekart.paymentservice.service;

import com.stylekart.paymentservice.client.OrderServiceClient;
import com.stylekart.paymentservice.dto.OrderResponse;
import com.stylekart.paymentservice.dto.PaymentRequest;
import com.stylekart.paymentservice.dto.PaymentResponse;
import com.stylekart.paymentservice.exception.PaymentAlreadyExistsException;
import com.stylekart.paymentservice.exception.PaymentNotFoundException;
import com.stylekart.paymentservice.model.Payment;
import com.stylekart.paymentservice.model.PaymentStatus;
import com.stylekart.paymentservice.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderServiceClient orderServiceClient;

    public PaymentResponse processPayment(PaymentRequest request, String userEmail, String token) {

        // Check if payment already exists for this order
        paymentRepository.findByOrderId(request.getOrderId()).ifPresent(p -> {
            throw new PaymentAlreadyExistsException(
                    "Payment already processed for order: " + request.getOrderId());
        });

        // Fetch order details
        OrderResponse order = orderServiceClient.getOrderById(request.getOrderId(), token);

        // Mock payment processing — 90% success rate
        boolean paymentSuccess = Math.random() > 0.1;

        PaymentStatus status = paymentSuccess ? PaymentStatus.SUCCESS : PaymentStatus.FAILED;
        String failureReason = paymentSuccess ? null : "Payment declined by bank";
        String newOrderStatus = paymentSuccess ? "CONFIRMED" : "PENDING";

        Payment payment = Payment.builder()
                .transactionId(UUID.randomUUID().toString())
                .orderId(order.getId())
                .userEmail(userEmail)
                .amount(order.getTotalAmount())
                .paymentMethod(request.getPaymentMethod())
                .status(status)
                .failureReason(failureReason)
                .build();

        Payment saved = paymentRepository.save(payment);

        // Update order status based on payment result
        orderServiceClient.updateOrderStatus(order.getId(), newOrderStatus, token);

        return mapToResponse(saved);
    }

    public PaymentResponse getPaymentByOrderId(Long orderId) {
        Payment payment = paymentRepository.findByOrderId(orderId)
                .orElseThrow(() -> new PaymentNotFoundException(
                        "Payment not found for order: " + orderId));
        return mapToResponse(payment);
    }

    public PaymentResponse getPaymentByTransactionId(String transactionId) {
        Payment payment = paymentRepository.findByTransactionId(transactionId)
                .orElseThrow(() -> new PaymentNotFoundException(
                        "Payment not found with transaction id: " + transactionId));
        return mapToResponse(payment);
    }

    public List<PaymentResponse> getMyPayments(String userEmail) {
        return paymentRepository.findByUserEmailOrderByCreatedAtDesc(userEmail)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private PaymentResponse mapToResponse(Payment payment) {
        return PaymentResponse.builder()
                .id(payment.getId())
                .transactionId(payment.getTransactionId())
                .orderId(payment.getOrderId())
                .userEmail(payment.getUserEmail())
                .amount(payment.getAmount())
                .paymentMethod(payment.getPaymentMethod().name())
                .status(payment.getStatus().name())
                .failureReason(payment.getFailureReason())
                .createdAt(payment.getCreatedAt())
                .build();
    }
}
EOF

# ─────────────────────────────────────────────
# controller/PaymentController.java
# ─────────────────────────────────────────────
echo "📝 Writing PaymentController..."
cat > $BASE/controller/PaymentController.java << 'EOF'
package com.stylekart.paymentservice.controller;

import com.stylekart.paymentservice.dto.PaymentRequest;
import com.stylekart.paymentservice.dto.PaymentResponse;
import com.stylekart.paymentservice.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping
    public ResponseEntity<PaymentResponse> processPayment(
            @Valid @RequestBody PaymentRequest request,
            Authentication authentication,
            HttpServletRequest httpRequest) {
        String token = httpRequest.getHeader("Authorization").substring(7);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(paymentService.processPayment(request, authentication.getName(), token));
    }

    @GetMapping("/order/{orderId}")
    public ResponseEntity<PaymentResponse> getPaymentByOrderId(@PathVariable Long orderId) {
        return ResponseEntity.ok(paymentService.getPaymentByOrderId(orderId));
    }

    @GetMapping("/transaction/{transactionId}")
    public ResponseEntity<PaymentResponse> getPaymentByTransactionId(
            @PathVariable String transactionId) {
        return ResponseEntity.ok(paymentService.getPaymentByTransactionId(transactionId));
    }

    @GetMapping("/my")
    public ResponseEntity<List<PaymentResponse>> getMyPayments(Authentication authentication) {
        return ResponseEntity.ok(paymentService.getMyPayments(authentication.getName()));
    }
}
EOF

# ─────────────────────────────────────────────
# pom.xml — rewrite cleanly
# ─────────────────────────────────────────────
echo "📝 Rewriting pom.xml..."
cat > payment-service/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <groupId>com.stylekart</groupId>
    <artifactId>payment-service</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>payment-service</name>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.11.5</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

echo ""
echo "✅ Payment Service setup complete!"
echo ""
echo "Next steps:"
echo "  1. CREATE DATABASE stylekart_payments;"
echo "  2. Make sure order-service is running on :8083"
echo "  3. cd payment-service && ./mvnw spring-boot:run"
echo "  4. Test POST http://localhost:8084/api/payments"
