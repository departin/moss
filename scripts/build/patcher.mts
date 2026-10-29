// Builds "Moss for Discord", the installer that adds Moss to the official Discord app.
// Needs moss-core built next to this repo (../moss/dist/desktop.asar).
import { execFileSync } from "child_process";
import { existsSync, mkdirSync, readdirSync } from "fs";
import { homedir } from "os";
import { join } from "path";

import pkg from "../../package.json";

const root = join(import.meta.dir, "..", "..");
const asar = join(root, "..", "moss", "dist", "desktop.asar");
if (!existsSync(asar)) throw new Error(`Build moss-core first, ${asar} is missing`);

const cache = join(process.env.LOCALAPPDATA ?? join(homedir(), "AppData", "Local"), "electron-builder", "Cache");
const nsis = readdirSync(cache).filter(d => d.startsWith("nsis-")).flatMap(d => readdirSync(join(cache, d)).map(sub => join(cache, d, sub, "makensis.exe"))).find(existsSync);
if (!nsis) throw new Error("makensis wasn't found. Run electron-builder once so it downloads NSIS.");

mkdirSync(join(root, "dist"), { recursive: true });
const out = join(root, "dist", `Moss-for-Discord-Setup-${pkg.version}.exe`);
execFileSync(nsis, ["-V2", `-DVERSION=${pkg.version}`, `-DASAR=${asar}`, `-DICON=${join(root, "build", "icon.ico")}`, `-DOUTFILE=${out}`, join(root, "build", "patcher.nsi")], { stdio: "inherit" });
console.log(`Built ${out}`);
