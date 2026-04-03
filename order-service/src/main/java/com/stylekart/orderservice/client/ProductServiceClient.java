package com.stylekart.orderservice.client;

import com.stylekart.orderservice.dto.ProductResponse;
import com.stylekart.orderservice.exception.ProductServiceException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
@RequiredArgsConstructor
public class ProductServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.product-service.url}")
    private String productServiceUrl;

    public ProductResponse getProductById(Long productId) {
        try {
            return restTemplate.getForObject(
                    productServiceUrl + "/api/products/" + productId,
                    ProductResponse.class
            );
        } catch (Exception e) {
            throw new ProductServiceException("Failed to fetch product with id: " + productId);
        }
    }
}
