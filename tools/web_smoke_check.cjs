#!/usr/bin/env node

const fs = require("fs");
const http = require("http");
const path = require("path");
const { chromium, devices } = require("playwright");

const buildDir = path.resolve(process.argv[2] || "");

if (!buildDir || !fs.existsSync(path.join(buildDir, "index.html"))) {
	throw new Error("Usage: node tools/web_smoke_check.cjs <build-dir-with-index.html>");
}

function getContentType(filePath) {
	const extension = path.extname(filePath).toLowerCase();
	const contentTypes = {
		".html": "text/html; charset=utf-8",
		".js": "text/javascript; charset=utf-8",
		".json": "application/json; charset=utf-8",
		".pck": "application/octet-stream",
		".png": "image/png",
		".svg": "image/svg+xml",
		".txt": "text/plain; charset=utf-8",
		".wasm": "application/wasm",
	};
	return contentTypes[extension] || "application/octet-stream";
}

function makeServer(rootDir) {
	return http.createServer((request, response) => {
		const requestUrl = new URL(request.url, "http://127.0.0.1");
		const requestPath = requestUrl.pathname === "/" ? "/index.html" : requestUrl.pathname;
		const normalizedPath = path.normalize(requestPath).replace(/^([.][.][/\\])+/, "");
		const resolvedPath = path.resolve(path.join(rootDir, "." + normalizedPath));

		if (!resolvedPath.startsWith(rootDir)) {
			response.writeHead(403, { "Content-Type": "text/plain; charset=utf-8" });
			response.end("Forbidden");
			return;
		}

		fs.readFile(resolvedPath, (error, data) => {
			if (error) {
				response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
				response.end("Not found");
				return;
			}

			response.writeHead(200, {
				"Cache-Control": "no-store",
				"Content-Type": getContentType(resolvedPath),
				"Cross-Origin-Embedder-Policy": "require-corp",
				"Cross-Origin-Opener-Policy": "same-origin",
				"Cross-Origin-Resource-Policy": "cross-origin",
			});
			response.end(data);
		});
	});
}

async function runCase(baseUrl, name, contextOptions) {
	const browser = await chromium.launch({
		headless: true,
		args: ["--autoplay-policy=no-user-gesture-required"],
	});

	const context = await browser.newContext({
		...contextOptions,
		ignoreHTTPSErrors: true,
		viewport: contextOptions.viewport || { width: 1280, height: 720 },
	});
	const page = await context.newPage();

	const consoleErrors = [];
	const pageErrors = [];
	const requestFailures = [];

	page.on("console", (message) => {
		if (message.type() === "error") {
			const text = message.text();
			if (text.includes("Analytics disabled:")) {
				return;
			}
			if (text.includes("at: push_warning") || text.includes("GDScript backtrace")) {
				return;
			}
			if (text.includes("[0] warn (") || text.includes("_ready (res://autoloads/analytics.gd:")) {
				return;
			}
			consoleErrors.push(text);
		}
	});

	page.on("pageerror", (error) => {
		pageErrors.push(error.stack || error.message || String(error));
	});

	page.on("requestfailed", (request) => {
		if (request.url().endsWith(".map")) {
			return;
		}
		const failure = request.failure();
		requestFailures.push({
			url: request.url(),
			method: request.method(),
			errorText: (failure && failure.errorText) || "Unknown failure",
		});
	});

	try {
		await page.goto(`${baseUrl}/index.html`, { waitUntil: "load", timeout: 30000 });
		await page.waitForFunction(() => window.crossOriginIsolated === true, null, { timeout: 15000 });
		await page.waitForFunction(() => window.__godotGameReady === true, null, { timeout: 45000 });

		const bootState = await page.evaluate(() => window.__godotBootState || null);
		const statusVisible = await page.evaluate(() => {
			const status = document.getElementById("status");
			if (!status) {
				return false;
			}
			const style = window.getComputedStyle(status);
			return status.isConnected && style.display !== "none" && style.visibility !== "hidden";
		});

		if (bootState != null && Array.isArray(bootState.failures) && bootState.failures.length > 0) {
			throw new Error(`${name}: boot monitor reported failures: ${JSON.stringify(bootState.failures)}`);
		}
		var actionableRequestFailures = requestFailures.filter((failure) => {
			if (!failure.url.endsWith(".wasm")) {
				return true;
			}
			return failure.errorText != "net::ERR_ABORTED";
		});
		if (actionableRequestFailures.length > 0) {
			throw new Error(`${name}: network failures detected: ${actionableRequestFailures.map((failure) => `${failure.method} ${failure.url} :: ${failure.errorText}`).join(" | ")}`);
		}
		if (pageErrors.length > 0) {
			throw new Error(`${name}: page errors detected: ${pageErrors.join(" | ")}`);
		}
		if (consoleErrors.length > 0) {
			throw new Error(`${name}: console errors detected: ${consoleErrors.join(" | ")}`);
		}
		if (statusVisible) {
			throw new Error(`${name}: Godot loading overlay is still visible after the game reported ready.`);
		}

		console.log(`${name}: ready in ${bootState && bootState.readyAtMs ? bootState.readyAtMs : "unknown"}ms`);
		return bootState;
	} finally {
		await context.close();
		await browser.close();
	}
}

async function main() {
	const server = makeServer(buildDir);
	await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
	const address = server.address();
	const baseUrl = `http://127.0.0.1:${address.port}`;

	try {
		await runCase(baseUrl, "desktop", {});
		await runCase(baseUrl, "mobile", devices["Pixel 5"]);
	} finally {
		await new Promise((resolve, reject) => {
			server.close((error) => {
				if (error) {
					reject(error);
					return;
				}
				resolve();
			});
		});
	}
}

main().catch((error) => {
	console.error(error.stack || error.message || String(error));
	process.exitCode = 1;
});
