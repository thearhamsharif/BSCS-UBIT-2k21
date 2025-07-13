# 1. Import Libraries
import pandas as pd
import matplotlib.pyplot as plt

# 2. Load Dataset from Raw URL
url = "https://raw.githubusercontent.com/selva86/datasets/master/College.csv"
df = pd.read_csv(url)

# 3. Basic Info
print("Shape:", df.shape)
print("Columns:", df.columns.tolist())
print(df.head())

# 4. Histogram: Outstate Tuition
plt.figure(figsize=(8, 4))
plt.hist(df["Outstate"], bins=30, color="skyblue", edgecolor="black")
plt.title("Distribution of Out-of-State Tuition")
plt.xlabel("Tuition ($)")
plt.ylabel("Number of Colleges")
plt.grid(True)
plt.tight_layout()
plt.show()

# 5. Boxplot: Accept Rate vs Private/Public
plt.figure(figsize=(6, 4))
groups = df.groupby("Private")["Accept"]
plt.boxplot([group for _, group in groups], tick_labels=["No", "Yes"])
plt.title("Acceptance Rate by Institution Type")
plt.xlabel("Private Institution")
plt.ylabel("Acceptance Rate (%)")
plt.grid(True)
plt.tight_layout()
plt.show()

# 6. Scatter Plot: Faculty vs Expenditures
plt.figure(figsize=(6, 4))
plt.scatter(df["PhD"], df["Expend"], alpha=0.6, edgecolor="black")
plt.title("PhD Faculty vs Expenditure per Student")
plt.xlabel("Number of PhD Faculty (%)")
plt.ylabel("Expenditure per Student")
plt.grid(True)
plt.tight_layout()
plt.show()

# 7. Correlation Heatmap with Matplotlib
num_df = df.select_dtypes(include="number")
corr = num_df.corr()

plt.figure(figsize=(10, 8))
plt.imshow(corr, cmap="coolwarm", interpolation="nearest")
plt.colorbar()
plt.title("Correlation Matrix (Numeric Features)")
plt.xticks(range(len(corr.columns)), corr.columns, rotation=90)
plt.yticks(range(len(corr.columns)), corr.columns)
plt.tight_layout()
plt.show()
