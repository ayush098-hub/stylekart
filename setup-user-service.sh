#!/bin/bash

# ─────────────────────────────────────────────
#  StyleKart — User Service Setup Script
#  Run from: /home/ayush/stylekart/
#  Usage: bash setup-user-service.sh
# ─────────────────────────────────────────────

set -e

BASE="demo/src/main/java/com/stylekart/userservice"
RESOURCES="demo/src/main/resources"

echo "📁 Creating package directories..."
mkdir -p $BASE/controller
mkdir -p $BASE/service
mkdir -p $BASE/repository
mkdir -p $BASE/model
mkdir -p $BASE/dto
mkdir -p $BASE/security
mkdir -p $BASE/exception
mkdir -p $BASE/config

# ─────────────────────────────────────────────
# application.yml
# ─────────────────────────────────────────────
echo "📝 Writing application.yml..."
rm -f $RESOURCES/application.properties
cat > $RESOURCES/application.yml << 'EOF'
server:
  port: 8081

spring:
  application:
    name: user-service
  datasource:
    url: jdbc:postgresql://localhost:5432/stylekart_users
    username: postgres
    password: postgres
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true

jwt:
  secret: 404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970
  expiration: 86400000
EOF

# ─────────────────────────────────────────────
# model/Role.java
# ─────────────────────────────────────────────
echo "📝 Writing model/Role.java..."
cat > $BASE/model/Role.java << 'EOF'
package com.stylekart.userservice.model;

public enum Role {
    ROLE_USER,
    ROLE_ADMIN
}
EOF

# ─────────────────────────────────────────────
# model/User.java
# ─────────────────────────────────────────────
echo "📝 Writing model/User.java..."
cat > $BASE/model/User.java << 'EOF'
package com.stylekart.userservice.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean enabled = true;

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
# repository/UserRepository.java
# ─────────────────────────────────────────────
echo "📝 Writing repository/UserRepository.java..."
cat > $BASE/repository/UserRepository.java << 'EOF'
package com.stylekart.userservice.repository;

import com.stylekart.userservice.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
EOF

# ─────────────────────────────────────────────
# dto/RegisterRequest.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/RegisterRequest.java..."
cat > $BASE/dto/RegisterRequest.java << 'EOF'
package com.stylekart.userservice.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    @Email(message = "Invalid email format")
    @NotBlank(message = "Email is required")
    private String email;

    @Size(min = 8, message = "Password must be at least 8 characters")
    @NotBlank(message = "Password is required")
    private String password;
}
EOF

# ─────────────────────────────────────────────
# dto/LoginRequest.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/LoginRequest.java..."
cat > $BASE/dto/LoginRequest.java << 'EOF'
package com.stylekart.userservice.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {

    @Email
    @NotBlank
    private String email;

    @NotBlank
    private String password;
}
EOF

# ─────────────────────────────────────────────
# dto/AuthResponse.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/AuthResponse.java..."
cat > $BASE/dto/AuthResponse.java << 'EOF'
package com.stylekart.userservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AuthResponse {
    private String token;
    private String email;
    private String firstName;
    private String role;
}
EOF

# ─────────────────────────────────────────────
# dto/UserProfileResponse.java
# ─────────────────────────────────────────────
echo "📝 Writing dto/UserProfileResponse.java..."
cat > $BASE/dto/UserProfileResponse.java << 'EOF'
package com.stylekart.userservice.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class UserProfileResponse {
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private String role;
    private LocalDateTime createdAt;
}
EOF

# ─────────────────────────────────────────────
# exception/UserAlreadyExistsException.java
# ─────────────────────────────────────────────
echo "📝 Writing exception/UserAlreadyExistsException.java..."
cat > $BASE/exception/UserAlreadyExistsException.java << 'EOF'
package com.stylekart.userservice.exception;

public class UserAlreadyExistsException extends RuntimeException {
    public UserAlreadyExistsException(String message) {
        super(message);
    }
}
EOF

# ─────────────────────────────────────────────
# exception/UserNotFoundException.java
# ─────────────────────────────────────────────
echo "📝 Writing exception/UserNotFoundException.java..."
cat > $BASE/exception/UserNotFoundException.java << 'EOF'
package com.stylekart.userservice.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
EOF

