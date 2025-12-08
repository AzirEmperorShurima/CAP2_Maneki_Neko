import app from "./app.js";
import os from "os";
import { createHealthCheckRoute, initKeepAliveCron } from "./src/services/self_ping.js";

const port = app.get("port");
createHealthCheckRoute(app);
app.listen(port, () => {
  const env = process.env.NODE_ENV || "development";
  const pid = process.pid;
  const now = new Date().toLocaleString();
  const localUrl = `http://localhost:${port}`;
  const lanIP = (() => {
    const nets = os.networkInterfaces();
    for (const name of Object.keys(nets)) {
      for (const net of nets[name] || []) {
        if (net.family === "IPv4" && !net.internal) return net.address;
      }
    }
    return null;
  })();
  const networkUrl = lanIP ? `http://${lanIP}:${port}` : "N/A";
  const c = { r: "\x1b[0m", b: "\x1b[1m", m: "\x1b[35m", c: "\x1b[36m", g: "\x1b[32m", y: "\x1b[33m" };
  const lines = [
    `${c.b}${c.m}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${c.r}`,
    `${c.m}┃${c.r} ${c.b}${c.c}Server Ready${c.r} ${c.y}(${env})${c.r}               ${c.m}┃${c.r}`,
    `${c.m}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${c.r}`,
    `${c.m}┃${c.r} ${c.g}Local${c.r}   ${c.c}${localUrl}${c.r}             ${c.m}┃${c.r}`,
    `${c.m}┃${c.r} ${c.g}Network${c.r} ${c.c}${networkUrl}${c.r}             ${c.m}┃${c.r}`,
    `${c.m}┃${c.r} ${c.g}PID${c.r}     ${c.c}${pid}${c.r}   ${c.g}Time${c.r} ${c.c}${now}${c.r} ${c.m}┃${c.r}`,
    `${c.m}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${c.r}`
  ];
  console.log("\n" + lines.join("\n") + "\n");
  initKeepAliveCron();
});