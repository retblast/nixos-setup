pragma Singleton
import QtQuick
import Quickshell

// Shared notification history + shell panel state.
//
// Toasts.qml pushes a COPY of the fields (plain values - never the
// Notification wrapper, which the server deletes shortly after the
// handler returns; storing it would leave the history reading a
// dangling object).
//
// ListModel is a real QAbstractListModel: append/clear at runtime is
// safe against the quickshell 0.3.1 + Qt 6.11 Repeater-model
// reassignment segfault (see Toasts.qml for the crash context).
ListModel {
	// Entries are inserted at the top. Roles (defined by the first
	// insert, stable afterwards): appName, summary, body, time, urgent.

	// Panel arbitration: "notifcenter", "quicksettings" or "". Only one
	// panel window is mapped at a time; both panels and the clock dot
	// bind to this so they can never overlap.
	property string openPanel: ""

	// Unread counter for the clock dot. Notifications that arrive while
	// the center is open do not count as unread.
	property int unread: 0

	property int maxEntries: 20

	function push(appName, summary, body, urgent) {
		insert(0, {
			appName: appName || "",
			summary: summary || "",
			body: body || "",
			time: Qt.formatDateTime(new Date(), "HH:mm"),
			urgent: urgent === true
		});
		while (count > maxEntries)
			remove(count - 1);
		if (openPanel !== "notifcenter")
			unread = unread + 1;
	}

	function clearAll() {
		clear();
		unread = 0;
	}

	function seen() {
		unread = 0;
	}
}
