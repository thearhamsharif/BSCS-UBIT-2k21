# 1. Import Libraries
import matplotlib.pyplot as plt
from sklearn.linear_model import BayesianRidge, ARDRegression, LinearRegression
from sklearn.datasets import load_diabetes
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, r2_score

# 2. Import Data (Diabetes Dataset)
diabetes = load_diabetes()
X = diabetes.data
y = diabetes.target

print(f"Dataset shape: {X.shape}")
print("Feature names:", diabetes.feature_names)

# 3. Preprocess / Feature Scaling (Inside Pipelines or Manual)
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 4. Train-Test Split
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42
)

# 5. Define Regressors
ols = LinearRegression()
bayesian_ridge = BayesianRidge()
ard = ARDRegression()

regressors = {
    "Linear Regression (OLS)": ols,
    "Bayesian Ridge Regression": bayesian_ridge,
    "ARD Regression": ard,
}

# 6. Fit Models
for name, reg in regressors.items():
    reg.fit(X_train, y_train)
    print(f"{name} fitted successfully.")

# 7. Test Models and Print Scores
for name, reg in regressors.items():
    y_pred = reg.predict(X_test)
    print(f"\n{name}")
    print(f"R^2 Score: {r2_score(y_test, y_pred):.4f}")
    print(f"Mean Squared Error: {mean_squared_error(y_test, y_pred):.4f}")

# 8. Visualize Coefficients
plt.figure(figsize=(12, 6))
for name, reg in regressors.items():
    plt.plot(reg.coef_, marker='o', label=name)

plt.title("Comparison of Coefficients (Diabetes Dataset)")
plt.xlabel("Feature Index")
plt.ylabel("Coefficient Value")
plt.legend()
plt.show()
