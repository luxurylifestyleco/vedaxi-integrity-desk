import assert from "node:assert/strict";

const SOURCES = [
  ["MCP", "modelcontextprotocol/modelcontextprotocol", "ab3a39c13bd23be691c2760e1c6c5c15a64582e1"],
  ["A2A", "a2aproject/A2A", "43e0c874d3baba68ed84b98678d7f2268438e69f"],
  ["WebMCP", "webmachinelearning/webmcp", "f5645e9aea51eb589599f181d104a2f49430608e"],
  ["UCP", "Universal-Commerce-Protocol/ucp", "a7c944a6ce07faff72d3872a26945514183ef6e5"],
];

export function compareStandards(current) {
  return SOURCES.map(([name, repo, baseline]) => ({
    name,
    repo,
    baseline,
    current: current[repo],
    changed: current[repo] !== baseline,
  }));
}

async function fetchHead(repo) {
  const response = await fetch(`https://api.github.com/repos/${repo}/commits/HEAD`, {
    headers: { Accept: "application/vnd.github+json", "User-Agent": "vedaxi-standards-watch" },
  });
  if (!response.ok) throw new Error(`${repo}: GitHub returned ${response.status}`);
  return (await response.json()).sha;
}

if (process.argv.includes("--self-test")) {
  const current = Object.fromEntries(SOURCES.map(([, repo, baseline]) => [repo, baseline]));
  assert.equal(compareStandards(current).some(({ changed }) => changed), false);
  current[SOURCES[0][1]] = "changed";
  assert.equal(compareStandards(current)[0].changed, true);
  console.log("standards watcher self-test passed");
} else {
  try {
    const current = Object.fromEntries(
      await Promise.all(SOURCES.map(async ([, repo]) => [repo, await fetchHead(repo)])),
    );
    const report = compareStandards(current);
    for (const item of report) {
      console.log(`${item.changed ? "CHANGED" : "UNCHANGED"} ${item.name} ${item.current} https://github.com/${item.repo}`);
    }
    if (report.some(({ changed }) => changed)) process.exitCode = 1;
  } catch (error) {
    console.error(`WATCH ERROR ${error.message}`);
    process.exitCode = 2;
  }
}
