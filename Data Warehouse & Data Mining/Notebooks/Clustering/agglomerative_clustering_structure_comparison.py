# 1. Import Libraries
import matplotlib.pyplot as plt
from sklearn.datasets import make_moons, make_blobs
from sklearn.cluster import AgglomerativeClustering

# 2. Generate Structured Data (Moons)
X_structured, _ = make_moons(n_samples=300, noise=0.05, random_state=42)

# 3. Generate Unstructured Data (Random Blobs)
X_unstructured, _ = make_blobs(n_samples=300, centers=3, random_state=42)

# 4. Apply Agglomerative Clustering
clustering_structured = AgglomerativeClustering(n_clusters=2)
labels_structured = clustering_structured.fit_predict(X_structured)

clustering_unstructured = AgglomerativeClustering(n_clusters=3)
labels_unstructured = clustering_unstructured.fit_predict(X_unstructured)

# 5. Visualize Results
plt.figure(figsize=(12, 6))

# Structured Data (Moons)
plt.subplot(1, 2, 1)
plt.scatter(X_structured[:, 0], X_structured[:, 1], c=labels_structured, cmap='viridis', s=50)
plt.title("Agglomerative Clustering on Structured Data (Moons)")

# Unstructured Data (Blobs)
plt.subplot(1, 2, 2)
plt.scatter(X_unstructured[:, 0], X_unstructured[:, 1], c=labels_unstructured, cmap='viridis', s=50)
plt.title("Agglomerative Clustering on Unstructured Data (Blobs)")

plt.tight_layout()
plt.show()
