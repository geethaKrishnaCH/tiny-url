package com.easylearnz.tinyurl.controller;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class TinyUrlController {

    private final StringRedisTemplate redisTemplate;

    public TinyUrlController(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    // Post request to create a new key-value pair in Redis
    @PostMapping("/redis/create")
    public ResponseEntity<String> create(@RequestBody Map<String, String> request) {
        String key = request.get("key");
        String value = request.get("value");
        redisTemplate.opsForValue().set(key, value);
        return ResponseEntity.ok("Key-Value pair created in Redis");
    }

    @GetMapping("/redis/key/{key}")
    public ResponseEntity<String> getValue(@PathVariable String key) {
        String value = redisTemplate.opsForValue().get(key);
        return ResponseEntity.ok(value);
    }
}
