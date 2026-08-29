import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function showVolume(ok) {
        const pending = ok && Services.AudioService.operation === "pending";
        Services.OSDService.showItem({
            title: "Volume",
            detail: ok ? (Services.AudioService.muted ? "Muted" : `${Services.AudioService.displayVolumePercent}%`) : "Volume operation failed",
            value: Services.AudioService.displayVolumePercent,
            icon: Services.AudioService.muted ? "volume_off" : "volume_up",
            state: ok ? (pending ? "pending" : "confirmed") : "failed",
            replacementKey: "audio"
        });
        if (pending) Services.OSDService.trackOperation("audio");
        return ok;
    }

    function volumeUp(): bool { return root.showVolume(Services.AudioService.stepVolume(5)); }
    function volumeDown(): bool { return root.showVolume(Services.AudioService.stepVolume(-5)); }
    function toggleVolumeMute(): bool { return root.showVolume(Services.AudioService.toggleMuted()); }

    function microphoneMute(): bool {
        const ok = Services.AudioService.toggleMicrophoneMuted();
        Services.OSDService.showItem({
            title: "Microphone",
            detail: ok ? (Services.AudioService.microphoneMuted ? "Muted" : "Unmuted") : "Microphone operation failed",
            icon: Services.AudioService.microphoneMuted ? "mic_off" : "mic",
            state: ok ? "confirmed" : "failed",
            replacementKey: "microphone"
        });
        return ok;
    }

    function showBrightness(ok, keyboard): bool {
        const service = keyboard ? Services.KeyboardBrightnessService : Services.BrightnessService;
        const key = keyboard ? "keyboard-brightness" : "brightness";
        const title = keyboard ? "Keyboard brightness" : "Brightness";
        const value = service.pendingPercent >= 0 ? service.pendingPercent : service.confirmedPercent;
        const pending = ok && service.operation === "pending";
        if (pending) {
            Services.OSDService.trackOperation(key);
            return true;
        }
        Services.OSDService.showItem({ title: title, detail: ok ? `${value}%` : "Operation failed", value: value, icon: keyboard ? "keyboard" : "brightness_medium", state: ok ? (pending ? "pending" : "confirmed") : "failed", replacementKey: key });
        return ok;
    }

    function brightnessUp(): bool { return root.showBrightness(Services.BrightnessService.stepBrightness(5), false); }
    function brightnessDown(): bool { return root.showBrightness(Services.BrightnessService.stepBrightness(-5), false); }
    function keyboardBrightnessUp(): bool { return root.showBrightness(Services.KeyboardBrightnessService.stepBrightness(5), true); }
    function keyboardBrightnessDown(): bool { return root.showBrightness(Services.KeyboardBrightnessService.stepBrightness(-5), true); }

    function mediaAction(action): bool {
        const ok = action === "next" ? Services.MediaService.next()
            : (action === "previous" ? Services.MediaService.previous() : Services.MediaService.togglePlaying());
        Services.OSDService.showItem({ title: "Media", detail: ok ? Services.MediaService.description : "Media operation unavailable", icon: "music_note", state: ok ? "confirmed" : "failed", replacementKey: "media" });
        return ok;
    }

    IpcHandler {
        target: "qe-actions"
        function volumeUp(): bool { return root.volumeUp(); }
        function volumeDown(): bool { return root.volumeDown(); }
        function toggleVolumeMute(): bool { return root.toggleVolumeMute(); }
        function toggleMicrophoneMute(): bool { return root.microphoneMute(); }
        function brightnessUp(): bool { return root.brightnessUp(); }
        function brightnessDown(): bool { return root.brightnessDown(); }
        function keyboardBrightnessUp(): bool { return root.keyboardBrightnessUp(); }
        function keyboardBrightnessDown(): bool { return root.keyboardBrightnessDown(); }
        function mediaNext(): bool { return root.mediaAction("next"); }
        function mediaPrevious(): bool { return root.mediaAction("previous"); }
        function mediaToggle(): bool { return root.mediaAction("toggle"); }
        function notificationsToggle(): void { Services.SurfaceService.toggleNotificationCenter(); }
        function notificationsDismissAll(): void { Services.NotificationService.dismissAll(); }
    }
}
