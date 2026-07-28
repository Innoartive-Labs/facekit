# CHANGELOG

## 1.0.0

- Initial release of **FaceKit**: 100% pure Dart offline facial recognition engine.
- **Detector**: Multi-scale image pyramid ($24 \times 24$ sliding window) with IoU NMS and adaptive contrast fallback pass.
- **Landmarks & Alignment**: 68 primary facial keypoints, 468 3D mesh interpolation, pupil intensity minimum search, and similarity transformation alignment to $112 \times 112$ canonical format.
- **Spatial Feature Descriptor**: 128-dimensional spatial cell LBP texture + HOG gradient feature descriptor projected onto an L2 unit hypersphere vector.
- **Nearest-Neighbor Matcher**: Fast in-memory nearest-neighbor matching using Cosine Similarity and Euclidean Distance metrics.
- **Persistence & Serialization**: Custom CRC32-checked `.face` binary format, JSON database import/export, and raw 128D embedding vector extraction for external SQL/NoSQL databases.
