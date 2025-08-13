HOW TO MAKE A CREATE MAP MARKERS FOR A MAP
==========================================

General format
--------------

Create a YAML file in Data/MapMarkers.

It should have the same name as the area/map. Example: Podunk.yaml

The YAML should be structured as an array, with as many elements as the number of markers you need for your map.

Markers include:
* Labels (for towns and important places)
* Icons (ATM, phone, hospital, hotel), including arrows (to warp to the next area)

Logically, every item in the the YAML array is a marker, which format is described below.

Marker format
-------------

### Required fields

> type:

String. Can be "label" or "icon".

> value:

String. Describes what the marker should display.
* If the marker is a label, "value" is the text to display in the label (or a CSV key for translated text).
* If the marker is an icon, "value" is the icon name; can be "atm", "burger", "home", "hospital", "hotel", "phone", "arrow", or "arrow_side".

> position:

Object. Specifies the marker position. It has two number fields, "x" and "y".

### Optional fields

> flip_h:

Boolean. Set to true if you want the marker to be flipped horizontally. Only applies to icon markers.

> flip_v:

Boolean. Set to true if you want the marker to be flipped vertically. Only applies to icon markers.

Reference
---------

See Data/MapMarkers/Podunk.yaml to get an example.

These YAMLs are parsed in Scripts/UI/MapScreen/MapScreen.gd