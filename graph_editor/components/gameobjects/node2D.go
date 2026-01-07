embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"node\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/graph_editor/assets/atlas/editor.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.1
  }
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 30.0\n"
  "  y: 20.0\n"
  "}\n"
  "color {\n"
  "  y: 0.0\n"
  "  z: 0.0\n"
  "}\n"
  "outline {\n"
  "  x: 1.0\n"
  "  y: 1.0\n"
  "  z: 1.0\n"
  "}\n"
  "shadow {\n"
  "  x: 1.0\n"
  "  y: 1.0\n"
  "  z: 1.0\n"
  "}\n"
  "text: \"0\"\n"
  "font: \"/graph_editor/components/fonts/ffff12.font\"\n"
  "material: \"/graph_editor/components/materials/label.material\"\n"
  ""
  position {
    y: 14.0
  }
}
embedded_components {
  id: "sprite1"
  type: "sprite"
  data: "default_animation: \"node_back\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/graph_editor/assets/atlas/editor.atlas\"\n"
  "}\n"
  ""
  position {
    x: 2.5
    y: -3.0
  }
}
