import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var model

  signal closed()

  property string tabMode: "search"
  property string searchQuery: ""
  property var searchResults: []
  property bool searchLoading: false
  property string searchError: ""

  property string editLabel: ""
  property string editLatitude: ""
  property string editLongitude: ""
  property string editTimeZone: ""
  property string editElevation: "0"

  property string validationError: ""

  Component.onCompleted: {
    syncFromModel()
  }

  function syncFromModel() {
    editLabel = model.locationLabel || ""
    editLatitude = model.latitude !== null && model.latitude !== undefined ? String(model.latitude) : ""
    editLongitude = model.longitude !== null && model.longitude !== undefined ? String(model.longitude) : ""
    editTimeZone = model.timeZone || ""
    editElevation = model.elevationM ? String(model.elevationM) : "0"
    validationError = ""
  }

  function validateAndSave() {
    validationError = ""
    var lat = parseFloat(editLatitude.trim())
    var lon = parseFloat(editLongitude.trim())
    var elev = parseFloat(editElevation.trim() || "0")

    if (isNaN(lat) || lat < -90.0 || lat > 90.0) {
      validationError = "Latitude must be between -90.0 and 90.0"
      return
    }
    if (isNaN(lon) || lon < -180.0 || lon > 180.0) {
      validationError = "Longitude must be between -180.0 and 180.0"
      return
    }

    var tzName = editTimeZone.trim()
    var label = editLabel.trim() || (lat.toFixed(2) + ", " + lon.toFixed(2))

    model.saveLocation(label, lat, lon, tzName, elev)
    root.closed()
  }

  function importWeather() {
    weatherFile.reload()
  }

  FileView {
    id: weatherFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    printErrors: false
    onLoaded: {
      try {
        var raw = text()
        if (!raw) return
        var data = JSON.parse(raw)
        if (data && data.latitude !== undefined && data.longitude !== undefined) {
          root.editLatitude = String(data.latitude)
          root.editLongitude = String(data.longitude)
          if (data.name) root.editLabel = String(data.name)
          root.tabMode = "manual"
          root.validationError = "Imported from Omarchy Weather"
        }
      } catch (e) {
        root.validationError = "Could not read weather settings"
      }
    }
  }

  Timer {
    id: searchDebounce
    interval: 400
    repeat: false
    onTriggered: {
      performSearch()
    }
  }

  function performSearch() {
    var q = searchQuery.trim()
    if (q.length < 2) {
      searchResults = []
      searchLoading = false
      return
    }
    searchLoading = true
    searchError = ""

    var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(q) + "&count=5&language=en&format=json"
    var xhr = new XMLHttpRequest()
    xhr.open("GET", url, true)
    xhr.timeout = 5000
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        searchLoading = false
        if (xhr.status === 200) {
          try {
            var doc = JSON.parse(xhr.responseText)
            if (doc && doc.results && doc.results.length > 0) {
              searchResults = doc.results
            } else {
              searchResults = []
              searchError = "No matching cities found."
            }
          } catch (e) {
            searchError = "Failed to parse search results."
          }
        } else {
          searchError = "Network error searching locations."
        }
      }
    }
    xhr.ontimeout = function() {
      searchLoading = false
      searchError = "Search timed out."
    }
    xhr.send()
  }

  Column {
    anchors.fill: parent
    spacing: Style.spacing.rowGap

    Row {
      width: parent.width
      spacing: Style.spacing.controlGap

      Button {
        text: "City Search"
        selected: root.tabMode === "search"
        onClicked: { root.tabMode = "search" }
      }

      Button {
        text: "Manual Coordinates"
        selected: root.tabMode === "manual"
        onClicked: { root.tabMode = "manual" }
      }

      Item { width: Style.spacing.md; height: 1 }

      Button {
        text: "✕"
        tooltipText: "Cancel"
        onClicked: { root.syncFromModel(); root.closed() }
      }
    }

    Column {
      width: parent.width
      visible: root.tabMode === "search"
      spacing: Style.spacing.sm

      TextField {
        id: searchField
        width: parent.width
        placeholderText: "Type a city (e.g. Dallas, London, Tokyo)..."
        text: root.searchQuery
        onTextChanged: {
          root.searchQuery = text
          searchDebounce.restart()
        }
      }

      Text {
        text: "Search queries Open-Meteo Geocoding API via HTTPS."
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.muted
      }

      Text {
        visible: root.searchLoading
        text: "Searching..."
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.accent
      }

      Text {
        visible: root.searchError !== ""
        text: root.searchError
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.urgent
      }

      Column {
        width: parent.width
        spacing: 2
        visible: root.searchResults.length > 0

        Repeater {
          model: root.searchResults
          delegate: Button {
            required property var modelData
            width: parent.width
            leftAlign: true
            text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "") + (modelData.country ? ", " + modelData.country : "")
            onClicked: {
              root.editLabel = modelData.name + (modelData.country ? ", " + modelData.country : "")
              root.editLatitude = String(modelData.latitude)
              root.editLongitude = String(modelData.longitude)
              root.editTimeZone = modelData.timezone || ""
              root.validateAndSave()
            }
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
          spacing: 2
          Text {
            text: "Latitude"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            color: Color.foreground
          }
          TextField {
            width: parent.width
            placeholderText: "33.0"
            text: root.editLatitude
            onTextChanged: { root.editLatitude = text }
          }
        }

        Column {
          width: (parent.width - Style.spacing.controlGap) / 2
          spacing: 2
          Text {
            text: "Longitude"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            color: Color.foreground
          }
          TextField {
            width: parent.width
            placeholderText: "-96.0"
            text: root.editLongitude
            onTextChanged: { root.editLongitude = text }
          }
        }
      }

      Column {
        width: parent.width
        spacing: 2
        Text {
          text: "IANA Time Zone (optional)"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.foreground
        }
        TextField {
          width: parent.width
          placeholderText: "America/Chicago (leave blank for local system)"
          text: root.editTimeZone
          onTextChanged: { root.editTimeZone = text }
        }
      }

      Column {
        width: parent.width
        spacing: 2
        Text {
          text: "Label (optional)"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.foreground
        }
        TextField {
          width: parent.width
          placeholderText: "Home, Celina, TX"
          text: root.editLabel
          onTextChanged: { root.editLabel = text }
        }
      }

      Text {
        visible: root.validationError !== ""
        text: root.validationError
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.urgent
      }
    }

    Row {
      width: parent.width
      spacing: Style.spacing.controlGap

      Button {
        text: "Import Weather"
        tooltipText: "Import coordinates from Omarchy Weather"
        onClicked: { root.importWeather() }
      }

      Button {
        text: "Clear Location"
        tooltipText: "Reset to unconfigured global mode"
        onClicked: { root.model.clearLocation(); root.closed() }
      }

      Item { width: Style.spacing.md; height: 1 }

      Button {
        text: "Save"
        selected: true
        onClicked: { root.validateAndSave() }
      }
    }
  }
}
