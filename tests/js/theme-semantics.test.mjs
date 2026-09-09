import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));

async function qmlFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(entry => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return qmlFiles(path);
    return entry.isFile() && entry.name.endsWith(".qml") ? [path] : [];
  }));
  return nested.flat();
}

for (const directory of ["components", "modules"]) {
  for (const path of await qmlFiles(join(root, directory))) {
    const source = await readFile(path, "utf8");
    assert.equal(source.includes("ThemeService.theme.palette"), false,
      `${relative(root, path)} must consume semantic theme tokens`);
  }
}

for (const path of await qmlFiles(join(root, "modules"))) {
  const source = await readFile(path, "utf8");
  assert.equal(source.includes("tokens.on_surface_disabled"), false,
    `${relative(root, path)} must leave disabled styling to shared controls`);
}

console.log("theme semantic source checks passed");
