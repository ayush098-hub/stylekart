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
