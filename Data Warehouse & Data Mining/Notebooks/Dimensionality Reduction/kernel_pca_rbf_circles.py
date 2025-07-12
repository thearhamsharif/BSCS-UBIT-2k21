# 1. Import Libraries
import matplotlib.pyplot as plt
from sklearn.datasets import make_circles
from sklearn.decomposition import KernelPCA
from sklearn.preprocessing import StandardScaler

# 2. Generate Nonlinear Data (Nested Circles)
X, y = make_circles(n_samples=400, factor=0.3, noise=0.05, random_state=42)

# 3. Standardize Features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 4. Apply Kernel PCA
kpca = KernelPCA(n_components=2, kernel='rbf', gamma=15)
X_kpca = kpca.fit_transform(X_scaled)

# 5. Plot Original Data
plt.figure(figsize=(12, 5))

plt.subplot(1, 2, 1)
plt.scatter(X_scaled[:, 0], X_scaled[:, 1], c=y, cmap='plasma', s=30)
plt.title("Original Data (Nested Circles)")
plt.xlabel("Feature 1")
plt.ylabel("Feature 2")

# 6. Plot Transformed Data
plt.subplot(1, 2, 2)
plt.scatter(X_kpca[:, 0], X_kpca[:, 1], c=y, cmap='plasma', s=30)
plt.title("Kernel PCA Projection (RBF Kernel)")
plt.xlabel("PC1")
plt.ylabel("PC2")

plt.tight_layout()
plt.show()
