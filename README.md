# Accessibility Testing MCP

An MCP server for accessibility testing using **axe-core** and **IBM Equal Access**. Choose your testing engine or use both for comprehensive coverage.

## Example Prompts
- "Test the accessibility of https://example.com"
- "Test the accessibility of https://example.com" blockers only output issues in chat: What is the Issue, Who it Impacts, How to Fix, WCAG, Severity, Code Snippet"

### Dual Engine Support

- **Axe-core** (Deque) - Industry standard, zero false positives
- **IBM Equal Access** - Comprehensive IBM accessibility requirements

### Multi-Screen Testing

Test at multiple viewport sizes to catch responsive accessibility issues.

### Tools

| Tool | Description |
|------|-------------|
| `analyze_url` | Test any URL for accessibility issues |
| `analyze_url_json` | URL test with raw JSON output |
| `analyze_html` | Test HTML content directly |
| `analyze_html_json` | HTML test with raw JSON output |
| `get_rules` | List available accessibility rules |

All tools accept an optional `engine` parameter (`"axe"` or `"ace"`).

### 

## Installation

```bash
npm install
npm run build
```

## Configuration

### Environment Variables

Configure via MCP config `env` section:

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `A11Y_ENGINE` | `axe`, `ace` | `axe` | Testing engine |
| `WCAG_LEVEL` | `2.0_A`, `2.0_AA`, `2.1_A`, `2.1_AA`, `2.2_AA`, etc. | `2.1_AA` | WCAG version & level |
| `BEST_PRACTICES` | `true`, `false` | `true` | Include best practices/recommendations |
| `SCREEN_SIZES` | Comma-separated `WIDTHxHEIGHT` | `1280x1024` | Viewport sizes to test |
| `HEADLESS_BROWSER` | `true`, `false` | `true` | Run browser in headless mode; set to `false` to open visible browser |
| `MCP_TRANSPORT` | `stdio`, `http` | `stdio` | Use `http` to run as a remote MCP server (Streamable HTTP). |
| `PORT` | number | `3000` | When `MCP_TRANSPORT=http`, the port to listen on. |
| `CORS_ORIGIN` | origin string | `*` | Allowed CORS origin for HTTP transport (set in production). |

The `WCAG_LEVEL` setting automatically configures both Axe-core tags and IBM Equal Access policies.

### Running as a remote MCP server (HTTP)

You can run the server over HTTP so clients (e.g. Claude Code, Cursor, other MCP clients) connect to it remotely instead of via stdio:

```bash
# Build and start HTTP server on port 3000
npm run build
MCP_TRANSPORT=http PORT=3000 node build/index.js
# Or use the shortcut:
npm run start:http
```

The MCP endpoint is **POST/GET** at `/mcp` (e.g. `http://localhost:3000/mcp`). The server uses **stateless Streamable HTTP** (one transport per request), so it is safe to run behind load balancers and scales horizontally.

**Connect a client to the remote server:**

- **Claude Code**: `claude mcp add --transport http my-a11y https://your-host/mcp`
- **Cursor**: In MCP settings, add a remote server with URL `https://your-host/mcp` and transport `http`.

### Hosting options for remote MCP

| Option | Notes |
|--------|------|
| **Railway** | Use the repo **Dockerfile** (Builder = Dockerfile in settings). Set `MCP_TRANSPORT=http`; the image installs Chromium and system deps so `analyze_url` works. |
| **Docker** | Use a Node image, install Playwright dependencies and Chromium, set `MCP_TRANSPORT=http` and expose the app port. |
| **VPS (e.g. AWS EC2, DigitalOcean)** | Run `npm run start:http` behind nginx/Caddy as a reverse proxy; use HTTPS and set `CORS_ORIGIN` to your client’s origin. |
| **Serverless (e.g. AWS Lambda)** | Possible but not ideal: cold starts and time limits can affect long-running scans; prefer a long-running container or VM. |

