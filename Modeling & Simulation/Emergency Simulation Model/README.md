# <img src="assets/favicon.png" width="32" height="32"> Department Simulation | Professional Analytical Hub

![Social Preview](assets/social_preview.png)

A state-of-the-art **Discrete Event Simulation (DES)** tool designed for modeling, analyzing, and optimizing complex workflows using queuing theory. This tool provides researchers, analysts, and managers with real-time visual analytics and cost-effective decision-making support.

## 🚀 Core Features

- **Comprehensive Queuing Models**:
  - **Markovian Models**: M/M/1, M/M/c, M/M/1/K, M/M/c/K.
  - **General Service Models**: M/G/1, M/G/c, M/D/1.
  - **General Arrival/Service Models**: G/G/1, G/G/c.
- **Advanced Priority Systems**:
  - Support for **First-In-First-Out (FIFO)**.
  - **Non-Preemptive Priority (NP)**: Higher priority customers jump the queue but don't interrupt service.
  - **Preemptive Priority (PR)**: Higher priority customers can interrupt ongoing service sessions.
- **Cost Optimization Analysis**:
  - Calculate total simulation costs based on server operational costs and customer waiting costs.
- **Real-Time Visual Analytics**:
  - **Multi-Server Gantt Charts**: Track server usage and idle patterns.
  - **Queue Timeline plots**: Visualize queue length fluctuations over time.
  - **Metric Breakdowns**: Detailed bars and scatter plots for Wait Time, Service Time, and Response Time.
- **Theoretical Comparison**: Automated comparison between simulated data and theoretical steady-state results.

## 🛠️ Technical Background

The simulator is built using a **Discrete Event Simulation (DES)** engine implemented in Vanilla JavaScript. 

- **State Management**: Uses a custom DES loop tracking arrivals and completion events to jump through simulation time efficiently.
- **Distributions**: Supports Exponential (Poisson), Uniform, Deterministic, and Normal distributions using mathematical transforms (e.g., Box-Muller for Normal distribution).
- **Stability Analysis**: Built-in stability checks ($\rho < 1$) for infinite capacity models to ensure physical feasibility.
- **Precision Handling**: Implements floating-point precision guards (`Math.max(0, ...)` logic) to ensure accurate time metric reporting.

## 🎨 UI/UX Design

- **Premium Glassmorphism**: High-end aesthetic with frosted-glass effects and subtle depth.
- **Responsive Layout**: Optimized for desktop and tablets for professional use-cases.
- **Micro-animations**: Smooth transitions and interactive chart hover states for enhanced data exploration.

## 📖 Getting Started

1. Clone or download the repository.
2. Open `index.html` in any modern web browser.
3. Select your desired Queuing Model and Input Parameters.
4. Click **SIMULATE** to view real-time analytical results.

## 📝 Author

**Arham Sharif**
Simulation & Modeling Analysis HUB

---

### 📄 License

This project is proprietary. All rights are reserved by Arham Sharif. Unauthorized use, copying, or distribution is strictly prohibited. Arham Sharif reserves the unrestricted right to use, modify, and distribute this software. 

See the [LICENSE](LICENSE) file for the full legal terms.

---
*Note: This tool is intended for analytical and educational purposes.*
