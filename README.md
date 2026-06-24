# Footshape Scanner: 3D Foot Scanning at your fingertips

Footshape Scanner is an iOS application that allows users to scan their feet using an iOS device (FaceID / TrueDepth / LiDAR enabled) and generate accurate 3D models. Users can capture precise 3D dimensions of feet for podiatry, custom orthotics, ergonomic shoe fitting, and custom footwear. 

Once you’ve installed the app, you can create a new scan by rotating the phone around the subject. Footshape Scanner uses the TrueDepth sensor and LiDAR camera coupled with SLAM algorithms to capture a point cloud map and generate a 3D mesh.

The application automatically converts the scanned footshape into high-quality **USDZ** and **GLB** 3D formats, allowing for easy sharing, editing, and integration into CAD systems.

## Tech Stack
* **iOS App**: Swift, Apple ARKit, and StandardCyborg Fusion SDK
* **Backend Engine**: Python for mesh processing
