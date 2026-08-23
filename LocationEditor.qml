pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  required property var model

  signal closed()

  property string tabMode: "search"
  property string searchQuery: ""
  property var searchResults: []
  property bool searchLoading: false
  property string searchError: ""
  property int searchGeneration: 0

  property string editLabel: ""
  property string editLatitude: ""
  property string editLongitude: ""
  property string editTimeZone: ""
  property string editElevation: "0"
  property string validationError: ""
  property string infoMessage: ""
  property bool saving: false
  property bool resetAllArmed: false
  property bool weatherImportRequested: false

  implicitWidth: Style.space(390)
  implicitHeight: editorColumn.implicitHeight
  focus: visible

  Accessible.role: Accessible.Pane
  Accessible.name: "Moonshot location settings"

  function syncFromModel() {
    root.editLabel = root.model.locationLabel || ""
    root.editLatitude = root.model.latitude !== null && root.model.latitude !== undefined
      ? String(root.model.latitude) : ""
    root.editLongitude = root.model.longitude !== null && root.model.longitude !== undefined
      ? String(root.model.longitude) : ""
    root.editTimeZone = root.model.timeZone || ""
    root.editElevation = root.model.elevationM !== null && root.model.elevationM !== undefined
      ? String(root.model.elevationM) : "0"
    root.validationError = ""
    root.infoMessage = ""
    root.saving = false
    root.resetAllArmed = false
    root.weatherImportRequested = false
    resetConfirmTimer.stop()
  }

  function cancel() {
    root.syncFromModel()
    root.closed()
  }

  function validateAndSave() {
    root.validationError = ""
    root.infoMessage = ""

    var lat = Number(root.editLatitude.trim())
    var lon = Number(root.editLongitude.trim())
    var elev = Number(root.editElevation.trim() || "0")
    var tzName = root.editTimeZone.trim()

    if (root.editLatitude.trim() === "" || !isFinite(lat) || lat < -90 || lat > 90) {
      root.validationError = "Latitude must be between −90 and 90."
      return
    }
    if (root.editLongitude.trim() === "" || !isFinite(lon) || lon < -180 || lon > 180) {
      root.validationError = "Longitude must be between −180 and 180."
      return
    }
    if (!isFinite(elev) || elev < -500 || elev > 9000) {
      root.validationError = "Elevation must be between −500 and 9,000 meters."
      return
    }
    if (tzName === "" || /\s/.test(tzName)) {
      root.validationError = "Enter an IANA time zone such as America/Chicago."
      return
    }

    var label = root.editLabel.trim() || (lat.toFixed(2) + ", " + lon.toFixed(2))
    root.saving = true
    root.model.validateAndSaveLocation(label, lat, lon, tzName, elev)
  }

  function compactPlaceLabel(place) {
    var label = String(place && place.locationLabel ? place.locationLabel : "Saved place")
    return label.length > 24 ? label.substring(0, 23) + "…" : label
  }

  function savedPlaceTooltip(place) {
    if (!place) return "Use saved place"
    return String(place.locationLabel || "Saved place") + " · " + String(place.timeZone || "")
  }

  function activateSavedPlace(place) {
    root.validationError = ""
    root.infoMessage = ""
    root.resetAllArmed = false
    resetConfirmTimer.stop()
    if (root.model.isActiveLocation(place)) {
      root.closed()
      return
    }
    root.saving = true
    root.model.activateSavedLocation(place)
  }

  function requestResetAll() {
    root.validationError = ""
    if (!root.resetAllArmed) {
      root.resetAllArmed = true
      root.infoMessage = "Select Confirm reset to clear the active location and forget every saved place."
      resetConfirmTimer.restart()
      return
    }
    resetConfirmTimer.stop()
    root.resetAllArmed = false
    root.model.resetLocations()
    root.closed()
  }

  function normalizedSearchResults(doc) {
    if (!doc || !Array.isArray(doc.results)) return []
    var out = []
    for (var i = 0; i < doc.results.length && out.length < 5; i++) {
      var candidate = doc.results[i]
      var lat = Number(candidate.latitude)
      var lon = Number(candidate.longitude)
      var tz = typeof candidate.timezone === "string" ? candidate.timezone.trim() : ""
      var name = typeof candidate.name === "string" ? candidate.name.trim() : ""
      if (!isFinite(lat) || lat < -90 || lat > 90 ||
          !isFinite(lon) || lon < -180 || lon > 180 || name === "" || tz === "") continue
      out.push({
        name: name.substring(0, 96),
        admin1: typeof candidate.admin1 === "string" ? candidate.admin1.trim().substring(0, 96) : "",
        country: typeof candidate.country === "string" ? candidate.country.trim().substring(0, 96) : "",
        latitude: lat,
        longitude: lon,
        timezone: tz
      })
    }
    return out
  }

  function performSearch() {
    var query = root.searchQuery.trim()
    root.searchGeneration++
    var generation = root.searchGeneration
    if (query.length < 2) {
      root.searchResults = []
      root.searchLoading = false
      return
    }

    root.searchLoading = true
    root.searchError = ""
    var url = "https://geocoding-api.open-meteo.com/v1/search?name="
      + encodeURIComponent(query) + "&count=5&language=en&format=json"
    var xhr = new XMLHttpRequest()
    var oversized = false
    xhr.open("GET", url, true)
    xhr.timeout = 5000
    xhr.onreadystatechange = function() {
      if (generation !== root.searchGeneration) return
      if (xhr.readyState === XMLHttpRequest.LOADING) {
        try {
          if (xhr.responseText && xhr.responseText.length > 65536) {
            oversized = true
            xhr.abort()
            root.searchLoading = false
            root.searchError = "The search response was too large."
          }
        } catch (e) {}
        return
      }
      if (xhr.readyState !== XMLHttpRequest.DONE) return

      root.searchLoading = false
      if (oversized) return
      if (xhr.status !== 200) {
        root.searchError = "Location search is unavailable. Manual entry still works offline."
        return
      }
      try {
        if (xhr.responseText.length > 65536) throw new Error("oversized")
        root.searchResults = root.normalizedSearchResults(JSON.parse(xhr.responseText))
        if (root.searchResults.length === 0) root.searchError = "No matching cities found."
      } catch (e) {
        root.searchResults = []
        root.searchError = "The location search response was invalid."
      }
    }
    xhr.ontimeout = function() {
      if (generation !== root.searchGeneration) return
      root.searchLoading = false
      root.searchError = "Location search timed out. Manual entry still works offline."
    }
    xhr.send()
  }

  function chooseSearchResult(candidate) {
    if (!candidate) return
    root.editLabel = candidate.name + (candidate.country ? ", " + candidate.country : "")
    root.editLatitude = String(candidate.latitude)
    root.editLongitude = String(candidate.longitude)
    root.editTimeZone = candidate.timezone
    root.editElevation = "0"
    root.tabMode = "manual"
    root.infoMessage = "Search result selected. Review the values, then save."
    Qt.callLater(function() { latitudeField.forceActiveFocus() })
  }

  function importWeather() {
    root.validationError = ""
    root.infoMessage = ""
    root.weatherImportRequested = true
    weatherFile.reload()
  }

  FileView {
    id: weatherFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    printErrors: false
    onLoaded: {
      if (!root.weatherImportRequested) return
      root.weatherImportRequested = false
      try {
        var data = JSON.parse(text())
        if (!data || data.latitude === undefined || data.longitude === undefined)
          throw new Error("missing coordinates")
        root.editLatitude = String(data.latitude)
        root.editLongitude = String(data.longitude)
        if (data.name) root.editLabel = String(data.name)
        if (data.timezone) root.editTimeZone = String(data.timezone)
        root.tabMode = "manual"
        root.infoMessage = root.editTimeZone === ""
          ? "Weather coordinates imported. Add the location’s IANA time zone before saving."
          : "Weather location imported. Review the values before saving."
      } catch (e) {
        root.validationError = "Omarchy Weather does not have importable coordinates."
      }
    }
    onLoadFailed: {
      if (!root.weatherImportRequested) return
      root.weatherImportRequested = false
      root.validationError = "Omarchy Weather does not have a saved location."
    }
  }

  Timer {
    id: searchDebounce
    interval: 350
    repeat: false
    onTriggered: root.performSearch()
  }

  Timer {
    id: resetConfirmTimer
    interval: 5000
    repeat: false
    onTriggered: {
      root.resetAllArmed = false
      if (root.infoMessage.indexOf("Select Confirm reset") === 0) root.infoMessage = ""
    }
  }

  Connections {
    target: root.model
    function onLocationSaveFinished(success, message) {
      root.saving = false
      if (success) root.closed()
      else root.validationError = message || "The location could not be validated."
    }
  }

  Keys.onEscapePressed: function(event) {
    root.cancel()
    event.accepted = true
  }

  onVisibleChanged: {
    if (!visible) return
    root.syncFromModel()
    Qt.callLater(function() {
      if (root.tabMode === "search") searchField.forceActiveFocus()
      else latitudeField.forceActiveFocus()
    })
  }

  Column {
    id: editorColumn
    width: parent.width
    spacing: Style.spacing.rowGap

    Item {
      width: parent.width
      height: Math.max(editorTitle.implicitHeight, cancelButton.implicitHeight)

      Column {
        id: editorTitle
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
          text: "Location"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }
        Text {
          text: "Coordinates stay local. City search is optional."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Ui.Button {
        id: cancelButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Cancel"
        focusable: true
        foreground: Color.popups.text
        onClicked: root.cancel()
      }
    }

    Ui.PanelSeparator { foreground: Color.popups.text }

    Column {
      id: savedPlacesSection
      width: parent.width
      visible: root.model.savedLocations.length > 0
      spacing: Style.spacing.sm

      Item {
        width: parent.width
        height: Math.max(savedPlacesTitle.implicitHeight, resetAllButton.implicitHeight)

        Ui.PanelSectionHeader {
          id: savedPlacesTitle
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Saved places"
          foreground: Color.popups.text
        }

        Ui.Button {
          id: resetAllButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: root.resetAllArmed ? "Confirm reset" : "Reset all"
          tooltipText: "Clear the active location and forget all saved places"
          focusable: true
          enabled: !root.saving
          foreground: root.resetAllArmed ? Color.urgent : Color.popups.text
          onClicked: root.requestResetAll()
        }
      }

      Grid {
        id: savedPlacesGrid
        width: parent.width
        columns: 2
        columnSpacing: Style.spacing.controlGap
        rowSpacing: Style.spacing.controlGap
        readonly property int rowCount: Math.ceil(root.model.savedLocations.length / columns)
        readonly property real cellWidth: (width - columnSpacing) / columns
        height: rowCount * Style.spacing.controlHeight
          + Math.max(0, rowCount - 1) * rowSpacing

        Repeater {
          model: root.model.savedLocations
          delegate: Ui.Button {
            id: savedPlaceButton
            required property var modelData
            width: savedPlacesGrid.cellWidth
            height: Style.spacing.controlHeight
            text: root.compactPlaceLabel(savedPlaceButton.modelData)
            tooltipText: root.savedPlaceTooltip(savedPlaceButton.modelData)
            selected: root.model.isActiveLocation(savedPlaceButton.modelData)
            bordered: true
            focusable: true
            enabled: !root.saving
            foreground: Color.popups.text
            onClicked: root.activateSavedPlace(savedPlaceButton.modelData)
          }
        }
      }
    }

    Row {
      spacing: Style.spacing.controlGap

      Ui.Button {
        text: "City search"
        selected: root.tabMode === "search"
        focusable: true
        foreground: Color.popups.text
        onClicked: {
          root.tabMode = "search"
          Qt.callLater(searchField.forceActiveFocus)
        }
      }
      Ui.Button {
        text: "Manual coordinates"
        selected: root.tabMode === "manual"
        focusable: true
        foreground: Color.popups.text
        onClicked: {
          root.tabMode = "manual"
          Qt.callLater(latitudeField.forceActiveFocus)
        }
      }
    }

    Column {
      width: parent.width
      visible: root.tabMode === "search"
      spacing: Style.spacing.sm

      Ui.TextField {
        id: searchField
        width: parent.width
        foreground: Color.popups.text
        placeholderText: "Search city or town"
        text: root.searchQuery
        Accessible.name: "City search"
        onTextChanged: {
          root.searchQuery = text
          searchDebounce.restart()
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Search sends this query to Open-Meteo over HTTPS. Core astronomy never uses the network."
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        visible: root.searchLoading
        text: "Searching…"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        width: parent.width
        visible: root.searchError !== ""
        wrapMode: Text.WordWrap
        text: root.searchError
        color: Color.urgent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      Column {
        width: parent.width
        spacing: Style.space(2)
        visible: root.searchResults.length > 0

        Repeater {
          model: root.searchResults
          delegate: Ui.Button {
            id: resultButton
            required property var modelData
            width: parent.width
            leftAlign: true
            focusable: true
            foreground: Color.popups.text
            text: resultButton.modelData.name
              + (resultButton.modelData.admin1 ? ", " + resultButton.modelData.admin1 : "")
              + (resultButton.modelData.country ? ", " + resultButton.modelData.country : "")
            onClicked: root.chooseSearchResult(resultButton.modelData)
          }
        }
      }
    }

    Column {
      width: parent.width
      visible: root.tabMode === "manual"
      spacing: Style.spacing.sm

      Row {
        width: parent.width
        spacing: Style.spacing.controlGap

        Column {
          width: (parent.width - Style.spacing.controlGap) / 2
          spacing: Style.space(2)
          Text {
            text: "Latitude"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
          Ui.TextField {
            id: latitudeField
            width: parent.width
            foreground: Color.popups.text
            placeholderText: "33.0"
            text: root.editLatitude
            Accessible.name: "Latitude"
            onTextChanged: root.editLatitude = text
          }
        }

        Column {
          width: (parent.width - Style.spacing.controlGap) / 2
          spacing: Style.space(2)
          Text {
            text: "Longitude"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
          Ui.TextField {
            width: parent.width
            foreground: Color.popups.text
            placeholderText: "−96.0"
            text: root.editLongitude
            Accessible.name: "Longitude"
            onTextChanged: root.editLongitude = text
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(2)
        Text {
          text: "IANA time zone"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Ui.TextField {
          width: parent.width
          foreground: Color.popups.text
          placeholderText: "America/Chicago"
          text: root.editTimeZone
          Accessible.name: "IANA time zone"
          onTextChanged: root.editTimeZone = text
        }
      }

      Row {
        width: parent.width
        spacing: Style.spacing.controlGap

        Column {
          width: parent.width * 0.66
          spacing: Style.space(2)
          Text {
            text: "Label"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
          Ui.TextField {
            width: parent.width
            foreground: Color.popups.text
            placeholderText: "Home"
            text: root.editLabel
            Accessible.name: "Location label"
            onTextChanged: root.editLabel = text
          }
        }

        Column {
          width: parent.width - parent.children[0].width - Style.spacing.controlGap
          spacing: Style.space(2)
          Text {
            text: "Elevation (m)"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
          Ui.TextField {
            width: parent.width
            foreground: Color.popups.text
            placeholderText: "0"
            text: root.editElevation
            Accessible.name: "Elevation in meters"
            onTextChanged: root.editElevation = text
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: root.infoMessage !== ""
      wrapMode: Text.WordWrap
      text: root.infoMessage
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }

    Text {
      width: parent.width
      visible: root.validationError !== ""
      wrapMode: Text.WordWrap
      text: root.validationError
      color: Color.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      Accessible.role: Accessible.AlertMessage
    }

    Ui.PanelSeparator { foreground: Color.popups.text }

    Item {
      width: parent.width
      height: Math.max(leftActions.implicitHeight, saveButton.implicitHeight)

      Row {
        id: leftActions
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.controlGap

        Ui.Button {
          text: "Import Weather"
          focusable: true
          enabled: !root.saving
          foreground: Color.popups.text
          onClicked: root.importWeather()
        }
        Ui.Button {
          text: "Clear active"
          tooltipText: "Use no location while keeping saved places"
          focusable: true
          enabled: !root.saving && root.model.locationConfigured
          foreground: Color.popups.text
          onClicked: {
            root.model.clearLocation()
            root.closed()
          }
        }
      }

      Ui.Button {
        id: saveButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.tabMode === "manual"
        text: root.saving ? "Validating…" : "Save location"
        selected: true
        enabled: !root.saving
        focusable: true
        foreground: Color.popups.text
        onClicked: root.validateAndSave()
      }
    }
  }
}
