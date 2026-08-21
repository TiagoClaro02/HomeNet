const API_URL = "http://192.168.1.160:8080/api/status";

let previousInterfaces = null;
let previousTimestamp = null;

/* =========================
   UTILITIES
   ========================= */

function formatBytes(bytes) {
    const gb = bytes / 1024 / 1024 / 1024;

    if (gb >= 1) {
        return gb.toFixed(2) + " GB";
    }

    const mb = bytes / 1024 / 1024;

    if (mb >= 1) {
        return mb.toFixed(2) + " MB";
    }

    return (bytes / 1024).toFixed(2) + " KB";
}


function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    seconds %= 86400;

    const hours = Math.floor(seconds / 3600);
    seconds %= 3600;

    const minutes = Math.floor(seconds / 60);

    return `${days}d ${hours}h ${minutes}m`;
}


function escapeHtml(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

function formatRate(bytesPerSecond) {
    if (bytesPerSecond === null || bytesPerSecond === undefined) {
        return "—";
    }

    const mb = bytesPerSecond / 1024 / 1024;

    if (mb >= 1) {
        return mb.toFixed(2) + " MB/s";
    }

    const kb = bytesPerSecond / 1024;

    if (kb >= 1) {
        return kb.toFixed(2) + " KB/s";
    }

    return bytesPerSecond.toFixed(0) + " B/s";
}

function formatPacketsRate(packetsPerSecond) {
    return packetsPerSecond.toFixed(0) + " p/s";
}

function formatEventRate(rate) {
    if (rate === null) {
        return "—";
    }

    if (rate < 0.01) {
        return "0/sec";
    }

    return rate.toFixed(2) + "/sec";
}

async function updateDashboard() {
    try {
        console.log("Fetching API...");

        const response = await fetch(API_URL);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        console.log("JSON:", data);

        const now = performance.now();

        let elapsed = null;

        if (previousTimestamp !== null) {
            elapsed = (now - previousTimestamp) / 1000;
        }

        updateSystem(data);
        updateNetwork(data, elapsed);
        updateHealth(data, elapsed);

        previousInterfaces = data.network.interfaces.map((iface) => ({
            name: iface.name,
            stats: { ...iface.stats }
        }));

        previousTimestamp = now;

        document.getElementById("connection-status").textContent =
            "Connected";

        document.getElementById("connection-status").className =
            "status connected";

        document.getElementById("last-update").textContent =
            new Date().toLocaleTimeString();

    } catch (error) {
        console.error("API ERROR:", error);

        document.getElementById("connection-status").textContent =
            "Disconnected";

        document.getElementById("connection-status").className =
            "status disconnected";

        setHealthStatus(
            "unknown",
            "Unable to communicate with the HomeNet API"
        );
    }
}


/* =========================
   SYSTEM
   ========================= */

function updateSystem(data) {
    const system = data.system;

    document.getElementById("hostname").textContent =
        system.hostname;

    document.getElementById("architecture").textContent =
        system.architecture;

    document.getElementById("uptime").textContent =
        formatUptime(system.uptime);

    document.getElementById("cpu-usage").textContent =
        system.cpu.usage.toFixed(2) + "%";

    document.getElementById("load-1m").textContent =
        system.cpu.load_1m.toFixed(2);

    document.getElementById("load-5m").textContent =
        system.cpu.load_5m.toFixed(2);

    document.getElementById("load-15m").textContent =
        system.cpu.load_15m.toFixed(2);

    document.getElementById("memory-total").textContent =
        formatBytes(system.memory.total);

    document.getElementById("memory-used").textContent =
        formatBytes(system.memory.used);

    document.getElementById("memory-available").textContent =
        formatBytes(system.memory.available);

    document.getElementById("disk-total").textContent =
        formatBytes(system.disk.total);

    document.getElementById("disk-used").textContent =
        formatBytes(system.disk.used);

    document.getElementById("disk-free").textContent =
        formatBytes(system.disk.free);
}


/* =========================
   NETWORK
   ========================= */

function updateNetwork(data, elapsed) {
    const network = data.network;

    document.getElementById("gateway").textContent =
        network.connections.default_gateway;

    document.getElementById("dns").textContent =
        network.connections.dns_servers.join(", ");

    updateInterfaces(network.interfaces, elapsed);

    updateAddresses(network.connections.addresses);

    updateRoutes(network.connections.routes);
}


function updateInterfaces(interfaces, elapsed) {
    const container = document.getElementById("interfaces");

    container.innerHTML = "";

    for (const iface of interfaces) {

        const previous = previousInterfaces
            ? previousInterfaces.find(
                item => item.name === iface.name
            )
            : null;

        const delta = calculateInterfaceDelta(
            iface,
            previous,
            elapsed
        );

        const health = getInterfaceHealth(delta);

        const element = document.createElement("div");

        element.className = `network-interface ${health.status}`;

        element.innerHTML = `
            <div class="interface-header">
                <strong>${escapeHtml(iface.name)}</strong>
                <span class="status-dot ${health.status}"></span>
            </div>

            <div class="health-reason ${health.status}">
                ${escapeHtml(health.reason)}
            </div>

            <div class="interface-stats">

                <div>
                    <span class="label">RX</span>
                    <span>${formatBytes(iface.stats.rx_bytes)}</span>
                </div>

                <div>
                    <span class="label">TX</span>
                    <span>${formatBytes(iface.stats.tx_bytes)}</span>
                </div>

                <div>
                    <span class="label">RX Packets</span>
                    <span>${iface.stats.rx_packets.toLocaleString()}</span>
                </div>

                <div>
                    <span class="label">TX Packets</span>
                    <span>${iface.stats.tx_packets.toLocaleString()}</span>
                </div>

                <div>
                    <span class="label">RX Errors</span>
                    <span>${iface.stats.rx_errors}</span>
                </div>

                <div>
                    <span class="label">TX Errors</span>
                    <span>${iface.stats.tx_errors}</span>
                </div>

                <div>
                    <span class="label">RX Dropped</span>
                    <span>${iface.stats.rx_dropped}</span>
                </div>

                <div>
                    <span class="label">TX Dropped</span>
                    <span>${iface.stats.tx_dropped}</span>
                </div>

                <div>
                    <span class="label">RX Drop Rate</span>
                    <span>${formatEventRate(delta.rx_dropped_rate)}</span>
                </div>

                <div>
                    <span class="label">TX Drop Rate</span>
                    <span>${formatRate(delta.tx_dropped_rate)}</span>
                </div>

                <div>
                    <span class="label">RX Error Rate</span>
                    <span>${formatRate(delta.rx_errors_rate)}</span>
                </div>

                <div>
                    <span class="label">TX Error Rate</span>
                    <span>${formatRate(delta.tx_errors_rate)}</span>
                </div>

            </div>
        `;

        container.appendChild(element);
    }
}

function calculateInterfaceDelta(current, previous, elapsed) {

    if (!previous || elapsed === null || elapsed <= 0) {
        return {
            rx_dropped_rate: null,
            tx_dropped_rate: null,
            rx_errors_rate: null,
            tx_errors_rate: null
        };
    }

    return {
        rx_dropped_rate:
            calculateRate(
                current.stats.rx_dropped,
                previous.stats.rx_dropped,
                elapsed
            ),

        tx_dropped_rate:
            calculateRate(
                current.stats.tx_dropped,
                previous.stats.tx_dropped,
                elapsed
            ),

        rx_errors_rate:
            calculateRate(
                current.stats.rx_errors,
                previous.stats.rx_errors,
                elapsed
            ),

        tx_errors_rate:
            calculateRate(
                current.stats.tx_errors,
                previous.stats.tx_errors,
                elapsed
            )
    };
}


function calculateRate(current, previous, elapsed) {

    const delta = current - previous;

    // Counter probably reset (e.g. reboot)
    if (delta < 0) {
        return 0;
    }

    return delta / elapsed;
}

function updateAddresses(addresses) {
    const container = document.getElementById("addresses");

    container.innerHTML = "";

    for (const addr of addresses) {
        const element = document.createElement("div");

        element.className = "network-row";

        element.innerHTML = `
            <span>${escapeHtml(addr.interface)}</span>
            <span>${escapeHtml(addr.address)}/${addr.prefix}</span>
        `;

        container.appendChild(element);
    }
}


function updateRoutes(routes) {
    const container = document.getElementById("routes");

    container.innerHTML = "";

    for (const route of routes) {
        const element = document.createElement("div");

        element.className = "network-row";

        element.innerHTML = `
            <span>${escapeHtml(route.interface)}</span>
            <span>
                ${escapeHtml(route.destination)}
                →
                ${escapeHtml(route.gateway)}
            </span>
            <span>metric ${route.metric}</span>
        `;

        container.appendChild(element);
    }
}


/* =========================
   HEALTH
   ========================= */

function updateHealth(data, elapsed) {
    const system = data.system;
    const interfaces = data.network.interfaces;

    const cpuHealth = getCpuHealth(system.cpu.usage);

    const memoryHealth = getMemoryHealth(
        system.memory.used,
        system.memory.total
    );

    const diskHealth = getDiskHealth(
        system.disk.used,
        system.disk.total
    );

    const networkHealth = getNetworkHealth(
        interfaces,
        elapsed
    );

    setHealthIndicator(
        "health-cpu",
        cpuHealth.status,
        cpuHealth.reason
    );

    setHealthIndicator(
        "health-memory",
        memoryHealth.status,
        memoryHealth.reason
    );

    setHealthIndicator(
        "health-disk",
        diskHealth.status,
        diskHealth.reason
    );

    setHealthIndicator(
        "health-network",
        networkHealth.status,
        networkHealth.reason
    );

    const overallHealth = worstHealth([
        cpuHealth,
        memoryHealth,
        diskHealth,
        networkHealth
    ]);

    setHealthStatus(
        overallHealth.status,
        overallHealth.reason
    );
}


/* =========================
   CPU HEALTH
   ========================= */

function getCpuHealth(usage) {

    if (usage >= 90) {
        return {
            status: "critical",
            reason: `CPU usage is very high (${usage.toFixed(1)}%)`
        };
    }

    if (usage >= 70) {
        return {
            status: "warning",
            reason: `CPU usage is high (${usage.toFixed(1)}%)`
        };
    }

    return {
        status: "healthy",
        reason: `CPU usage is normal (${usage.toFixed(1)}%)`
    };
}


/* =========================
   MEMORY HEALTH
   ========================= */

function getMemoryHealth(used, total) {

    const percentage = (used / total) * 100;

    if (percentage >= 90) {
        return {
            status: "critical",
            reason: `Memory usage is very high (${percentage.toFixed(1)}%)`
        };
    }

    if (percentage >= 75) {
        return {
            status: "warning",
            reason: `Memory usage is high (${percentage.toFixed(1)}%)`
        };
    }

    return {
        status: "healthy",
        reason: `Memory usage is normal (${percentage.toFixed(1)}%)`
    };
}


/* =========================
   DISK HEALTH
   ========================= */

function getDiskHealth(used, total) {

    const percentage = (used / total) * 100;

    if (percentage >= 95) {
        return {
            status: "critical",
            reason: `Disk usage is critically high (${percentage.toFixed(1)}%)`
        };
    }

    if (percentage >= 85) {
        return {
            status: "warning",
            reason: `Disk usage is high (${percentage.toFixed(1)}%)`
        };
    }

    return {
        status: "healthy",
        reason: `Disk usage is normal (${percentage.toFixed(1)}%)`
    };
}


/* =========================
   INTERFACE HEALTH
   ========================= */

function getInterfaceHealth(delta) {

    if (
        delta.rx_dropped_rate === null ||
        delta.tx_dropped_rate === null ||
        delta.rx_errors_rate === null ||
        delta.tx_errors_rate === null
    ) {
        return {
            status: "unknown",
            reason: "Waiting for enough samples to calculate network health"
        };
    }

    const errorRate =
        delta.rx_errors_rate +
        delta.tx_errors_rate;

    const dropRate =
        delta.rx_dropped_rate +
        delta.tx_dropped_rate;


    /*
     * CRITICAL
     */

    if (errorRate > 1) {
        return {
            status: "critical",
            reason:
                `Network errors detected (${errorRate.toFixed(2)} errors/sec)`
        };
    }

    if (dropRate > 100) {
        return {
            status: "critical",
            reason:
                `High packet drop rate (${dropRate.toFixed(2)} drops/sec)`
        };
    }


    /*
     * WARNING
     */

    if (errorRate > 0) {
        return {
            status: "warning",
            reason:
                `Network errors detected (${errorRate.toFixed(2)} errors/sec)`
        };
    }

    if (dropRate > 10) {
        return {
            status: "warning",
            reason:
                `Packet drops detected (${dropRate.toFixed(2)} drops/sec)`
        };
    }


    /*
     * HEALTHY
     */

    return {
        status: "healthy",
        reason: "No network errors or packet drops detected"
    };
}


/* =========================
   NETWORK HEALTH
   ========================= */

function getNetworkHealth(interfaces, elapsed) {

    const statuses = [];

    for (const iface of interfaces) {

        const previous = previousInterfaces
            ? previousInterfaces.find(
                item => item.name === iface.name
            )
            : null;

        const delta = calculateInterfaceDelta(
            iface,
            previous,
            elapsed
        );

        const health = getInterfaceHealth(delta);

        statuses.push({
            name: iface.name,
            health: health
        });
    }

    if (statuses.some(item => item.health.status === "critical")) {

        const bad = statuses.find(
            item => item.health.status === "critical"
        );

        return {
            status: "critical",
            reason: `${bad.name}: ${bad.health.reason}`
        };
    }

    if (statuses.some(item => item.health.status === "warning")) {

        const bad = statuses.find(
            item => item.health.status === "warning"
        );

        return {
            status: "warning",
            reason: `${bad.name}: ${bad.health.reason}`
        };
    }

    if (statuses.some(item => item.health.status === "healthy")) {

        return {
            status: "healthy",
            reason: "All network interfaces are operating normally"
        };
    }

    return {
        status: "unknown",
        reason: "Waiting for network statistics"
    };
}


/* =========================
   OVERALL HEALTH
   ========================= */

function worstHealth(statuses) {

    const priority = {
        critical: 3,
        warning: 2,
        unknown: 1,
        healthy: 0
    };

    let worst = statuses[0];

    for (const status of statuses) {

        if (priority[status.status] > priority[worst.status]) {
            worst = status;
        }
    }

    return worst;
}


/* =========================
   UI
   ========================= */

function setHealthIndicator(id, status, reason) {

    const element = document.getElementById(id);

    if (!element) {
        return;
    }

    element.textContent = status.toUpperCase();
    element.className = status;

    /*
     * Store the explanation directly on the element.
     * We'll use this for the tooltip for now.
     */

    element.title = reason;
}


function setHealthStatus(status, reason) {

    const element = document.getElementById("health-status");

    if (!element) {
        return;
    }

    element.textContent = status.toUpperCase();
    element.className = `health-badge ${status}`;

    element.title = reason;
}

/* =========================
   START
   ========================= */

console.log("🔥 Starting dashboard...");

updateDashboard()
    .then(() => {
        console.log("🔥 updateDashboard finished");
    })
    .catch((error) => {
        console.error("🔥 updateDashboard crashed:", error);
    });

setInterval(() => {
    console.log("🔥 Interval tick");
    updateDashboard();
}, 2000);