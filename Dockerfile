# Custom PostgreSQL image for Espresso ML with pre-loaded schemas
FROM postgres:15

# Set labels for metadata
LABEL maintainer="Espresso ML Team"
LABEL description="PostgreSQL 15 with Espresso ML database schemas"
LABEL version="1.0.0"

# Set environment variables
ENV POSTGRES_DB=espresso_ml \
    POSTGRES_USER=postgres \
    POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"

# Copy schema files to the initialization directory
COPY charts/postgesql/schema/ /docker-entrypoint-initdb.d/

# Create a custom initialization script that sets up the database properly
COPY docker-entrypoint-initdb.d/99-custom-setup.sh /docker-entrypoint-initdb.d/99-custom-setup.sh
RUN chmod +x /docker-entrypoint-initdb.d/99-custom-setup.sh

# Add health check script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Create non-root user and set proper permissions
RUN groupadd -r espresso && \
    useradd -r -g espresso espresso && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R espresso:espresso /var/lib/postgresql/data && \
    chmod -R 755 /var/lib/postgresql/data

# Switch to non-root user
USER espresso

# Set healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

# Expose PostgreSQL port
EXPOSE 5432

# Default command (inherited from postgres:15)
CMD ["postgres"]
