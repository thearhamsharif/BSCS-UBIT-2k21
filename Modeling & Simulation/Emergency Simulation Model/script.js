document.getElementById('simulateBtn').addEventListener('click', runSimulation);

function runSimulation() {
  const serverCount = parseInt(document.getElementById('serverCount').value);
  const customerCount = parseInt(document.getElementById('customerCount').value);
  const distributionType = document.getElementById('distributionType').value;
  const lambda = parseFloat(document.getElementById('lambda').value);
  const mu = parseFloat(document.getElementById('mu').value);

  if (isNaN(lambda) || isNaN(mu) || lambda <= 0 || mu <= 0) {
    alert("Please enter valid positive values for Lambda and Mu.");
    return;
  }

  // Show result sections
  document.getElementById('metricsSection').style.display = 'grid';
  document.getElementById('tableSection').style.display = 'block';
  document.getElementById('chartsSection').style.display = 'block';
  document.getElementById('steadyStateSection').style.display = 'block';

  const simulationData = generateSimulationData(customerCount, lambda, mu, distributionType, serverCount);
  updateUI(simulationData, lambda, mu, distributionType, serverCount);
}

function generateSimulationData(n, lambda, mu, distType, servers) {
  let data = [];
  let currentTime = 0;

  // Server availability tracking
  let serverFreeTime = new Array(servers).fill(0);
  let serverOccupancy = new Array(servers).fill(0).map(() => []);

  for (let i = 1; i <= n; i++) {
    // Inter-arrival time (Exponential)
    const interArrival = -Math.log(1 - Math.random()) / lambda;
    currentTime += interArrival;

    // Service time
    let serviceTime;
    if (distType === 'MM') {
      serviceTime = -Math.log(1 - Math.random()) / mu;
    } else {
      // M/G - using a slightly different distribution (e.g., Uniform variation around 1/mu)
      serviceTime = (1 / mu) * (0.5 + Math.random());
    }

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
      label: `Customer ${i}`
    });

    const waitTime = startTime - currentTime;
    const turnaroundTime = endTime - currentTime;

    data.push({
      id: i,
      arrivalTime: currentTime,
      serviceTime: serviceTime,
      priority: Math.floor(Math.random() * 3) + 1, // Random priority for UI display
      waitTime: waitTime,
      responseTime: waitTime,
      turnaroundTime: turnaroundTime,
      startTime: startTime,
      endTime: endTime,
      server: chosenServer + 1
    });
  }

  return { customers: data, serverOccupancy: serverOccupancy };
}

