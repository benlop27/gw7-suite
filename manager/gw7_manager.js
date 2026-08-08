"use strict";

const CATALOG_URL = "gw7_midi_catalog.json";

let CAT = null;
let state = { midi: null, out: null, in: null };

const $ = id => document.getElementById(id);
const hex = b => ("0" + (b & 0xff).toString(16).toUpperCase()).slice(-2);

function chanSel() { return parseInt($("chan").value, 10); }
function ch0() { return chanSel() - 1; }

function log(text, cls) {
  $("last-msg").textContent = text;
  $("last-msg").className = cls || "";
}
function setStatus(text, cls) {
  $("midi-status").textContent = text;
  $("midi-status").className = "status" + (cls ? " " + cls : "");
}

function sendSysEx(bytes) {
  if (!state.out) return log("No MIDI output selected", "err");
  state.out.send([0xf0, ...bytes, 0xf7]);
  log("TX " + [0xf0, ...bytes, 0xf7].map(hex).join(" "), "tx");
}
function sendCC(cc, v, c = ch0()) {
  if (!state.out) return log("No MIDI output selected", "err");
  state.out.send([0xb0 | c, cc & 0x7f, v & 0x7f]);
  log(`TX ${hex(0xb0 | c)} ${hex(cc)} ${hex(v)}  CC${cc}=${v} ch${c + 1}`, "tx");
}
function sendPC(p, c = ch0()) {
  if (!state.out) return log("No MIDI output selected", "err");
  state.out.send([0xc0 | c, p & 0x7f]);
  log(`TX ${hex(0xc0 | c)} ${hex(p)}  PC${p + 1} ch${c + 1}`, "tx");
}

function loadTone(bank, tone, idx) {
  sendCC(0, tone.cc00);
  sendCC(32, tone.cc32);
  sendPC(tone.pc - 1);
  $("preset-lcd").textContent = `${bank.name} ${String(idx + 1).padStart(3, "0")}`;
  $("preset-name").textContent = `ch${chanSel()} · ${tone.name}`;
}

function buildGrid() {
  const banks = CAT.tone_banks;
  let cur = banks[0].name;
  const tabs = $("bank-tabs");
  const grid = $("tone-grid");
  for (const b of banks) {
    const t = document.createElement("button");
    t.textContent = b.name;
    t.title = b.name;
    t.addEventListener("click", () => { cur = b.name; draw(); });
    tabs.appendChild(t);
  }
  function draw() {
    [...tabs.children].forEach((t, i) => t.classList.toggle("active", banks[i].name === cur));
    grid.replaceChildren();
    const bank = banks.find(b => b.name === cur);
    bank.tones.forEach((tone, idx) => {
      const b = document.createElement("button");
      b.title = `${bank.name} · ${tone.name}`;
      const num = document.createElement("span");
      num.className = "num";
      num.textContent = String(tone.no);
      b.appendChild(num);
      const lab = document.createElement("span");
      lab.className = "nm";
      lab.textContent = tone.name;
      b.appendChild(lab);
      b.addEventListener("click", () => {
        [...grid.children].forEach(x => x.classList.remove("sel"));
        b.classList.add("sel");
        loadTone(bank, tone, idx);
      });
      grid.appendChild(b);
    });
  }
  draw();
}

function parseRx(d) {
  if (d[0] === 0xf0) {
    log("RX " + Array.from(d).map(hex).join(" "), "rx");
    return;
  }
  const st = d[0] & 0xf0, ch = (d[0] & 0x0f) + 1;
  let s = `RX ${Array.from(d).map(hex).join(" ")}`;
  if (st === 0xc0) s += `  ch${ch} Program ${d[1] + 1}`;
  else if (st === 0xb0) s += `  ch${ch} CC${d[1]}=${d[2]}`;
  else s += `  ch${ch} status ${hex(st)}`;
  log(s, "rx");
}

async function connectMidi() {
  if (!navigator.requestMIDIAccess) {
    setStatus("Web MIDI needs Chrome/Edge over http://localhost", "err");
    $("midi-led").className = "led err";
    return;
  }
  try {
    state.midi = await navigator.requestMIDIAccess();
  } catch (e) {
    setStatus("MIDI access denied: " + e.message, "err");
    $("midi-led").className = "led err";
    return;
  }
  state.midi.addEventListener("statechange", populatePorts);
  populatePorts();
  setStatus("Web MIDI ready", "ok");
  $("midi-led").className = "led on";
}
function populatePorts() {
  const inSel = $("in-port"), outSel = $("out-port");
  inSel.replaceChildren(); outSel.replaceChildren();
  for (const p of state.midi.inputs.values())
    inSel.appendChild(new Option(p.name + (p.state === "connected" ? "" : " (disconnected)"), p.id));
  for (const p of state.midi.outputs.values())
    outSel.appendChild(new Option(p.name + (p.state === "connected" ? "" : " (disconnected)"), p.id));
  if (!state.midi.outputs.size) log("No MIDI outputs found — is the GW-7 connected?", "warn");
}
function wirePorts() {
  $("in-port").addEventListener("change", () => {
    if (state.in) state.in.onmidimessage = null;
    const id = $("in-port").value;
    state.in = id ? state.midi.inputs.get(id) : null;
    if (state.in) state.in.onmidimessage = e => parseRx(e.data);
  });
  $("out-port").addEventListener("change", () => {
    const id = $("out-port").value;
    state.out = id ? state.midi.outputs.get(id) : null;
  });
  $("in-port").dispatchEvent(new Event("change"));
  $("out-port").dispatchEvent(new Event("change"));
}

async function main() {
  try {
    const r = await fetch(CATALOG_URL);
    if (!r.ok) throw new Error("HTTP " + r.status);
    CAT = await r.json();
  } catch (e) {
    setStatus("Cannot load catalog — serve over http://localhost", "err");
    return;
  }
  const chan = $("chan");
  for (let i = 1; i <= 16; i++)
    chan.appendChild(new Option(`Ch ${i}${i === 10 ? " (drum)" : ""}`, i));
  buildGrid();
  $("btn-connect").addEventListener("click", async () => { await connectMidi(); wirePorts(); });
  await connectMidi();
  wirePorts();
}

main();
