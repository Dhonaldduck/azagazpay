FROM node:22-slim

# Install sqlite3 dependencies
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy all source code
COPY . .

# Buat folder data untuk database agar tidak hilang saat restart (jika pakai volume)
RUN mkdir -p data

# Expose port
EXPOSE 3000

# Jalankan backend dengan flag experimental sqlite
CMD ["node", "--experimental-sqlite", "src/index.js"]
