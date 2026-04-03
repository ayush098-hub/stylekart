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
