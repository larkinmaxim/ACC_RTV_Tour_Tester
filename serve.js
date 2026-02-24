/**
 * Simple static file server with Bun — serves index.html and project files.
 * Run: bun run serve
 */
const server = Bun.serve({
  port: 3001,
  async fetch(req) {
    const pathname = new URL(req.url).pathname;
    const filePath = pathname === "/" ? "index.html" : pathname.slice(1).replace(/^\//, "");

    const file = Bun.file(filePath);
    if (await file.exists()) {
      return new Response(file);
    }
    return new Response("Not Found", { status: 404 });
  },
});

console.log(`Serving at http://localhost:${server.port}`);
