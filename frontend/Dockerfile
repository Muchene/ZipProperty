# Multi-stage build for production
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Set the working directory
WORKDIR /app

# Enable web support and ensure proper configuration
RUN flutter config --enable-web

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the source code
COPY . .

# Clean and get dependencies again to ensure everything is properly set up
RUN flutter clean
RUN flutter pub get

# Build for web (production)
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy the built web app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
