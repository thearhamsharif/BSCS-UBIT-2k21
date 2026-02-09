document.getElementById('simulateBtn').addEventListener('click', runSimulation);
document.getElementById('resetBtn').addEventListener('click', resetSimulation);
document.getElementById('queuingModel').addEventListener('change', onModelChange);
onModelChange(); // Initialize labels

function onModelChange() {
  const model = document.getElementById('queuingModel').value;
  const serverInput = document.getElementById('serverCount');
  const arrivalSelect = document.getElementById('arrivalDist');
  const serviceSelect = document.getElementById('serviceDist');
  const capacityInput = document.getElementById('capacity');
  const capacityGroup = document.getElementById('capacityGroup');

  // Reset defaults
  serverInput.disabled = false;
  arrivalSelect.disabled = false;
  serviceSelect.disabled = false;
  capacityInput.disabled = false;
  capacityGroup.style.display = 'flex';

  switch (model) {
    case 'MM1':
      serverInput.value = 1;
      serverInput.disabled = true;
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      serviceSelect.value = 'EXPO';
      serviceSelect.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'MMC':
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      serviceSelect.value = 'EXPO';
      serviceSelect.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'MM1K':
      serverInput.value = 1;
      serverInput.disabled = true;
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      serviceSelect.value = 'EXPO';
      serviceSelect.disabled = true;
      capacityInput.value = 5;
      break;
    case 'MMCK':
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      serviceSelect.value = 'EXPO';
      serviceSelect.disabled = true;
      capacityInput.value = 5;
      break;
    case 'MG1':
      serverInput.value = 1;
      serverInput.disabled = true;
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'MGC':
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'MD1':
      serverInput.value = 1;
      serverInput.disabled = true;
      arrivalSelect.value = 'EXPO';
      arrivalSelect.disabled = true;
      serviceSelect.value = 'DET';
      serviceSelect.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'GG1':
      serverInput.value = 1;
      serverInput.disabled = true;
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
    case 'GGC':
      capacityInput.value = 999;
      capacityGroup.style.display = 'none';
      break;
  }
}

function runSimulation() {
  try {
    const serverCount = parseInt(document.getElementById('serverCount').value);
    const customerCount = parseInt(document.getElementById('customerCount').value);
    const arrivalDist = document.getElementById('arrivalDist').value;
    const serviceDist = document.getElementById('serviceDist').value;
    const lambda = parseFloat(document.getElementById('lambda').value);
    const mu = parseFloat(document.getElementById('mu').value);
    const capacity = parseInt(document.getElementById('capacity').value);

    // Robust Input Validation
    if (isNaN(lambda) || isNaN(mu) || lambda <= 0 || mu <= 0) {
      showError("Please enter valid positive values for Lambda (\u03BB) and Mu (\u03BC).");
      return;
    }
    if (isNaN(serverCount) || serverCount < 1) {
      showError("Server count (c) must be at least 1.");
      return;
    }
    if (isNaN(customerCount) || customerCount < 1) {
      showError("Number of customers (N) must be at least 1.");
      return;
    }
    if (isNaN(capacity) || capacity < 1) {
      showError("System capacity (K) must be at least 1.");
      return;
    }
    if (capacity < serverCount && document.getElementById('queuingModel').value.includes('K')) {
      showError("System capacity (K) cannot be less than the number of servers (c).");
      return;
    }

    // Stability Check (\u03C1 < 1) for Infinite Capacity Models
    const model = document.getElementById('queuingModel').value;
    const isFinite = model.includes('K');
    const rho = lambda / (serverCount * mu);

    if (!isFinite && rho >= 1) {
      showError(`System is Unstable (\u03C1 = ${rho.toFixed(2)} \u2265 1).
Theoretical values cannot be calculated as the queue will grow to infinity.
Please increase service rate (\u03BC) or increase number of servers (c).`);
      return;
    }

    // Show result sections
    document.getElementById('metricsSection').style.display = 'grid';
    document.getElementById('tableSection').style.display = 'block';
    document.getElementById('chartsSection').style.display = 'block';
    document.getElementById('steadyStateSection').style.display = 'block';

    const simulateBtn = document.getElementById('simulateBtn');
    simulateBtn.disabled = true;
    simulateBtn.innerText = "SIMULATING...";

    setTimeout(() => {
      const simulationData = generateSimulationData(customerCount, lambda, mu, arrivalDist, serviceDist, serverCount, capacity);
      updateUI(simulationData, lambda, mu, arrivalDist, serviceDist, serverCount, capacity);

      simulateBtn.disabled = false;
      simulateBtn.innerText = "SIMULATE";
      showSuccess("Simulation completed successfully!");
    }, 500); // Small delay for UX feel
  } catch (err) {
    document.getElementById('simulateBtn').disabled = false;
    document.getElementById('simulateBtn').innerText = "SIMULATE";
    showError("An unexpected error occurred during simulation. Please check your inputs.");
  }
}

