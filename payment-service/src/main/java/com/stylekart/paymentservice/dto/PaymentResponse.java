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
