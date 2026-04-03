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
