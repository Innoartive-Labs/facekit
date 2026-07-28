# FaceKit Roadmap & Future Expansion Plan

FaceKit's modular architecture is designed for long-term scalability. Future versions will introduce advanced computer vision capabilities without breaking existing public APIs.

---

## Completed Milestones (v1.0.0)

- [x] **Pure Dart Foundation**: Zero native C/C++ bindings, zero TensorFlow/ONNX dependencies.
- [x] **Math & Linear Algebra Engine**: Vector, Matrix, Tensor, Conv2D, MaxPool, activations, SIMD loop unrolling.
- [x] **Image Preprocessing**: Bilinear resize, rotation, crop, pad, hist-eq, Gaussian blur, Sobel, Integral Image.
- [x] **Face Detection**: Multi-scale pyramid detector with IoU Non-Maximum Suppression.
- [x] **Landmark Detection**: 68-point landmarks and dense 468-point 3D facial mesh points.
- [x] **Face Alignment**: Eye roll angle correction and $112 \times 112$ canonical normalization.
- [x] **128D Spatial Feature Descriptor**: Multi-cell spatial LBP & HOG feature extractor.

- [x] **Registration & Recognition API**: `register()`, `recognize()`, `recognizeMultiple()`, `delete()`, `update()`.
- [x] **Custom `.face` Binary Format**: Binary format serializer with CRC32 checksum data integrity.
- [x] **Local Database Adapters**: Memory, JSON, and Binary database storage adapters.

---

## Upcoming Roadmap (v1.1.0+)

### 1. Anti-Spoofing & Liveness Detection
- Texture analysis via Local Binary Patterns (LBP) to distinguish real human skin from printed photos or digital screens.
- Optical flow movement analysis across video frames.

### 2. Blink Detection & Eye State Analysis
- Eye Aspect Ratio (EAR) computation from 68-point landmarks:
  $$\text{EAR} = \frac{\|p_2 - p_6\| + \|p_3 - p_5\|}{2 \|p_1 - p_4\|}$$
- Real-time blink verification for interactive liveness checks.

### 3. Head Pose Estimation (Yaw, Pitch, Roll)
- 3D-to-2D Perspective-n-Point (PnP) solver in pure Dart estimating head orientation angles relative to camera.

### 4. Real-Time Face Tracking
- Kalman filter / IoU tracker for multi-object tracking across video frames.

### 5. Emotion & Expression Recognition
- Micro-expression classifier mapping landmark deformations to neutral, happy, sad, surprised, angry, and disgusted expressions.

### 6. Age & Gender Estimation
- Multi-task lightweight CNN heads estimating age ranges and gender classification.

### 7. SQLite Storage Adapter
- Native SQLite plugin adapter for persistent relational face database indexing (`FaceDatabaseSQLiteAdapter`).