# ─────────────────────────────────────────────
# exception/GlobalExceptionHandler.java
# ─────────────────────────────────────────────
echo "📝 Writing exception/GlobalExceptionHandler.java..."
cat > $BASE/exception/GlobalExceptionHandler.java << 'EOF'
package com.stylekart.userservice.exception;

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

    @ExceptionHandler(UserAlreadyExistsException.class)
    public ResponseEntity<Map<String, Object>> handleUserAlreadyExists(UserAlreadyExistsException ex) {
        return buildResponse(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleUserNotFound(UserNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, ex.getMessage());
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
cat > $BASE/security/JwtUtil.java << 'EOF'
package com.stylekart.userservice.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, userDetails.getUsername());
    }

    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(getSignKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
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
echo "📝 Writing security/JwtAuthFilter.java..."
cat > $BASE/security/JwtAuthFilter.java << 'EOF'
package com.stylekart.userservice.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        String jwt = null;
        String userEmail = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            jwt = authHeader.substring(7);
            userEmail = jwtUtil.extractUsername(jwt);
        }

        if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = userDetailsService.loadUserByUsername(userEmail);
            if (jwtUtil.validateToken(jwt, userDetails)) {
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
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
package com.stylekart.userservice.config;

import com.stylekart.userservice.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
EOF

# ─────────────────────────────────────────────
# service/CustomUserDetailsService.java
# ─────────────────────────────────────────────
echo "📝 Writing service/CustomUserDetailsService.java..."
cat > $BASE/service/CustomUserDetailsService.java << 'EOF'
package com.stylekart.userservice.service;

import com.stylekart.userservice.exception.UserNotFoundException;
import com.stylekart.userservice.model.User;
import com.stylekart.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority(user.getRole().name()))
        );
    }
}
EOF

# ─────────────────────────────────────────────
# service/AuthService.java
# ─────────────────────────────────────────────
echo "📝 Writing service/AuthService.java..."
cat > $BASE/service/AuthService.java << 'EOF'
package com.stylekart.userservice.service;

import com.stylekart.userservice.dto.AuthResponse;
import com.stylekart.userservice.dto.LoginRequest;
import com.stylekart.userservice.dto.RegisterRequest;
import com.stylekart.userservice.dto.UserProfileResponse;
import com.stylekart.userservice.exception.UserAlreadyExistsException;
import com.stylekart.userservice.exception.UserNotFoundException;
import com.stylekart.userservice.model.Role;
import com.stylekart.userservice.model.User;
import com.stylekart.userservice.repository.UserRepository;
import com.stylekart.userservice.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("User already exists with email: " + request.getEmail());
        }

        User user = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(Role.ROLE_USER)
                .enabled(true)
                .build();

        userRepository.save(user);

        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .role(user.getRole().name())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .role(user.getRole().name())
                .build();
    }

    public UserProfileResponse getProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        return UserProfileResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
EOF

# ─────────────────────────────────────────────
# controller/AuthController.java
# ─────────────────────────────────────────────
echo "📝 Writing controller/AuthController.java..."
cat > $BASE/controller/AuthController.java << 'EOF'
package com.stylekart.userservice.controller;

import com.stylekart.userservice.dto.AuthResponse;
import com.stylekart.userservice.dto.LoginRequest;
import com.stylekart.userservice.dto.RegisterRequest;
import com.stylekart.userservice.dto.UserProfileResponse;
import com.stylekart.userservice.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getProfile(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(authService.getProfile(userDetails.getUsername()));
    }
}
EOF

# ─────────────────────────────────────────────
# pom.xml — add jjwt dependency
# ─────────────────────────────────────────────
echo "📝 Updating pom.xml with jjwt dependency..."
sed -i 's|</dependencies>|  <dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-api</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-impl</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t\t<dependency>\n\t\t\t<groupId>io.jsonwebtoken</groupId>\n\t\t\t<artifactId>jjwt-jackson</artifactId>\n\t\t\t<version>0.11.5</version>\n\t\t\t<scope>runtime</scope>\n\t\t</dependency>\n\t</dependencies>|' demo/pom.xml

echo ""
echo "✅ User Service setup complete!"
echo ""
echo "📂 Structure created under demo/src/main/java/com/stylekart/userservice/"
echo ""
echo "Next steps:"
echo "  1. Start PostgreSQL and create database: CREATE DATABASE stylekart_users;"
echo "  2. cd demo && ./mvnw spring-boot:run"
echo "  3. Test POST http://localhost:8081/api/auth/register"
EOF