function getRandomFromDist(type, rate) {
  const mean = 1 / rate;
  switch (type) {
    case 'EXPO':
      return -Math.log(1 - Math.random()) * mean;
    case 'UNIF':
      // Uniform between 0.5*mean and 1.5*mean
      return mean * (0.5 + Math.random());
    case 'DET':
      return mean;
    case 'NORM':
      // Box-Muller transform for normal distribution
      let u = 0, v = 0;
      while (u === 0) u = Math.random();
      while (v === 0) v = Math.random();
      let standardNormal = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
      // stdDev = 0.2 * mean for some variation
      return Math.max(0.1, mean + standardNormal * (0.2 * mean));
    default:
      return mean;
  }
}

function generateSimulationData(n, lambda, mu, arrivalDist, serviceDist, servers, capacity) {
  let data = [];
  let dropped = 0;
  let currentTime = 0;

  // Server availability tracking
  let serverFreeTime = new Array(servers).fill(0);
  let serverOccupancy = new Array(servers).fill(0).map(() => []);

  for (let i = 1; i <= n; i++) {
    // Inter-arrival time
    const interArrival = getRandomFromDist(arrivalDist, lambda);
    currentTime += interArrival;

    // Check system capacity (K)
    // Functional check: How many are currently in system?
    let inSystem = 0;
    serverFreeTime.forEach(t => {
      if (t > currentTime) inSystem++;
    });
    // Simplification: Approximate queue length by looking at scheduled ends
    // In a real event-based simulation, we'd track the queue. 
    // Here we can count how many servers are busy + how many are waiting to start.
    // However, our data structure is linear. Let's filter 'data' for currently in system.
    let currentlyInSystem = data.filter(c => c.endTime > currentTime).length;

    if (currentlyInSystem >= capacity) {
      dropped++;
      continue;
    }

    // Service time (enforcing a minimum of 1 unit as requested)
    const serviceTime = Math.max(1, getRandomFromDist(serviceDist, mu));

    // Assign to the first available server
    let chosenServer = 0;
    let earliestFree = serverFreeTime[0];

    for (let s = 1; s < servers; s++) {
      if (serverFreeTime[s] < earliestFree) {
        earliestFree = serverFreeTime[s];
        chosenServer = s;
      }
    }

    const startTime = Math.max(currentTime, serverFreeTime[chosenServer]);

    // Record idle time if any
    if (startTime > serverFreeTime[chosenServer]) {
      serverOccupancy[chosenServer].push({
        type: 'idle',
        start: serverFreeTime[chosenServer],
        end: startTime,
        label: 'Idle'
      });
    }

    const endTime = startTime + serviceTime;
    serverFreeTime[chosenServer] = endTime;

    serverOccupancy[chosenServer].push({
      type: 'service',
      start: startTime,
      end: endTime,
      label: `Cust ${i}`
    });

    const waitTime = startTime - currentTime;
    const turnaroundTime = endTime - currentTime;

    data.push({
      id: i,
      arrivalTime: currentTime,
      serviceTime: serviceTime,
      priority: Math.floor(Math.random() * 3) + 1,
      waitTime: waitTime,
      responseTime: waitTime,
      turnaroundTime: turnaroundTime,
      startTime: startTime,
      endTime: endTime,
      server: chosenServer + 1
    });
  }

  return { customers: data, serverOccupancy: serverOccupancy, dropped: dropped };
}

