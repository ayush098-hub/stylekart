package com.stylekart.orderservice.repository;

import com.stylekart.orderservice.model.Order;
import com.stylekart.orderservice.model.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByUserEmailOrderByCreatedAtDesc(String userEmail);
    Optional<Order> findByIdAndUserEmail(Long id, String userEmail);
    List<Order> findByStatus(OrderStatus status);
}
