/*
 * Vesktop, a desktop app aiming to give you a snappier Discord Experience
 * Copyright (c) 2023 Vendicated and Vencord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app, BrowserWindow } from "electron";
import { join } from "path";
import { SplashProps } from "shared/browserWinProperties";
import { STATIC_DIR } from "shared/paths";

import { VencordSettings } from "./settings";

export let splash: BrowserWindow | undefined;
import { loadView } from "./vesktopStatic";

const totalTasks = 9;
let doneTasks = 0;

let splashReady = false;
const pendingSplashMessages: Array<[string, unknown]> = [];

function sendToSplash(channel: string, payload: unknown) {
    if (!splash || splash.isDestroyed()) return;
    if (splashReady) {
        splash.webContents.send(channel, payload);
    } else {
        pendingSplashMessages.push([channel, payload]);
    }
}

export async function createSplashWindow(startMinimized = false) {
    splash = new BrowserWindow({
        ...SplashProps,
        ...(process.platform === "win32"
            ? { icon: join(STATIC_DIR, "icon.ico") }
            : process.platform === "linux"
              ? { icon: join(STATIC_DIR, "icon.png") }
              : {}),
        show: !startMinimized,
        webPreferences: {
            preload: join(__dirname, "splashPreload.js")
        }
    });

    splash.webContents.setMaxListeners(15);
    loadView(splash, "splash.html", new URLSearchParams({ v: app.getVersion() }));

    const theme = VencordSettings.store.plugins?.MossTheme ?? {};
    const stops = [theme.accent, theme.accent2, theme.accent3].filter((c?: string) => /^#[0-9a-f]{6}$/i.test(c ?? ""));
    const custom = theme.colorMode === "custom" && stops.length > 0;
    const accent = custom ? stops[0] : theme.colorMode === "discord" ? "#5865F2" : "#9AD4B1";
    const fill = custom && theme.accentStyle === "gradient" && stops.length > 1
        ? `linear-gradient(90deg, ${stops.join(", ")})`
        : `linear-gradient(90deg, color-mix(in srgb, ${accent} 55%, black), ${accent})`;
    splash.webContents.insertCSS(`:root { --accent: ${accent}; --fill: ${fill}; }`);

    splash.webContents.once("did-finish-load", () => {
        if (!splash || splash.isDestroyed()) return;
        splashReady = true;
        for (const [channel, payload] of pendingSplashMessages) {
            if (!splash || splash.isDestroyed()) return;
            splash.webContents.send(channel, payload);
        }
        pendingSplashMessages.length = 0;
    });

    splash.on("closed", () => {
        splashReady = false;
        pendingSplashMessages.length = 0;
    });

    return splash;
}

export function addSplashLog() {
    if (!splash || splash.isDestroyed()) return;
    doneTasks++;
    const percentage = Math.min(100, Math.round((doneTasks / totalTasks) * 100));
    sendToSplash("update-splash-progress", percentage);
}

export function getSplash() {
    return splash;
}

export function updateSplashMessage(message: string) {
    sendToSplash("update-splash-message", message);
}

export function closeSplash() {
    if (!splash || splash.isDestroyed()) return;
    const closing = splash;
    closing.webContents.send("splash-fade-out");
    setTimeout(() => closing.isDestroyed() || closing.destroy(), 240);
}
