# Use Node 20 on Debian Bookworm so we can install Chromium system deps (libglib, etc.)
# required by both Playwright and accessibility-checker's Puppeteer on Linux.
FROM node:20-bookworm

WORKDIR /app

# Install dependencies first (postinstall will run playwright install chromium;
# we override with full deps in the next step).
COPY package.json package-lock.json ./
RUN npm ci

# Install Chromium and all system libraries (libgobject-2.0, etc.) so the browser
# launches in the container. Fixes: "libgobject-2.0.so.0: cannot open shared object file"
RUN npx playwright install --with-deps chromium

# Build and run
COPY . .
RUN npm run build

ENV NODE_ENV=production
# Railway sets PORT; default for local Docker
ENV MCP_TRANSPORT=http
ENV PORT=3000
EXPOSE 3000

CMD ["node", "build/index.js"]