function updateUI(data, lambda, mu, distType, servers) {
  const customers = data.customers;

  // 1. Update Metrics Cards
  const avgWait = customers.reduce((sum, c) => sum + c.waitTime, 0) / customers.length;
  const avgService = customers.reduce((sum, c) => sum + c.serviceTime, 0) / customers.length;
  const avgTurnaround = customers.reduce((sum, c) => sum + c.turnaroundTime, 0) / customers.length;
  const avgResponse = customers.reduce((sum, c) => sum + c.responseTime, 0) / customers.length;

  document.getElementById('avgWaitTime').innerText = avgWait.toFixed(2);
  document.getElementById('avgServiceTime').innerText = avgService.toFixed(2);
  document.getElementById('avgTurnaroundTime').innerText = avgTurnaround.toFixed(2);
  document.getElementById('avgResponseTime').innerText = avgResponse.toFixed(2);

  // 2. Theoretical Results
  const rho = lambda / mu;
  if (rho < 1) {
    const theoryLq = (rho * rho) / (1 - rho);
    const theoryLs = rho / (1 - rho);
    const theoryWq = rho / (mu - lambda);
    const theoryWs = 1 / (mu - lambda);

    document.getElementById('theoryUtilization').innerText = rho.toFixed(4);
    document.getElementById('theoryLq').innerText = theoryLq.toFixed(4);
    document.getElementById('theoryWq').innerText = theoryWq.toFixed(4);
    document.getElementById('theoryLs').innerText = theoryLs.toFixed(4);
    document.getElementById('theoryWs').innerText = theoryWs.toFixed(4);
  } else {
    document.getElementById('theoryUtilization').innerText = rho.toFixed(4) + " (Unstable)";
  }

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

function renderGanttChart(occupancy) {
  const gantt = document.getElementById('ganttChart');
  const axis = document.getElementById('ganttAxis');
  const title = document.getElementById('ganttChartTitle');

  gantt.innerHTML = '';
  axis.innerHTML = '';

  const server1 = occupancy[0];
  const totalTime = server1[server1.length - 1].end;

  let busyTime = 0;
  server1.forEach(item => {
    const width = (item.end - item.start) / totalTime * 100;
    const div = document.createElement('div');
    div.className = `gantt-item ${item.type}`;
    div.style.width = `${width}%`;
    div.innerText = item.label;
    div.title = `${item.label}: ${item.start.toFixed(2)} - ${item.end.toFixed(2)}`;
    gantt.appendChild(div);

    if (item.type === 'service') busyTime += (item.end - item.start);
  });

  title.innerText = `Server 1 (${(busyTime / totalTime * 100).toFixed(2)}%)`;

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
  const maxValue = Math.max(...values, ...serviceValues, 0.5) * 1.2;
  const blueColor = "#1976D2";
  const orangeColor = "#F57C00";

  // Axes
  ctx.strokeStyle = "#ccc";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x, y);
  ctx.lineTo(x, y + h);
  ctx.lineTo(x + w, y + h);
  ctx.stroke();

  // Legend
  ctx.font = "10px Roboto";
  ctx.textAlign = "left";
  ctx.fillStyle = blueColor;
  ctx.fillRect(x + w - 100, y - 20, 10, 10);
  ctx.fillText("Metric", x + w - 85, y - 12);
  ctx.fillStyle = orangeColor;
  ctx.fillRect(x + w - 45, y - 20, 10, 10);
  ctx.fillText("Service", x + w - 30, y - 12);

  const groupWidth = w / values.length;
  const barWidth = groupWidth * 0.35;

  values.forEach((v, i) => {
    const bHeight1 = (v / maxValue) * h;
    const bHeight2 = (serviceValues[i] / maxValue) * h;
    const bx = x + i * groupWidth + groupWidth * 0.15;

    // Blue Bar
    ctx.fillStyle = blueColor;
    ctx.fillRect(bx, y + h - bHeight1, barWidth, bHeight1);

    // Orange Bar
    ctx.fillStyle = orangeColor;
    ctx.fillRect(bx + barWidth, y + h - bHeight2, barWidth, bHeight2);

    // Labels
    if (values.length <= 15) {
      ctx.fillStyle = "#666";
      ctx.font = "8px Roboto";
      ctx.textAlign = "center";
      ctx.fillText(labels[i], bx + barWidth, y + h + 12);
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
  const padding = 60;
  const w = 800 - 2 * padding;
  const h = 400 - 2 * padding;

  const maxTime = Math.max(...customers.map(c => c.endTime), 1) * 1.1; // 10% padding
  const maxID = customers.length;

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
    // Tiny tick
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
    // Tiny tick
    ctx.beginPath();
    ctx.moveTo(padding, py);
    ctx.lineTo(padding - 5, py);
    ctx.stroke();
  }
  // Rotate ctx to draw vertical label
  ctx.save();
  ctx.translate(15, padding + h / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.textAlign = "center";
  ctx.fillText("Customer ID", 0, 0);
  ctx.restore();

  customers.forEach(c => {
    const xA = padding + (c.arrivalTime / maxTime) * w;
    const yA = padding + h - (c.id / maxID) * h;
    ctx.fillStyle = "#1976D2";
    ctx.beginPath();
    ctx.arc(xA, yA, 6, 0, Math.PI * 2);
    ctx.fill();

    const xE = padding + (c.endTime / maxTime) * w;
    const yE = padding + h - (c.id / maxID) * h;
    ctx.fillStyle = "#F57C00";
    ctx.beginPath();
    ctx.arc(xE, yE, 6, 0, Math.PI * 2);
    ctx.fill();
  });

  // Legend
  ctx.font = "14px Roboto";
  ctx.textAlign = "right";
  ctx.fillStyle = "#1976D2";
  ctx.fillRect(750, 60, 15, 15);
  ctx.fillText("Arrival Time", 740, 72);
  ctx.fillStyle = "#F57C00";
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

