package com.easylearnz.tinyurl.controller;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TinyUrlController {

    private final StringRedisTemplate redisTemplate;

    public TinyUrlController(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @GetMapping("/redis/test")
    public ResponseEntity<String> test() {
        redisTemplate.opsForValue().set("layer0", "Redis is working!");
        String value = redisTemplate.opsForValue().get("layer0");
        return ResponseEntity.ok(value);
    }
}
