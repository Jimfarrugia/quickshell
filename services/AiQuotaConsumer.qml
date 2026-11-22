import QtQml

// Quota consumer handle: while `active`, the owning surface keeps AI quota
// polling alive. Bind `active` to the surface's visibility; destruction
// releases the registration.
QtObject {
    id: root
    property bool active: false
    property bool registered: false

    function update() {
        if (root.active && !root.registered) {
            root.registered = true;
            AiQuotaService.registerConsumer();
        } else if (!root.active && root.registered) {
            root.registered = false;
            AiQuotaService.unregisterConsumer();
        }
    }
    onActiveChanged: update()
    Component.onCompleted: update()
    Component.onDestruction: if (root.registered) AiQuotaService.unregisterConsumer()
}
