# Defold Graph Pathfinder Editor

A visual editor for creating and editing navigation graphs for the [Defold Graph Pathfinder](https://github.com/selimanac/defold-graph-pathfinder) extension.

![Graph Pathfinder Editor](/.github/editor.jpg?raw=true)

## Quick Start

1. Configure `game.project` → `[graph_editor]` section (see [Configuration](#configuration))
2. Run one of the editor collections:
   - `/examples/editors/editor_xy.collection` (for 2D/XY plane)
   - `/examples/editors/editor_xz.collection` (for 3D/XZ plane)


## Configuration

### Game.project Settings

The editor requires configuration in your `game.project` file. Open `game.project` and ensure the `[graph_editor]` section is properly configured:

```ini
[graph_editor]
# Plane configuration: XY for 2D games, XZ for 3D games
plane = XY

# Data folder where graph files are stored (relative to project root)
folder = data

# Maximum number of nodes allowed in the graph
max_nodes = 1024

# Maximum game object nodes (visual representations)
max_gameobject_nodes = 1024

# Maximum edges per node
max_edges_per_node = 16

# A* heap pool block size (affects pathfinding performance)
heap_pool_block_size = 128

# Maximum path length for caching
max_cache_path_length = 128

# Comma-separated list of graph files available in the editor
files = test2D.json,test3D.json,default.json
```

#### Plane Configuration

The `plane` setting determines the coordinate system:

- **`plane = XY`** (2D Mode)
  - X axis: horizontal (left-right)
  - Y axis: vertical (up-down)
  - Z axis: always 0 (depth)
  - Use for: Top-down 2D games, side-scrollers
  
- **`plane = XZ`** (3D Mode)
  - X axis: horizontal (left-right)
  - Y axis: always 0 (height - on ground plane)
  - Z axis: vertical (forward-backward)
  - Use for: 3D games with perspective camera, isometric games

> [!IMPORTANT]
>  This setting is configured once at initialization and affects:
>  - Node positioning
>  - Edge rendering
>  - Agent movement
>  - Pathfinding coordinate conversions
>  - All exported data
> 


---

## Running the Editor

### Option 1: Using the Bootstrap Collection

Set the main collection in `game.project`:
   ```ini
   [bootstrap]
   main_collection = /examples/editors/editor_xy.collectionc
   ```
   or
   ```ini
   [bootstrap]
   main_collection = /examples/editors/editor_xz.collectionc
   ```



### Option 2: Including Editor in Your Collection

You can embed the editor in your own collection:

Add a collection instance:
   - For XY plane (2D): Select `/graph_editor/graph_editor_2D.collection`
   - For XZ plane (3D): Select `/graph_editor/graph_editor_3D.collection`

---

## Editor Interface

The editor interface consists of several panels:

### Main Menu Bar

![Graph Pathfinder Editor](/.github/main_menu.jpg?raw=true)

Located at the top of the screen:

#### File Menu
- **New** - Create a new empty graph (clears current graph)
- **Load** - Open an existing graph file from the data folder
- **Save** - Save current graph (prompts for filename if new)
- **Export JSON** - Export graph to JSON format (creates `*_nodes.json` and `*_edges.json`)
- **Quit** - Exit the editor

#### View Menu
Toggle visibility of various elements:
- **Nodes** - Show/hide node visual representations
- **Edges** - Show/hide edge lines connecting nodes
- **Paths** - Show/hide pathfinding visualization
- **Smooth Paths** - Show/hide smoothed path visualization



### Tools Panel

![Graph Pathfinder Editor](/.github/tools_menu.jpg?raw=true)

Select the editing mode:

- **Add Node** - Click on the plane to place new navigation nodes
- **Remove Node** - Click on a node to delete it (also removes connected edges)
- **Move Node** - Click and drag nodes to reposition them
- **Add Edge** - Click two nodes to create a bidirectional connection
- **Add A→B Edge** - Click two nodes to create a one-way directional edge (from first to second)
- **Remove Edge** - Click on an edge line to delete it
- **Add Agent** - Place test agents that follow pathfinding results
- **Reset Camera** - Return camera to default position and zoom

### Settings Panel

![Graph Pathfinder Editor](/.github/settings_menu.jpg?raw=true)

Configuration for pathfinding and visualization:

#### Paths Tab

**AGENT MODE**
- Select how agents behave when following paths:
  - `NODE_TO_NODE` - Agents follow node-to-node paths
  - `PROJECTED_TO_NODE` - Agents path from arbitrary positions to nodes
  - `NODE_TO_PROJECTED` - Agents path from nodes to arbitrary positions
  - `PROJECTED_TO_PROJECTED` - Agents path between arbitrary positions

**NODE TO NODE**
- **Checkbox**: Enable/disable visualization
- **Start Node Id**: Source node for pathfinding test
- **Goal Node Id**: Destination node for pathfinding test
- **Max Path Length**: Maximum allowed path length (prevents infinite searches)

**PROJECTED TO NODE**
- **Checkbox**: Enable/disable visualization
- **Goal Node Id**: Destination node
- **Max Path Length**: Maximum allowed path length
- _Note: Start position is taken from mouse position_

**NODE TO PROJECTED**
- **Checkbox**: Enable/disable visualization
- **Start Node Id**: Source node
- **Max Path Length**: Maximum allowed path length
- _Note: Goal position is taken from mouse position_

**PROJECTED TO PROJECTED**
- **Checkbox**: Enable/disable visualization
- **Start Position**: Manual input for start coordinates (X, Y, Z)
- **Max Path Length**: Maximum allowed path length
- _Note: Goal position is taken from mouse position_

#### Smoothing Tab

Configure path smoothing algorithms:

- **Smooth Style** - Select smoothing algorithm:
  - `NONE` - No smoothing (raw waypoints)
  - `BEZIER_QUADRATIC` - Quadratic Bezier curves
  - `BEZIER_CUBIC` - Cubic Bezier curves
  - `BEZIER_ADAPTIVE` - Adaptive Bezier based on geometry
  - `CIRCULAR_ARC` - Circular arc interpolation

- **Sample for Segment** - Number of points per curve segment (higher = smoother but more points)
- **Curve Radius** (Quadratic) - Controls curve tightness (0.0-1.0)
- **Control Point Offset** (Cubic) - Offset for Bezier control points (0.0-1.0)
- **Tightness** (Adaptive) - How tight curves follow corners (0.0-1.0)
- **Roundness** (Adaptive) - Smoothness of curves (0.0-1.0)
- **Max Corner Distance** (Adaptive) - Maximum distance from corner to control point
- **Arc Radius** (Circular Arc) - Radius of circular arcs

### Stats Panel

![Graph Pathfinder Editor](/.github/stats.jpg?raw=true)

Displays real-time statistics:
- **Editor Status** - Current editing mode and last action
- **Path Cache** - Current entries, max capacity, hit rate percentage
- **Distance Cache** - Current size, hit/miss counts, hit rate
- **Spatial Index** - Cell count, edge count, average/max edges per cell

### Node Panel

![Graph Pathfinder Editor](/.github/node.jpg?raw=true)

Appears when a node is selected:
- **Pathfinder Node ID** - Internal ID used by pathfinding library
- **AABB ID** - Collision detection ID
- **UUID** - Unique identifier for the node
- **URL** - Defold game object URL
- **Position** - Editable X, Y, Z coordinates (manual positioning)

---

## Creating a Navigation Graph

Follow these steps to create a navigation graph:

### Step 1: Create a New Graph

1. Click **File → New** to start with a clean slate
2. The editor will clear any existing nodes and edges

### Step 2: Place Nodes

1. Select **Add Node** from the Tools panel
2. Click anywhere on the plane to place nodes
3. Nodes appear as numbered circles
4. Place nodes at key navigation points (corners, waypoints, decision points)

### Step 3: Connect Nodes with Edges

#### Bidirectional Edges (Two-Way)

1. Select **Add Edge** from the Tools panel
2. Click on the **first node** (starting point)
3. Click on the **second node** (ending point)
4. A line appears connecting the nodes
5. Agents can travel in both directions

#### Directional Edges (One-Way)

1. Select **Add A→B Edge** from the Tools panel
2. Click on the **first node** (from)
3. Click on the **second node** (to)
4. A line with a direction indicator appears
5. Agents can only travel from first to second node

### Step 4: Edit

#### Moving Nodes
1. Select **Move Node** from the Tools panel
2. Click and drag nodes to new positions
3. Connected edges update automatically

#### Deleting Nodes
1. Select **Remove Node** from the Tools panel
2. Click on the node to delete
3. All connected edges are automatically removed

#### Deleting Edges
1. Select **Remove Edge** from the Tools panel
2. Click on the edge line to delete it

> [!CAUTION]
> Edges are AABBs and they might become large, so you may accidentally delete the wrong edges. Use it wisely.

### Step 5: Save Your Graph

1. Click **File → Save**
2. If this is a new graph, enter a filename (without extension)
3. The graph is saved to the `data` folder in binary format
4. The filename will appear in the Load menu for future sessions

---

## Testing Pathfinding

The editor includes built-in pathfinding visualization:

### Node to Node Pathfinding

1. Go to **Settings → Paths → NODE TO NODE**
2. Check the **Node to Node** checkbox
3. Enter **Start Node Id** (any valid node number)
4. Enter **Goal Node Id** (any valid node number)
5. A path will be visualized between the nodes
6. **Status** shows `SUCCESS` (green) or error message (red)

### Projected to Node (From Mouse)

1. Go to **Settings → Paths → PROJECTED TO NODE**
2. Check the **Projected to Node** checkbox
3. Enter **Goal Node Id**
4. Move your mouse over the plane
5. A path from mouse position to the goal node is visualized

### Node to Projected (To Mouse)

1. Go to **Settings → Paths → NODE TO PROJECTED**
2. Check the **Node to Projected** checkbox
3. Enter **Start Node Id**
4. Move your mouse over the plane
5. A path from the start node to mouse position is visualized

### Projected to Projected (Mouse to Point)

1. Go to **Settings → Paths → PROJECTED TO PROJECTED**
2. Check the **Projected to Projected** checkbox
3. Enter **Start Position** coordinates manually
4. Move your mouse over the plane
5. A path from the start position to mouse is visualized

### Testing with Agents

1. Select **Add Agent** from the Tools panel
2. Click on the plane to place an agent
3. Configure pathfinding mode in **Settings → Paths → AGENT MODE**
4. Enable one of the pathfinding modes (Node to Node, etc.)
5. Agents will automatically follow the visualized paths

**Agent Behavior:**
- Agents move along paths at configurable speed
- They rotate to face movement direction
- Status can be: INACTIVE, ACTIVE, PAUSED, REPLANNING, ARRIVED
- Multiple agents can be placed to test complex scenarios

---

## Saving and Loading Graphs

### Saving

**Method 1: Save to Existing File**
1. Click **File → Save**
2. If you loaded an existing file, it will be overwritten
3. Status message appears: "Saved successfully!"

**Method 2: Save As New File**
1. Click **File → Save**
2. If this is a new graph, enter a filename
3. Don't include the `.json` extension (added automatically)
4. The file is saved in the `data` folder

> [!WARNING]
> **File Format:** Files are saved in Defold's binary format (`.json` extension is misleading - these are NOT text JSON files)


### Loading

1. Click **File → Load**
2. A dialog appears showing available files (from `game.project` → `graph_editor.files`)
3. Select a file from the list
4. Click **LOAD**
5. The graph is loaded and visualized

> [!NOTE]
> Only files listed in `game.project` will appear in the Load dialog. To add new files, edit the `files` setting in `game.project`:


```ini
[graph_editor]
files = file1.json,file2.json,myNewGraph.json
```

---

## Exporting for Your Game

When you're ready to use the graph in your game:

### Export to JSON

1. Click **File → Export JSON**
2. Enter a base filename (e.g., "level1")
3. Click **SAVE**
4. Two files are created in the `data` folder:
   - `level1_nodes.json` - Node data (true JSON format)
   - `level1_edges.json` - Edge data (true JSON format)

**These JSON files can be:**
- Loaded in your game at runtime
- Edited manually if needed
- Version controlled more easily than binary files
- Shared with other developers or tools

### File Structure

**Nodes JSON Format:**
```json
{
  "uuid-here": {
    "uuid": "uuid-here",
    "position": {
      "x": 10.5,
      "y": 0.0
    },
    "pathfinder_node_id": 1,
    "edges": {
      "edge-uuid-1": "from_node_id",
      "edge-uuid-2": "to_node_id"
    }
  }
}
```

**Edges JSON Format:**
```json
{
  "uuid-here": {
    "uuid": "uuid-here",
    "from_node_id": 1,
    "to_node_id": 2,
    "bidirectional": true
  }
}
```


