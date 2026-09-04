import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const load = async path => JSON.parse(await readFile(new URL(path, import.meta.url), "utf8"));

function validate(document, schema, rootSchema = schema, path = "$") {
  if (schema.$ref) {
    const parts = schema.$ref.replace(/^#\//, "").split("/");
    let target = rootSchema;
    for (const part of parts) target = target[part];
    return validate(document, target, rootSchema, path);
  }

  const errors = [];
  const actualType = Array.isArray(document) ? "array" : document === null ? "null" : typeof document;
  if (schema.type === "object" && actualType !== "object") return [`${path}: expected object`];
  if (schema.type === "array" && actualType !== "array") return [`${path}: expected array`];
  if (schema.type === "string" && actualType !== "string") return [`${path}: expected string`];
  if (schema.type === "boolean" && actualType !== "boolean") return [`${path}: expected boolean`];
  if (schema.type === "number" && (actualType !== "number" || !Number.isFinite(document))) return [`${path}: expected number`];
  if (schema.type === "integer" && !Number.isInteger(document)) return [`${path}: expected integer`];

  if (schema.const !== undefined && document !== schema.const) errors.push(`${path}: expected constant ${schema.const}`);
  if (schema.enum && !schema.enum.includes(document)) errors.push(`${path}: unsupported value`);
  if (schema.pattern && typeof document === "string" && !(new RegExp(schema.pattern)).test(document)) errors.push(`${path}: pattern mismatch`);
  if (schema.minLength !== undefined && document.length < schema.minLength) errors.push(`${path}: too short`);
  if (schema.minimum !== undefined && document < schema.minimum) errors.push(`${path}: below minimum`);
  if (schema.maximum !== undefined && document > schema.maximum) errors.push(`${path}: above maximum`);

  if (actualType === "object") {
    const properties = schema.properties || {};
    for (const required of schema.required || []) {
      if (!(required in document)) errors.push(`${path}.${required}: required`);
    }
    if (schema.minProperties !== undefined && Object.keys(document).length < schema.minProperties)
      errors.push(`${path}: too few properties`);
    for (const [key, value] of Object.entries(document)) {
      if (properties[key]) errors.push(...validate(value, properties[key], rootSchema, `${path}.${key}`));
      else if (schema.additionalProperties === false) errors.push(`${path}.${key}: unsupported property`);
      else if (typeof schema.additionalProperties === "object")
        errors.push(...validate(value, schema.additionalProperties, rootSchema, `${path}.${key}`));
    }
  }

  return errors;
}

const configSchema = await load("../../config/schema/qe.schema.json");
const themeSchema = await load("../../themes/schema.json");
const stateSchema = await load("../../config/schema/theme-state.schema.json");
const notificationStateSchema = await load("../../config/schema/notification-state.schema.json");
const idleInhibitorStateSchema = await load("../../config/schema/idle-inhibitor-state.schema.json");
const helpSchema = await load("../../config/schema/help.schema.json");

for (const path of ["../../config/qe.json", "../fixtures/config/valid.json"])
  assert.deepEqual(validate(await load(path), configSchema), [], path);
for (const path of ["../../themes/poimandres.json", "../../themes/gruvbox.json", "../fixtures/themes/valid.json"])
  assert.deepEqual(validate(await load(path), themeSchema), [], path);
assert.deepEqual(validate(await load("../fixtures/state/valid.json"), stateSchema), []);
assert.deepEqual(validate(await load("../fixtures/notification-state/valid.json"), notificationStateSchema), []);
assert.deepEqual(validate(await load("../fixtures/idle-inhibitor-state/valid.json"), idleInhibitorStateSchema), []);
assert.deepEqual(validate(await load("../../defaults/manifest.json"), await load("../../defaults/schema.json")), []);
assert.deepEqual(validate(await load("../../config/help.json"), helpSchema), []);

assert.ok(validate(await load("../fixtures/config/invalid-root.json"), configSchema).length > 0);
assert.ok(validate(await load("../fixtures/config/invalid-field.json"), configSchema).length > 0);
assert.ok(validate(await load("../fixtures/themes/missing-token.json"), themeSchema).length > 0);
assert.ok(validate(await load("../fixtures/state/invalid.json"), stateSchema).length > 0);
assert.ok(validate(await load("../fixtures/notification-state/invalid.json"), notificationStateSchema).length > 0);
assert.ok(validate(await load("../fixtures/idle-inhibitor-state/invalid.json"), idleInhibitorStateSchema).length > 0);

console.log("JSON schema fixtures passed");