### Deploy to Railway (step-by-step)

Railway’s default Node/Nixpacks image does **not** include the system libraries Chromium needs (e.g. `libgobject-2.0.so.0`). Use the repo’s **Dockerfile** so the browser works after deploy.

1. **Connect the repo**
   - Go to [railway.app](https://railway.app) and sign in (e.g. with GitHub).
   - **New Project** → **Deploy from GitHub repo**.
   - Select the `accessibility-testing-mcp` repository (and branch, e.g. `main`).

2. **Use Docker build**
   - In the service: **Settings** → **Build** (or **Deploy**).
   - Set **Builder** to **Dockerfile** (so Railway builds from the repo’s `Dockerfile` instead of Nixpacks).
   - The Dockerfile installs Node, Chromium, and system dependencies (`playwright install --with-deps chromium`), then builds and runs the app.

3. **Set environment variables**
   - **Variables** (or **Settings** → **Environment**): add **`MCP_TRANSPORT`** = **`http`**.
   - Do **not** set `PORT`; Railway sets it. The app uses `process.env.PORT`.

4. **Start command**
   - No need to set a custom start command; the Dockerfile runs **`node build/index.js`**.

5. **Get the URL**
   - **Settings** → **Networking** → **Generate domain** (e.g. `your-app.up.railway.app`).
   - MCP endpoint: **`https://<your-app.up.railway.app>/mcp`** (or **`/mcp/bridge`** for CodeMie).

6. **Use in CodeMie**
   - Add an MCP server: type **Streamable HTTP**, URL **`https://<your-app.up.railway.app>/mcp`**.

**If you see “libgobject-2.0.so.0: cannot open shared object file”:** the runtime image is missing Chromium’s system libraries. Deploy using the **Dockerfile** (step 2) so Railway uses a image that runs `playwright install --with-deps chromium`.

### VS Code (GitHub Copilot)

Add to VS Code settings (JSON):

```jsonc
"mcp": {
  "servers": {
    "accessibility-testing-mcp": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/accessibility-testing-mcp/build/index.js"],
      "env": {
        "A11Y_ENGINE": "axe",
        "WCAG_LEVEL": "2.2_AA",
        "BEST_PRACTICES": "true",
        "SCREEN_SIZES": "1280x1024,320x640",
        "HEADLESS_BROWSER": "true"
      }
    }
  }
}
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "accessibility": {
      "command": "node",
      "args": ["/path/to/accessibility-testing-mcp/build/index.js"],
      "env": {
        "A11Y_ENGINE": "ace",
        "WCAG_LEVEL": "2.2_AA",
        "BEST_PRACTICES": "true"
      }
    }
  }
}
```

## Understanding Results

### Axe-core Output
- **Violations**: Definite accessibility failures
- **Incomplete**: Needs manual review
- **Passes**: Rules that passed
- **Inapplicable**: Rules that don't apply

### IBM Equal Access Output
- **Violations**: Accessibility failures
- **Potential Violations**: Needs review
- **Recommendations**: Suggested improvements (when BEST_PRACTICES=true)
- **Manual Checks**: Requires human testing

## WCAG_LEVEL Values

| Level | Description |
|-------|-------------|
| `2.0_A` | WCAG 2.0 Level A |
| `2.0_AA` | WCAG 2.0 Level AA |
| `2.1_A` | WCAG 2.1 Level A |
| `2.1_AA` | WCAG 2.1 Level AA (default) |
| `2.1_AAA` | WCAG 2.1 Level AAA |
| `2.2_A` | WCAG 2.2 Level A |
| `2.2_AA` | WCAG 2.2 Level AA |
| `2.2_AAA` | WCAG 2.2 Level AAA |

## Dependencies

- **@modelcontextprotocol/sdk** - MCP server framework
- **axe-core** - Deque accessibility testing engine
- **accessibility-checker** - IBM Equal Access engine
- **playwright** - Headless browser automation

## License

MIT
