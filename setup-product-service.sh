#!/bin/bash

# ─────────────────────────────────────────────
#  StyleKart — Product Service Setup Script
#  Run from: /home/ayush/stylekart/
#  Usage: bash setup-product-service.sh
# ─────────────────────────────────────────────

set -e

BASE="product-service/src/main/java/com/stylekart/productservice"
RESOURCES="product-service/src/main/resources"

echo "📁 Creating package directories..."
mkdir -p $BASE/controller
mkdir -p $BASE/service
mkdir -p $BASE/repository
mkdir -p $BASE/model
mkdir -p $BASE/dto
mkdir -p $BASE/exception
mkdir -p $BASE/config

# ─────────────────────────────────────────────
# Fix main application class package
# ─────────────────────────────────────────────
echo "📝 Fixing main application class..."
mkdir -p $BASE
cat > $BASE/ProductServiceApplication.java << 'EOF'
package com.stylekart.productservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ProductServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProductServiceApplication.class, args);
    }
}
EOF

# Remove old demo main class if present
rm -rf product-service/src/main/java/com/stylekart/demo 2>/dev/null || true

# ─────────────────────────────────────────────
# application.yml
# ─────────────────────────────────────────────
echo "📝 Writing application.yml..."
rm -f $RESOURCES/application.properties
cat > $RESOURCES/application.yml << 'EOF'
server:
  port: 8082

spring:
  application:
    name: product-service
  datasource:
    url: jdbc:postgresql://localhost:5432/stylekart_products
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
EOF

# ─────────────────────────────────────────────
# model/Category.java
# ─────────────────────────────────────────────
echo "📝 Writing model/Category.java..."
cat > $BASE/model/Category.java << 'EOF'
package com.stylekart.productservice.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "categories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column
    private String description;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    private List<Product> products;
}
EOF

# ─────────────────────────────────────────────
# model/Product.java
# ─────────────────────────────────────────────
echo "📝 Writing model/Product.java..."
cat > $BASE/model/Product.java << 'EOF'
package com.stylekart.productservice.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "products")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private BigDecimal price;

    @Column(nullable = false)
    private String brand;

    @Column(nullable = false)
    private Integer stockQuantity;

    @Column
    private String imageUrl;

    @Column(nullable = false)
    private String gender;

    @ElementCollection
    @CollectionTable(name = "product_sizes", joinColumns = @JoinColumn(name = "product_id"))
    @Column(name = "size")
    private List<String> availableSizes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false)
    private boolean active = true;

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
# repository/CategoryRepository.java
# ─────────────────────────────────────────────
echo "📝 Writing repository/CategoryRepository.java..."
cat > $BASE/repository/CategoryRepository.java << 'EOF'
package com.stylekart.productservice.repository;

import com.stylekart.productservice.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    Optional<Category> findByName(String name);
    boolean existsByName(String name);
}
EOF

# ─────────────────────────────────────────────
# repository/ProductRepository.java
# ─────────────────────────────────────────────
echo "📝 Writing repository/ProductRepository.java..."
cat > $BASE/repository/ProductRepository.java << 'EOF'
package com.stylekart.productservice.repository;

