import QtQuick
import Quickshell.Services.Pam

QtObject {
    id: root

    required property int attemptId
    readonly property bool active: context.active
    readonly property bool responseRequired: context.responseRequired
    readonly property bool responseVisible: context.responseVisible
    readonly property string message: context.message
    signal completed(string result, int attemptId)
    signal failed(int attemptId)

    function start() {
        return context.start();
    }

    function respond(response) {
        if (context.responseRequired) context.respond(response);
    }

    function abort() {
        context.abort();
    }

    property PamContext context: PamContext {
        config: "login"
        onCompleted: result => root.completed(
            result === PamResult.Success ? "success" : "failed",
            root.attemptId
        )
        onError: root.failed(root.attemptId)
    }
}
