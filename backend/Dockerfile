# Use the official Rust image as the base
FROM rust:1.91

# Set the working directory
WORKDIR /app

# Copy the Cargo.toml and Cargo.lock files
COPY Cargo.toml Cargo.lock ./

# Copy the source code
COPY src ./src
COPY migrations ./migrations

# Build the application
RUN cargo build --release

# Expose the port
EXPOSE 8080

# Run the application
CMD ["cargo", "run", "--release"]