function updateUI(data, lambda, mu, arrivalDist, serviceDist, servers, capacity) {
  const customers = data.customers;

  // 1. Update Metrics Cards
  const avgWait = customers.length ? customers.reduce((sum, c) => sum + c.waitTime, 0) / customers.length : 0;
  const avgService = customers.length ? customers.reduce((sum, c) => sum + c.serviceTime, 0) / customers.length : 0;
  const avgTurnaround = customers.length ? customers.reduce((sum, c) => sum + c.turnaroundTime, 0) / customers.length : 0;
  const avgResponse = customers.length ? customers.reduce((sum, c) => sum + c.responseTime, 0) / customers.length : 0;

  document.getElementById('avgWaitTime').innerText = avgWait.toFixed(2);
  document.getElementById('avgServiceTime').innerText = avgService.toFixed(2);
  document.getElementById('avgTurnaroundTime').innerText = avgTurnaround.toFixed(2);
  document.getElementById('avgResponseTime').innerText = avgResponse.toFixed(2);

  // 2. Theoretical Results
  const model = document.getElementById('queuingModel').value;
  let theory = { utilization: 0, lq: 0, wq: 0, ls: 0, ws: 0, unstable: false, pk: 0 };

  try {
    calculateTheoretical(model, lambda, mu, servers, capacity, arrivalDist, serviceDist, theory);
  } catch (err) {
    theory.unstable = true;
  }

  const formatTheory = (val) => (isNaN(val) || !isFinite(val)) ? "0.00" : val.toFixed(2);

  document.getElementById('theoryUtilization').innerText = (theory.utilization * 100).toFixed(2) + "%" + (theory.unstable ? " (Unstable/Error)" : "");
  document.getElementById('theoryLq').innerText = formatTheory(theory.lq);
  document.getElementById('theoryWq').innerText = formatTheory(theory.wq);
  document.getElementById('theoryLs').innerText = formatTheory(theory.ls);
  document.getElementById('theoryWs').innerText = formatTheory(theory.ws);

  // Update Dropped Card with Theoretical comparison
  const simulatedDropped = data.dropped;
  const theoreticalDropped = (isNaN(theory.pk) || !isFinite(theory.pk)) ? "0.0" : (theory.pk * parseInt(document.getElementById('customerCount').value)).toFixed(1);
  document.getElementById('droppedCount').innerHTML = `${simulatedDropped} <span style="font-size: 0.8rem; opacity: 0.7;">(Theory: ${theoreticalDropped})</span>`;

  // 3. Table Update
  const tbody = document.querySelector('#simulationTable tbody');
  tbody.innerHTML = '';
  customers.forEach(c => {
    const row = `<tr>
            <td>${c.id}</td>
            <td>${c.arrivalTime.toFixed(2)}</td>
            <td>${c.serviceTime.toFixed(2)}</td>
            <td>${c.priority}</td>
            <td>${c.waitTime.toFixed(2)}</td>
            <td>${c.responseTime.toFixed(2)}</td>
            <td>${c.turnaroundTime.toFixed(2)}</td>
            <td>${c.startTime.toFixed(2)}</td>
            <td>${c.endTime.toFixed(2)}</td>
        </tr>`;
    tbody.innerHTML += row;
  });

  // 4. Gantt Chart
  renderGanttChart(data.serverOccupancy);

  // 5. Plots
  renderPlots(customers);
}

