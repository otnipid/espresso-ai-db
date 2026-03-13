# Secure PostgreSQL image for Espresso ML with pre-loaded schemas
FROM postgres:15

# Create dedicated application user with minimal privileges
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set labels for metadata
LABEL maintainer="Espresso ML Team"
LABEL description="PostgreSQL 15 with Espresso ML database schemas (secure)"
LABEL version="1.0.0"

# Set secure environment variables
ENV POSTGRES_DB=espresso_ml \
    POSTGRES_USER=espresso_app \
    POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"

# Copy schema files to initialization directory (before user switch)
COPY schema/ /docker-entrypoint-initdb.d/schema/
COPY docker-entrypoint-initdb.d/99-custom-setup.sh /docker-entrypoint-initdb.d/99-custom-setup.sh

# Set permissions and switch to non-root user
RUN chmod +x /docker-entrypoint-initdb.d/99-custom-setup.sh && \
    chown -R appuser:appuser /docker-entrypoint-initdb.d/
USER appuser

# Add health check script (as appuser)
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Set healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /healthcheck.sh