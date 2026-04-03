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
