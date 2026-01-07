components {
  id: "editor_camera"
  component: "/graph_editor/scripts/editor_camera.script"
  properties {
    id: "zoom"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "camera"
  type: "camera"
  data: "aspect_ratio: 1.0\n"
  "fov: 0.7854\n"
  "near_z: 0.1\n"
  "far_z: 100.0\n"
  "auto_aspect_ratio: 1\n"
  "orthographic_zoom: 10.0\n"
  ""
}
