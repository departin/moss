/*
 * Vesktop, a desktop app aiming to give you a snappier Discord Experience
 * Copyright (c) 2026 Vendicated and Vesktop contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app, BrowserWindow } from "electron";
import { autoUpdater } from "electron-updater";
import { existsSync } from "fs";
import { join } from "path";
import { IpcEvents } from "shared/IpcEvents";
import { Millis } from "shared/utils/millis";

import { handle } from "./utils/ipcWrappers";

// only release builds ship app-update.yml
const enabled = app.isPackaged && existsSync(join(process.resourcesPath, "app-update.yml"));
let readyVersion: string | null = null;

autoUpdater.autoDownload = true;
autoUpdater.autoInstallOnAppQuit = true;
autoUpdater.logger = null;

autoUpdater.on("update-downloaded", info => {
    readyVersion = info.version;
    for (const win of BrowserWindow.getAllWindows()) win.webContents.send(IpcEvents.MOSS_UPDATE_READY, readyVersion);
});
autoUpdater.on("error", err => console.error("[Moss updater]", err?.message ?? err));

const check = async () => {
    if (!enabled) return null;
    const result = await autoUpdater.checkForUpdates().catch(() => null);
    return result?.isUpdateAvailable ? result.updateInfo.version : null;
};

if (enabled) {
    app.whenReady().then(() => {
        setTimeout(check, 15 * Millis.SECOND);
        setInterval(check, 6 * Millis.HOUR);
    });
}

handle(IpcEvents.UPDATER_IS_OUTDATED, () => false);
handle(IpcEvents.UPDATER_OPEN, () => { });
handle(IpcEvents.MOSS_UPDATE_STATUS, () => ({ enabled, readyVersion, version: app.getVersion() }));
handle(IpcEvents.MOSS_UPDATE_CHECK, () => check());
handle(IpcEvents.MOSS_UPDATE_INSTALL, () => {
    if (readyVersion) autoUpdater.quitAndInstall(true, true);
});