import com.stylekart.productservice.model.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ProductRepository extends JpaRepository<Product, Long> {

    Page<Product> findByActiveTrue(Pageable pageable);

    Page<Product> findByCategoryIdAndActiveTrue(Long categoryId, Pageable pageable);

    Page<Product> findByGenderAndActiveTrue(String gender, Pageable pageable);

    @Query("SELECT p FROM Product p WHERE p.active = true AND " +
           "(LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(p.brand) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<Product> searchProducts(@Param("keyword") String keyword, Pageable pageable);

    List<Product> findByBrandAndActiveTrue(String brand);
}
EOF

# ─────────────────────────────────────────────
# dto/CategoryRequest.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/CategoryRequest.java..."
cat > $BASE/dto/CategoryRequest.java << 'EOF'
package com.stylekart.productservice.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CategoryRequest {

    @NotBlank(message = "Category name is required")
    private String name;

    private String description;
}
EOF

# ─────────────────────────────────────────────
# dto/CategoryResponse.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/CategoryResponse.java..."
cat > $BASE/dto/CategoryResponse.java << 'EOF'
package com.stylekart.productservice.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CategoryResponse {
    private Long id;
    private String name;
    private String description;
}
EOF

# ─────────────────────────────────────────────
# dto/ProductRequest.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/ProductRequest.java..."
cat > $BASE/dto/ProductRequest.java << 'EOF'
package com.stylekart.productservice.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class ProductRequest {

    @NotBlank(message = "Product name is required")
    private String name;

    private String description;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
    private BigDecimal price;

    @NotBlank(message = "Brand is required")
    private String brand;

    @NotNull(message = "Stock quantity is required")
    @Min(value = 0, message = "Stock cannot be negative")
    private Integer stockQuantity;

    private String imageUrl;

    @NotBlank(message = "Gender is required")
    private String gender;

    private List<String> availableSizes;

    @NotNull(message = "Category ID is required")
    private Long categoryId;
}
EOF

# ─────────────────────────────────────────────
# dto/ProductResponse.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/ProductResponse.java..."
cat > $BASE/dto/ProductResponse.java << 'EOF'
package com.stylekart.productservice.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ProductResponse {
    private Long id;
    private String name;
    private String description;
    private BigDecimal price;
    private String brand;
    private Integer stockQuantity;
    private String imageUrl;
    private String gender;
    private List<String> availableSizes;
    private CategoryResponse category;
    private boolean active;
    private LocalDateTime createdAt;
}
EOF

# ─────────────────────────────────────────────
# dto/PagedResponse.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/PagedResponse.java..."
cat > $BASE/dto/PagedResponse.java << 'EOF'
package com.stylekart.productservice.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class PagedResponse<T> {
    private List<T> content;
    private int pageNumber;
    private int pageSize;
    private long totalElements;
    private int totalPages;
    private boolean last;
}
EOF

# ─────────────────────────────────────────────
# exception/ProductNotFoundException.java
# ─────────────────────────────────────────────
echo "📝 Writing exception classes..."
cat > $BASE/exception/ProductNotFoundException.java << 'EOF'
package com.stylekart.productservice.exception;

public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/CategoryNotFoundException.java << 'EOF'
package com.stylekart.productservice.exception;

public class CategoryNotFoundException extends RuntimeException {
    public CategoryNotFoundException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/CategoryAlreadyExistsException.java << 'EOF'
package com.stylekart.productservice.exception;

public class CategoryAlreadyExistsException extends RuntimeException {
    public CategoryAlreadyExistsException(String message) {
        super(message);
    }
}
EOF

cat > $BASE/exception/GlobalExceptionHandler.java << 'EOF'
package com.stylekart.productservice.exception;

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

    @ExceptionHandler(ProductNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleProductNotFound(ProductNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(CategoryNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleCategoryNotFound(CategoryNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(CategoryAlreadyExistsException.class)
    public ResponseEntity<Map<String, Object>> handleCategoryAlreadyExists(CategoryAlreadyExistsException ex) {
        return buildResponse(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationErrors(MethodArgumentNotValidException ex) {
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
# security/JwtUtil.java
# ─────────────────────────────────────────────
echo "📝 Writing security/JwtUtil.java..."
mkdir -p $BASE/security
cat > $BASE/security/JwtUtil.java << 'EOF'
package com.stylekart.productservice.security;

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

# ─────────────────────────────────────────────
# security/JwtAuthFilter.java
# ─────────────────────────────────────────────
cat > $BASE/security/JwtAuthFilter.java << 'EOF'
package com.stylekart.productservice.security;

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
echo "📝 Writing config/SecurityConfig.java..."
cat > $BASE/config/SecurityConfig.java << 'EOF'
package com.stylekart.productservice.config;

import com.stylekart.productservice.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
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
                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
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
# service/CategoryService.java
# ─────────────────────────────────────────────
echo "📝 Writing service/CategoryService.java..."
cat > $BASE/service/CategoryService.java << 'EOF'
package com.stylekart.productservice.service;

import com.stylekart.productservice.dto.CategoryRequest;
import com.stylekart.productservice.dto.CategoryResponse;
import com.stylekart.productservice.exception.CategoryAlreadyExistsException;
import com.stylekart.productservice.exception.CategoryNotFoundException;
import com.stylekart.productservice.model.Category;
import com.stylekart.productservice.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryResponse createCategory(CategoryRequest request) {
        if (categoryRepository.existsByName(request.getName())) {
            throw new CategoryAlreadyExistsException("Category already exists: " + request.getName());
        }

        Category category = Category.builder()
                .name(request.getName())
                .description(request.getDescription())
                .build();

        Category saved = categoryRepository.save(category);
        return mapToResponse(saved);
    }

    public List<CategoryResponse> getAllCategories() {
        return categoryRepository.findAll()
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public CategoryResponse getCategoryById(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new CategoryNotFoundException("Category not found with id: " + id));
        return mapToResponse(category);
    }

    public CategoryResponse mapToResponse(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .description(category.getDescription())
                .build();
    }
}
EOF

# ─────────────────────────────────────────────
# service/ProductService.java
# ─────────────────────────────────────────────
echo "📝 Writing service/ProductService.java..."
cat > $BASE/service/ProductService.java << 'EOF'
package com.stylekart.productservice.service;

import com.stylekart.productservice.dto.*;
import com.stylekart.productservice.exception.CategoryNotFoundException;
import com.stylekart.productservice.exception.ProductNotFoundException;
import com.stylekart.productservice.model.Category;
import com.stylekart.productservice.model.Product;
import com.stylekart.productservice.repository.CategoryRepository;
import com.stylekart.productservice.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryService categoryService;

    public ProductResponse createProduct(ProductRequest request) {
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new CategoryNotFoundException("Category not found with id: " + request.getCategoryId()));

        Product product = Product.builder()
                .name(request.getName())
                .description(request.getDescription())
                .price(request.getPrice())
                .brand(request.getBrand())
                .stockQuantity(request.getStockQuantity())
                .imageUrl(request.getImageUrl())
                .gender(request.getGender())
                .availableSizes(request.getAvailableSizes())
                .category(category)
                .active(true)
                .build();

        return mapToResponse(productRepository.save(product));
    }

    public PagedResponse<ProductResponse> getAllProducts(int page, int size, String sortBy) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<Product> products = productRepository.findByActiveTrue(pageable);
        return buildPagedResponse(products);
    }

    public ProductResponse getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + id));
        return mapToResponse(product);
    }

    public PagedResponse<ProductResponse> getProductsByCategory(Long categoryId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Product> products = productRepository.findByCategoryIdAndActiveTrue(categoryId, pageable);
        return buildPagedResponse(products);
    }

    public PagedResponse<ProductResponse> getProductsByGender(String gender, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Product> products = productRepository.findByGenderAndActiveTrue(gender, pageable);
        return buildPagedResponse(products);
    }

    public PagedResponse<ProductResponse> searchProducts(String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Product> products = productRepository.searchProducts(keyword, pageable);
        return buildPagedResponse(products);
    }

    public ProductResponse updateProduct(Long id, ProductRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + id));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new CategoryNotFoundException("Category not found with id: " + request.getCategoryId()));

        product.setName(request.getName());
        product.setDescription(request.getDescription());
        product.setPrice(request.getPrice());
        product.setBrand(request.getBrand());
        product.setStockQuantity(request.getStockQuantity());
        product.setImageUrl(request.getImageUrl());
        product.setGender(request.getGender());
        product.setAvailableSizes(request.getAvailableSizes());
        product.setCategory(category);

        return mapToResponse(productRepository.save(product));
    }

    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + id));
        product.setActive(false);
        productRepository.save(product);
    }

    private ProductResponse mapToResponse(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .brand(product.getBrand())
                .stockQuantity(product.getStockQuantity())
                .imageUrl(product.getImageUrl())
                .gender(product.getGender())
                .availableSizes(product.getAvailableSizes())
                .category(categoryService.mapToResponse(product.getCategory()))
                .active(product.isActive())
                .createdAt(product.getCreatedAt())
                .build();
    }

    private PagedResponse<ProductResponse> buildPagedResponse(Page<Product> page) {
        return PagedResponse.<ProductResponse>builder()
                .content(page.getContent().stream().map(this::mapToResponse).toList())
                .pageNumber(page.getNumber())
                .pageSize(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .last(page.isLast())
                .build();
    }
}
EOF

