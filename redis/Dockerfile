FROM redis:8.4.0-alpine3.22

# Create cert directory
RUN mkdir -p /certs \
    && chown -R redis:redis /certs \
    && chmod 700 /certs

# Copy certs into image
COPY certs/redis/redis.crt /certs/
COPY certs/redis/redis.key /certs/
COPY certs/root/ca.crt /certs/

# Fix permissions INSIDE image
RUN chown redis:redis /certs/* \
    && chmod 600 /certs/redis.key \
    && chmod 644 /certs/redis.crt /certs/ca.crt

# Copy redis config
COPY redis.conf /usr/local/etc/redis/redis.conf

USER redis

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
