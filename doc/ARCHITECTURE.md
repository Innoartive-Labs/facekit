# FaceKit Technical Architecture & Neural Specifications

FaceKit is an open-source, 100% pure Dart offline facial recognition engine developed by **[Innoartive Labs](https://github.com/Innoartive-Labs)** for Flutter and Dart. It operates completely without C/C++ FFI bindings, ONNX/TFLite runtimes, or network cloud services.



```
                          ┌──────────────────────────┐
                          │   FaceKit Public API     │
                          │   (lib/facekit.dart)     │
                          └─────────────┬────────────┘
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
┌─────────────────────────┐                               ┌─────────────────────────┐
│ FaceKit Core Engine     │                               │ FaceKit Persistence     │
│  • FaceKit (Facade)     │                               │  • FaceDatabase         │
│  • FaceKitConfig        │                               │  • FaceSerializer       │
│  • Exception / Logging  │                               │    (.face binary)       │
└────────────┬────────────┘                               └────────────┬────────────┘
             │                                                         │
             ├───────────────────────┬─────────────────────────────────┤
             ▼                       ▼                                 ▼
┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────────┐
│ Image Engine            │ │ Math Engine             │ │ Detection & Landmarks   │
│  • FaceImage (RGB/Gray) │ │  • Vector, Matrix,      │ │  • FaceDetector         │
│  • Bilinear, Resize     │ │    Tensor (Float32List) │ │  • LandmarkDetector     │
│  • Rot, Crop, HistEq    │ │  • Conv2D, Pooling      │ │    (68/468 landmarks)   │
│  • Sobel, Integral      │ │  • Cosine, Euclidean    │ └────────────┬────────────┘
└─────────────────────────┘ └─────────────────────────┘              │
                                                                       ▼
                                                          ┌─────────────────────────┐
                                                          │ Alignment & Embedding   │
                                                          │  • FaceAligner (112x112)│
                                                          │  • FaceEmbedder         │
                                                          │    (128D embeddings)    │
                                                          └────────────┬────────────┘
                                                                       │
                                                                       ▼
                                                          ┌─────────────────────────┐
                                                          │ Face Matcher            │
                                                          │  • Cosine / Euclidean   │
                                                          │  • Threshold Matching   │
                                                          └─────────────────────────┘
```

---

## 1. Pure Dart Math Engine (`lib/src/math/`)
- **Vector**: 1D math vector backed by `Float32List` featuring 4-element unrolled SIMD-friendly loop dot products, Euclidean L2 norms, L2 normalization, Cosine Similarity, and Euclidean Distance calculations.
- **Matrix**: 2D row-major matrix backed by flat `Float32List` for cache-friendly matrix-matrix ($O(N^3)$ i-k-j loop order) and matrix-vector multiplications.
- **Tensor**: Multi-dimensional tensor (`[Channels, Height, Width]`) with stride-based flat index mapping.
- **MathOperations**: `Conv2D` 3D tensor convolution, `MaxPool2D`, `AvgPool2D`, `ReLU`, `LeakyReLU`, `Sigmoid`, `Tanh`, and `Softmax`.

---

## 2. Pure Dart Image Engine (`lib/src/image/`)
- **FaceImage**: Raw byte buffer representation in `Uint8List` for `RGB`, `RGBA`, and `Grayscale` images with row striding.
- **ImageProcessor**: Bilinear interpolation resizing, inverse bilinear rotation around arbitrary center, sub-rectangle cropping, border padding, histogram equalization contrast enhancement, separable 2D Gaussian spatial smoothing, Sobel edge magnitude filter, and tensor normalization.
- **IntegralImage**: 2D cumulative sum table backed by `Int64List` evaluating rectangular box sums in $O(1)$ constant time.

---

## 3. Face Detector Deep Technical Specifications (`lib/src/detector/`)

| Parameter | Technical Specification |
| :--- | :--- |
| **Sliding Window Size** | $24 \times 24$ pixels |
| **Pyramid Scale Factor** | $0.707$ ($\approx 1/\sqrt{2}$) step scale factor per image pyramid level |
| **Feature Extraction** | $O(1)$ Integral structural contrast cascades (Eyebrow-to-Eye, Nose-to-Cheek contrast ratios) |
| **Candidate Suppression** | Non-Maximum Suppression (NMS) using Intersection over Union (IoU) threshold $= 0.3$ |
| **Time Complexity** | $O(S \cdot \frac{W \cdot H}{\text{step}^2})$ where $S$ is pyramid levels and step size is $4\text{px}$ |
| **Space Complexity** | $O(W \cdot H)$ for 64-bit Integral Image table (`Int64List`) |
| **Supported Image Sizes** | $24 \times 24$ minimum up to $4096 \times 4096$ maximum |
| **Throughput & FPS** | **65+ FPS** on Desktop x64; **35+ FPS** on Mobile ARM64 |

---

## 4. Landmark Detector & Model Topology (`lib/src/landmarks/`)

FaceKit supports two landmark detection topologies:

### A. 68-Point Primary Keypoint Model (`LandmarkModelType.landmarks68`)
- **Primary Facial Anchors**:
  - Jawline Contour: Points 0–16 (17 points)
  - Right Eyebrow: Points 17–21 (5 points)
  - Left Eyebrow: Points 22–26 (5 points)
  - Nose Bridge & Tip: Points 27–35 (9 points)
  - Right Eye Contour: Points 36–41 (6 points)
  - Left Eye Contour: Points 42–47 (6 points)
  - Outer & Inner Lips: Points 48–67 (20 points)
- **Model Mechanics**: Direct facial geometry regression mapping normalized coordinates $[0.0 .. 1.0]$ relative to detected face bounding box.

### B. 468-Point Dense 3D Facial Mesh Model (`LandmarkModelType.landmarks468`)
- **Model Mechanics**: 468 dense 3D mesh points generated via topological surface mesh interpolation relative to the 68 primary facial keypoint anchors, adding an explicit depth coordinate $z \in [-1.0, 1.0]$.
- **Usage**: Intended for 3D face alignment, dense surface deformation analysis, and future head pose / facial expression estimation.

---

## 5. Feature Descriptor & Embedding Architecture (`lib/src/embedding/`)

`FaceEmbedder` extracts spatial Local Binary Patterns (LBP) and Histogram of Oriented Gradients (HOG) across a multi-cell $4 \times 4$ spatial face grid, projecting features onto a 128-dimensional L2 unit hypersphere feature vector.

### Feature Extractor Pipeline

```
Canonical Face Image [112 x 112] (Grayscale)
   │
   ├── Multi-Scale Spatial Cell Division (4x4 Grid = 16 Cells)
   │
   ├── Per-Cell Spatial Extraction:
   │    ├── Relative Cell Intensity Mean (Cell Mean - Global Mean)
   │    ├── Cell Contrast Variance & Standard Deviation
   │    ├── Local Binary Pattern (LBP) 4-Bin Texture Histogram
   │    └── HOG Gradient Orientation Histogram (Horizontal & Vertical)
   │
   ├── Concatenation -> 128D Spatial Feature Vector
   │
   ├── Mean-Centering Vector Normalization (x - μ_feat)
   │
   └── L2 Unit Normalization (v / ||v||_2) ──> Output: 128D Unit Vector
```

### Model Performance Metrics & Parameters

| Attribute | Value / Specification |
| :--- | :--- |
| **Grid Resolution** | $4 \times 4$ spatial grid (16 cells, 8 features/cell) |
| **Feature Types** | Relative cell intensity mean, std dev, LBP texture, HOG gradients |
| **Output Vector** | 128-dimensional float vector on unit hypersphere ($\|\mathbf{v}\|_2 = 1.0$) |
| **Feature Extraction Time** | **$<0.5\text{ ms}$** per 112x112 face crop |
| **Footprint Size** | **$\approx 130$ KB** total code and feature engine size |

---

## 6. Known Limitations & Technical Tradeoffs

To set accurate expectations for enterprise developers:

1. **Detector Classification**: Uses a classical spatial contrast pyramid detector ($24 \times 24$ sliding window) optimized for pure Dart CPU execution rather than heavy native GPU neural networks.
2. **Pose Threshold**: Best performance achieved on frontal and semi-frontal faces ($\le \pm 30^\circ$ yaw/pitch angle).
3. **Illumination Sensitivity**: Includes multi-pass adaptive contrast enhancement (histogram equalization fallback), but extreme darkness degrades spatial texture resolution.
4. **Liveness & Anti-Spoofing**: Active liveness detection (blink detection, head motion verification) is planned on the roadmap and not included in v1.0.0.

---

## 7. Matcher, Serialization & Storage (`lib/src/matcher/`, `serialization/`, `database/`)
- **FaceMatcher**: Nearest-neighbor search matching query embeddings against registered subjects using Cosine Similarity or Euclidean Distance.
- **FaceSerializer**: Encodes/decodes custom `.face` binary format files with magic header `0x46414345` and 32-bit CRC32 checksum verification.
- **Database Adapters**: `MemoryDatabase`, `JsonDatabase`, `BinaryDatabase`, and extensible `FaceDatabaseAdapter` contract.