function calculateTheoretical(model, lambda, mu, c, K, arrivalDist, serviceDist, theory) {
  const rho = lambda / (c * mu);
  theory.utilization = rho;
  theory.pk = 0; // Default: no blocking

  if (model === 'MM1' || model === 'MMC') {
    if (rho >= 1) {
      theory.unstable = true;
      return;
    }
    const trafficIntensity = lambda / mu;
    let p0 = 0;
    if (c === 1) {
      p0 = 1 - rho;
    } else {
      let sum = 0;
      for (let k = 0; k < c; k++) {
        sum += Math.pow(trafficIntensity, k) / factorial(k);
      }
      p0 = 1 / (sum + (Math.pow(trafficIntensity, c) / (factorial(c) * (1 - rho))));
    }

    theory.lq = (p0 * Math.pow(trafficIntensity, c) * rho) / (factorial(c) * Math.pow(1 - rho, 2));
    theory.wq = theory.lq / lambda;
    theory.ws = theory.wq + (1 / mu);
    theory.ls = lambda * theory.ws;
  }
  else if (model === 'MG1' || model === 'MD1') {
    if (rho >= 1) {
      theory.unstable = true;
      return;
    }
    // Variance calculation for distributions
    let sigmaSq = 0;
    const meanS = 1 / mu;
    if (model === 'MD1') serviceDist = 'DET';

    if (serviceDist === 'EXPO') sigmaSq = Math.pow(meanS, 2);
    else if (serviceDist === 'UNIF') sigmaSq = Math.pow(meanS, 2) / 12; // Adjusted to m^2/12
    else if (serviceDist === 'NORM') sigmaSq = Math.pow(0.2 * meanS, 2);
    else if (serviceDist === 'DET') sigmaSq = 0;

    theory.wq = (lambda * (sigmaSq + Math.pow(meanS, 2))) / (2 * (1 - rho));
    theory.lq = lambda * theory.wq;
    theory.ws = theory.wq + meanS;
    theory.ls = lambda * theory.ws;
  }
  else if (model === 'MMCK' || model === 'MM1K') {
    if (model === 'MM1K') c = 1;
    const trafficIntensity = lambda / mu;
    let p0 = 0;
    let sum = 0;
    for (let n = 0; n <= c; n++) {
      sum += Math.pow(trafficIntensity, n) / factorial(n);
    }
    if (rho !== 1) {
      for (let n = c + 1; n <= K; n++) {
        sum += (Math.pow(trafficIntensity, c) / factorial(c)) * Math.pow(rho, n - c);
      }
    } else {
      sum += (Math.pow(trafficIntensity, c) / factorial(c)) * (K - c);
    }
    p0 = 1 / sum;

    let pk = 0;
    if (K >= c) {
      pk = (Math.pow(trafficIntensity, K) / (Math.pow(c, K - c) * factorial(c))) * p0;
    }

    const lambdaEff = lambda * (1 - pk);
    theory.pk = pk;
    theory.utilization = lambdaEff / (c * mu);

    // Lq calculation for MMCK (exact formula)
    let lq = 0;
    if (rho !== 1) {
      lq = (p0 * Math.pow(trafficIntensity, c) * rho) / (factorial(c) * Math.pow(1 - rho, 2));
      lq *= (1 - Math.pow(rho, K - c + 1) - (1 - rho) * (K - c + 1) * Math.pow(rho, K - c));
    } else {
      // Special case for rho = 1
      lq = (p0 * Math.pow(trafficIntensity, c) * (K - c) * (K - c + 1)) / (2 * factorial(c));
    }

    theory.lq = lq;
    theory.wq = theory.lq / lambdaEff;
    theory.ws = theory.wq + (1 / mu);
    theory.ls = lambdaEff * theory.ws;
  }
  else if (model === 'GG1' || model === 'GGC' || model === 'MGC') {
    if (rho >= 1) {
      theory.unstable = true;
      return;
    }
    // Allen-Cunneen Approximation
    // For MGC, arrivalDist will be EXPO, so ca2 = 1.
    const ca2 = getCV2(arrivalDist);
    const cs2 = getCV2(serviceDist);

    // P(L>=c) approximation
    const trafficIntensity = lambda / mu;
    let p0_mmc = 0;
    let sum = 0;
    for (let k = 0; k < c; k++) {
      sum += Math.pow(trafficIntensity, k) / factorial(k);
    }
    p0_mmc = 1 / (sum + (Math.pow(trafficIntensity, c) / (factorial(c) * (1 - rho))));
    const pw = (Math.pow(trafficIntensity, c) / (factorial(c) * (1 - rho))) * p0_mmc;

    theory.wq = (pw / (c * mu * (1 - rho))) * ((ca2 + cs2) / 2);
    theory.lq = lambda * theory.wq;
    theory.ws = theory.wq + (1 / mu);
    theory.ls = lambda * theory.ws;
  }
}

