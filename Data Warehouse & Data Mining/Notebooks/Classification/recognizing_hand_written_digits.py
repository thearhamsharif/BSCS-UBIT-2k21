# 1. Import Libraries
import matplotlib.pyplot as plt
import numpy as np
from sklearn import datasets
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import classification_report, accuracy_score

# 2. Load Digits Dataset
digits = datasets.load_digits()
X = digits.data
y = digits.target

print(f"Dataset shape: {X.shape}")
print(f"Number of classes: {len(np.unique(y))}")

# 3. Train-Test Split (80% train, 20% test)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# 4. Define classifier pipeline (example: KNN with scaling)
clf = make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=3))

# 5. Train classifier
clf.fit(X_train, y_train)

# 6. Test classifier
y_pred = clf.predict(X_test)
print(classification_report(y_test, y_pred))
print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")

# 7. Visualize some predictions
fig, axes = plt.subplots(2, 5, figsize=(10, 5))
for ax, image, pred, true in zip(axes.flatten(), X_test, y_pred, y_test):
    ax.imshow(image.reshape(8, 8), cmap='gray')
    ax.set_title(f"Pred: {pred}, True: {true}")
    ax.axis('off')
plt.tight_layout()
plt.show()
