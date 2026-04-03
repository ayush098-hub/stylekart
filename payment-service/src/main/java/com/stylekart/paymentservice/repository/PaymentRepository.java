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