function getCV2(dist) {
  // Squared Coefficient of Variation C^2 = Var / Mean^2
  switch (dist) {
    case 'EXPO': return 1;
    case 'UNIF': return 1 / 12 / (1); // Approx if range is 1.0 around mean
    case 'DET': return 0;
    case 'NORM': return Math.pow(0.2, 2); // stdDev = 0.2*mean -> CV = 0.2
    default: return 1;
  }
}


function factorial(n) {
  if (n < 0) return 0;
  if (n === 0) return 1;
  let res = 1;
  // Safety cap to prevent Infinity for very large factorials if inputs are somehow large
  for (let i = 2; i <= Math.min(n, 100); i++) res *= i;
  return res;
}

function renderGanttChart(occupancy) {
  const gantt = document.getElementById('ganttChart');
  const axis = document.getElementById('ganttAxis');
  const title = document.getElementById('ganttChartTitle');

  gantt.innerHTML = '';
  axis.innerHTML = '';

  // Use the longest timeline for the axis
  let maxEndTime = 0;
  occupancy.forEach(server => {
    if (server.length > 0) {
      maxEndTime = Math.max(maxEndTime, server[server.length - 1].end);
    }
  });

  const totalTime = maxEndTime || 1;

  occupancy.forEach((serverItems, idx) => {
    const serverRow = document.createElement('div');
    serverRow.className = 'gantt-chart';
    serverRow.style.marginBottom = '10px';

    let busyTime = 0;
    serverItems.forEach(item => {
      const width = (item.end - item.start) / totalTime * 100;
      const div = document.createElement('div');
      div.className = `gantt-item ${item.type}`;
      div.style.width = `${width}%`;
      div.innerText = item.label;
      div.title = `Server ${idx + 1} | ${item.label}: ${item.start.toFixed(2)} - ${item.end.toFixed(2)}`;
      serverRow.appendChild(div);
      if (item.type === 'service') busyTime += (item.end - item.start);
    });

    const rowLabel = document.createElement('div');
    rowLabel.style.fontSize = '0.7rem';
    rowLabel.style.marginBottom = '2px';
    rowLabel.innerText = `Server ${idx + 1} (${(busyTime / totalTime * 100).toFixed(2)}% busy)`;

    gantt.appendChild(rowLabel);
    gantt.appendChild(serverRow);
  });

  title.innerText = `Multi-Server Usage Timeline (${occupancy.length} Servers)`;

  for (let i = 0; i <= totalTime; i += Math.max(1, Math.floor(totalTime / 10))) {
    const tick = document.createElement('div');
    tick.className = 'axis-tick';
    tick.style.left = `${(i / totalTime * 100)}%`;
    tick.innerText = i;
    axis.appendChild(tick);
  }
}