# ─────────────────────────────────────────────
# controller/CategoryController.java
# ─────────────────────────────────────────────
echo "📝 Writing controller/CategoryController.java..."
cat > $BASE/controller/CategoryController.java << 'EOF'
package com.stylekart.productservice.controller;

import com.stylekart.productservice.dto.CategoryRequest;
import com.stylekart.productservice.dto.CategoryResponse;
import com.stylekart.productservice.service.CategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    public ResponseEntity<CategoryResponse> createCategory(@Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(categoryService.createCategory(request));
    }

    @GetMapping
    public ResponseEntity<List<CategoryResponse>> getAllCategories() {
        return ResponseEntity.ok(categoryService.getAllCategories());
    }

    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponse> getCategoryById(@PathVariable Long id) {
        return ResponseEntity.ok(categoryService.getCategoryById(id));
    }
}
EOF

# ─────────────────────────────────────────────
# controller/ProductController.java
# ─────────────────────────────────────────────
echo "📝 Writing controller/ProductController.java..."
cat > $BASE/controller/ProductController.java << 'EOF'
package com.stylekart.productservice.controller;

import com.stylekart.productservice.dto.PagedResponse;
import com.stylekart.productservice.dto.ProductRequest;
import com.stylekart.productservice.dto.ProductResponse;
import com.stylekart.productservice.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @PostMapping
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody ProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(productService.createProduct(request));
    }

    @GetMapping
    public ResponseEntity<PagedResponse<ProductResponse>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {
        return ResponseEntity.ok(productService.getAllProducts(page, size, sortBy));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getProductById(@PathVariable Long id) {
        return ResponseEntity.ok(productService.getProductById(id));
    }

    @GetMapping("/category/{categoryId}")
    public ResponseEntity<PagedResponse<ProductResponse>> getProductsByCategory(
            @PathVariable Long categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(productService.getProductsByCategory(categoryId, page, size));
    }

    @GetMapping("/gender/{gender}")
    public ResponseEntity<PagedResponse<ProductResponse>> getProductsByGender(
            @PathVariable String gender,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(productService.getProductsByGender(gender, page, size));
    }

    @GetMapping("/search")
    public ResponseEntity<PagedResponse<ProductResponse>> searchProducts(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(productService.searchProducts(keyword, page, size));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody ProductRequest request) {
        return ResponseEntity.ok(productService.updateProduct(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }
}
EOF

# ─────────────────────────────────────────────
# pom.xml — add jjwt dependency
# ─────────────────────────────────────────────
echo "📝 Updating pom.xml with jjwt dependency..."
sed -i 's|</dependencies>|  <dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-api</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-impl</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-jackson</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t</dependencies>|' product-service/pom.xml

echo ""
echo "✅ Product Service setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create the database: CREATE DATABASE stylekart_products;"
echo "  2. cd product-service && ./mvnw spring-boot:run"
echo "  3. Test POST http://localhost:8082/api/categories"
echo "  4. Test POST http://localhost:8082/api/products"