function renderPlots(customers) {
  const ids = customers.map(c => c.id);
  const serviceTimes = customers.map(c => c.serviceTime);

  const chartsConfig = [
    { id: 'waitingTimeChart', title: 'Waiting Time', data: customers.map(c => c.waitTime) },
    { id: 'serviceTimeChart', title: 'Service Time', data: serviceTimes },
    { id: 'responseTimeChart', title: 'Response Time', data: customers.map(c => c.responseTime) },
    { id: 'turnAroundTimeChart', title: 'Turn Around Time', data: customers.map(c => c.turnaroundTime) }
  ];

  chartsConfig.forEach(cfg => {
    const canvas = document.getElementById(cfg.id);
    canvas.width = 400;
    canvas.height = 250;
    const ctx = canvas.getContext('2d');
    drawSubBarChart(ctx, 40, 30, 340, 180, ids, cfg.data, serviceTimes, cfg.title);
  });

  const scatterCanvas = document.getElementById('scatterPlotCanvas');
  scatterCanvas.width = 800;
  scatterCanvas.height = 400;
  const scatterCtx = scatterCanvas.getContext('2d');
  drawScatterPlot(scatterCtx, customers);
}

function drawSubBarChart(ctx, x, y, w, h, labels, values, serviceValues, title) {
  ctx.clearRect(0, 0, x + w + 50, y + h + 50);
  if (!values.length) return;

  const maxValue = Math.max(...values, ...serviceValues, 0.5) * 1.2;
  const primaryColor = "#0d9488"; // Teal
  const accentColor = "#f59e0b"; // Amber

  // Axes
  ctx.strokeStyle = "#cbd5e1";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x, y);
  ctx.lineTo(x, y + h);
  ctx.lineTo(x + w, y + h);
  ctx.stroke();

  // Legend
  ctx.font = "12px Poppins";
  ctx.textAlign = "left";
  ctx.fillStyle = primaryColor;
  ctx.fillRect(x + w - 100, y - 24, 12, 12);
  ctx.fillText("Metric", x + w - 84, y - 14);
  ctx.fillStyle = accentColor;
  ctx.fillRect(x + w - 45, y - 24, 12, 12);
  ctx.fillText("Service", x + w - 29, y - 14);

  const groupWidth = w / values.length;
  const barWidth = Math.max(2, groupWidth * 0.35);

  values.forEach((v, i) => {
    const bHeight1 = (v / maxValue) * h;
    const bHeight2 = (serviceValues[i] / maxValue) * h;
    const bx = x + i * groupWidth + groupWidth * 0.15;

    // Primary Bar
    ctx.fillStyle = primaryColor;
    ctx.fillRect(bx, y + h - bHeight1, barWidth, bHeight1);

    // Accent Bar
    ctx.fillStyle = accentColor;
    ctx.fillRect(bx + barWidth, y + h - bHeight2, barWidth, bHeight2);

    // Labels
    if (values.length <= 20) {
      ctx.fillStyle = "#64748b";
      ctx.font = "10px Poppins";
      ctx.textAlign = "center";
      ctx.fillText(labels[i], bx + barWidth, y + h + 16);
    }
  });

  // Y-axis
  ctx.textAlign = "right";
  ctx.fillStyle = "#999";
  for (let j = 0; j <= 4; j++) {
    const val = (maxValue * j / 4).toFixed(1);
    const py = y + h - (j / 4) * h;
    ctx.fillText(val, x - 5, py + 3);
  }
}

function drawScatterPlot(ctx, customers) {
  ctx.clearRect(0, 0, 800, 400);
  if (!customers.length) return;

  const padding = 60;
  const w = 800 - 2 * padding;
  const h = 400 - 2 * padding;

  const maxTime = Math.max(...customers.map(c => c.endTime), 1) * 1.1;
  const maxID = Math.max(...customers.map(c => c.id), 1);

  ctx.strokeStyle = "#ccc";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(padding, padding);
  ctx.lineTo(padding, padding + h);
  ctx.lineTo(padding + w, padding + h);
  ctx.stroke();

  // X-Axis Numbering (Time)
  ctx.fillStyle = "#999";
  ctx.font = "10px Roboto";
  ctx.textAlign = "center";
  for (let i = 0; i <= 10; i++) {
    const val = (maxTime * i / 10).toFixed(0);
    const px = padding + (i / 10) * w;
    ctx.fillText(val, px, padding + h + 15);
    ctx.beginPath();
    ctx.moveTo(px, padding + h);
    ctx.lineTo(px, padding + h + 5);
    ctx.stroke();
  }
  ctx.fillText("Time Units", padding + w / 2, padding + h + 30);

  // Y-Axis Numbering (Customer ID)
  ctx.textAlign = "right";
  for (let j = 0; j <= maxID; j += Math.max(1, Math.floor(maxID / 5))) {
    const py = padding + h - (j / maxID) * h;
    ctx.fillText(j, padding - 10, py + 3);
    ctx.beginPath();
    ctx.moveTo(padding, py);
    ctx.lineTo(padding - 5, py);
    ctx.stroke();
  }

  ctx.save();
  ctx.translate(15, padding + h / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.textAlign = "center";
  ctx.fillText("Customer ID", 0, 0);
  ctx.restore();

  customers.forEach(c => {
    const xA = padding + (c.arrivalTime / maxTime) * w;
    const yA = padding + h - (c.id / maxID) * h;
    ctx.fillStyle = "#0d9488"; // Primary
    ctx.beginPath();
    ctx.arc(xA, yA, 4, 0, Math.PI * 2);
    ctx.fill();

    const xE = padding + (c.endTime / maxTime) * w;
    const yE = padding + h - (c.id / maxID) * h;
    ctx.fillStyle = "#f59e0b"; // Accent
    ctx.beginPath();
    ctx.arc(xE, yE, 4, 0, Math.PI * 2);
    ctx.fill();
  });

  // Legend
  ctx.font = "14px Poppins";
  ctx.textAlign = "right";
  ctx.fillStyle = "#0d9488";
  ctx.fillRect(750, 60, 15, 15);
  ctx.fillText("Arrival Time", 740, 72);
  ctx.fillStyle = "#f59e0b";
  ctx.fillRect(750, 85, 15, 15);
  ctx.fillText("End Time", 740, 97);
}

// Download Table as CSV
document.querySelector('.btn-download').addEventListener('click', () => {
  const table = document.getElementById('simulationTable');
  let csv = [];
  for (let i = 0; i < table.rows.length; i++) {
    let row = [], cols = table.rows[i].cells;
    for (let j = 0; j < cols.length; j++) row.push(cols[j].innerText);
    csv.push(row.join(","));
  }
  const csvContent = "data:text/csv;charset=utf-8," + csv.join("\n");
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", "simulation_results.csv");
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
});


function showSuccess(message) {
  showNotification(message, 'success');
}

function showError(message) {
  showNotification(message, 'error');
}

function showNotification(message, type) {
  const container = document.getElementById('error-container');

  const toast = document.createElement('div');
  toast.className = `error-toast ${type === 'success' ? 'success-toast' : ''}`;

  const iconSvg = type === 'success'
    ? `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>`
    : `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>`;

  toast.innerHTML = `
        <div class="icon">${iconSvg}</div>
        <div class="message">${message.replace(/\n/g, '<br>')}</div>
    `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 5000);
}

function resetSimulation() {
  // 1. Reset Inputs to defaults
  document.getElementById('queuingModel').value = 'MMC';
  document.getElementById('serverCount').value = 1;
  document.getElementById('customerCount').value = 10;
  document.getElementById('arrivalDist').value = 'EXPO';
  document.getElementById('serviceDist').value = 'EXPO';
  document.getElementById('lambda').value = 2;
  document.getElementById('mu').value = 3;
  document.getElementById('capacity').value = 999;

  onModelChange(); // Refresh label states

  // 2. Hide results
  document.getElementById('metricsSection').style.display = 'none';
  document.getElementById('tableSection').style.display = 'none';
  document.getElementById('chartsSection').style.display = 'none';
  document.getElementById('steadyStateSection').style.display = 'none';

  // 3. Clear transient results
  document.querySelector('#simulationTable tbody').innerHTML = '';

  showNotification("Simulation reset to defaults.", "success");
}
