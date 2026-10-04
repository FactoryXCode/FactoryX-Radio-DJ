'use strict';

const $ = id => document.getElementById(id);
const els = {
  badge:$('connectionBadge'), alarm:$('alarmPanel'), alarmKind:$('alarmKind'), alarmTitle:$('alarmTitle'), alarmText:$('alarmText'),
  ack:$('ackButton'), overall:$('overallText'), detail:$('overallDetail'), pulse:$('pulse'), recorder:$('recorderState'), host:$('recorderHost'),
  stream:$('streamState'), session:$('streamSession'), disk:$('diskState'), free:$('diskFree'), age:$('heartbeatAge'), time:$('heartbeatTime'),
  enable:$('enableButton'), install:$('installButton'), permissionHelp:$('permissionHelp'), eventSubject:$('eventSubject'), eventTime:$('eventTime')
};
let latest = null, lastFetch = 0, alarmsEnabled = localStorage.getItem('fxalert-enabled') === '1', installPrompt = null, audio = null, alarmTimer = 0, syntheticAlert = '';
const STALE_SECONDS = 20;

function words(value){ return String(value || 'unknown').replace(/[-_]/g,' ').replace(/^./, c => c.toUpperCase()); }
function when(value){ const d = new Date(value); return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString(); }
function setClass(el, base, state){ el.className = `${base} ${state}`; }
function heartbeatAge(){ return latest ? Math.max(0, Math.floor((Date.now() - new Date(latest.heartbeatUtc).getTime()) / 1000)) : Infinity; }
function severity(){
  if (!latest || heartbeatAge() > STALE_SECONDS) return 'critical';
  return ['ok','warning','critical','stopped'].includes(latest.state) ? (latest.state === 'stopped' ? 'critical' : latest.state) : 'warning';
}
function activeAlert(){
  if (!latest || heartbeatAge() > STALE_SECONDS) return {id:`heartbeat-${latest?.heartbeatUtc || 'none'}`, severity:'critical', subject:'FxRecord heartbeat lost', message:'FxRecord is no longer reporting. Check the recorder server now.'};
  if ((latest.state === 'warning' || latest.state === 'critical' || latest.state === 'stopped')) {
    const a = latest.alert || {};
    return {id:a.id || `${latest.state}-${latest.heartbeatUtc}`, severity:latest.state === 'stopped' ? 'critical' : latest.state, subject:a.subject || `FxRecord is ${latest.state}`, message:a.message || 'Open FxRecord on the server for details.'};
  }
  return null;
}
function acknowledged(id){ return localStorage.getItem('fxalert-ack') === id; }

function render(){
  const age = heartbeatAge(), state = severity(), alert = activeAlert();
  setClass(els.badge,'badge',state); els.badge.textContent = !latest ? 'No connection' : state === 'ok' ? 'Online' : words(state);
  setClass(els.pulse,'pulse',state);
  els.overall.textContent = state === 'ok' ? 'Everything is running' : state === 'warning' ? 'Check FxRecord' : 'Action is required';
  els.detail.textContent = !latest ? 'The status feed could not be read.' : age > STALE_SECONDS ? `The last heartbeat is ${age} seconds old.` : state === 'ok' ? 'Recorder, stream monitor and archive disk report normally.' : 'One or more checks need attention.';
  els.recorder.textContent = !latest ? 'Unavailable' : age > STALE_SECONDS ? 'Not responding' : latest.recordingActive ? 'Recording' : words(latest.state);
  els.host.textContent = latest?.recordingActive && latest?.recordingFile ? latest.recordingFile.split(/[\\/]/).pop() : (latest?.computer || '—'); els.stream.textContent = words(latest?.streamState);
  els.session.textContent = latest?.sessionId ? `Session ${latest.sessionId}` : 'No active session';
  els.disk.textContent = words(latest?.diskState); els.free.textContent = Number(latest?.diskFreeGB) >= 0 ? `${Number(latest.diskFreeGB).toFixed(1)} GB free` : 'Free space unavailable';
  els.age.textContent = Number.isFinite(age) ? `${age} sec ago` : 'No heartbeat'; els.time.textContent = latest ? when(latest.heartbeatUtc) : '—';
  if (latest?.alert?.subject) { els.eventSubject.textContent = latest.alert.subject; els.eventTime.textContent = when(latest.alert.createdUtc); }
  if (alert && !acknowledged(alert.id)) { els.alarm.classList.remove('hidden'); els.alarmKind.textContent = `${words(alert.severity)} alert`; els.alarmTitle.textContent = alert.subject; els.alarmText.textContent = alert.message; triggerAlarm(alert); }
  else { els.alarm.classList.add('hidden'); stopAlarm(); }
  els.enable.textContent = alarmsEnabled ? 'Alerts enabled' : 'Enable alerts';
}

async function poll(){
  try {
    const response = await fetch(`status.json?t=${Date.now()}`, {cache:'no-store'});
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    latest = await response.json(); lastFetch = Date.now(); syntheticAlert = '';
  } catch (error) {
    if (!syntheticAlert) syntheticAlert = String(error);
    if (Date.now() - lastFetch > STALE_SECONDS * 1000) latest = null;
  }
  render();
}

function ensureAudio(){
  if (!audio) audio = new (window.AudioContext || window.webkitAudioContext)();
  if (audio.state === 'suspended') audio.resume();
}
function beep(frequency=880, duration=.18){
  if (!alarmsEnabled || !audio) return;
  const osc=audio.createOscillator(), gain=audio.createGain(), now=audio.currentTime;
  osc.frequency.value=frequency; osc.type='square'; gain.gain.setValueAtTime(.0001,now); gain.gain.exponentialRampToValueAtTime(.15,now+.02); gain.gain.exponentialRampToValueAtTime(.0001,now+duration);
  osc.connect(gain).connect(audio.destination); osc.start(now); osc.stop(now+duration+.03);
}
async function notify(alert){
  if (!alarmsEnabled || Notification.permission !== 'granted') return;
  const reg = await navigator.serviceWorker?.ready;
  if (reg) reg.showNotification(alert.subject,{body:alert.message,icon:'../icons/icon-192.png',badge:'../icons/icon-192.png',tag:`fxalert-${alert.id}`,renotify:true});
}
function triggerAlarm(alert){
  if (!alarmsEnabled || window.currentAlertId === alert.id) return;
  window.currentAlertId = alert.id; ensureAudio(); beep(alert.severity === 'critical' ? 920 : 680,.25); notify(alert);
  clearInterval(alarmTimer); alarmTimer=setInterval(() => beep(alert.severity === 'critical' ? 920 : 680,.22), alert.severity === 'critical' ? 4000 : 12000);
}
function stopAlarm(){ clearInterval(alarmTimer); alarmTimer=0; window.currentAlertId=''; }

els.ack.addEventListener('click', () => { const alert=activeAlert(); if(alert) localStorage.setItem('fxalert-ack',alert.id); stopAlarm(); render(); });
els.enable.addEventListener('click', async () => {
  ensureAudio(); alarmsEnabled=true; localStorage.setItem('fxalert-enabled','1');
  if ('Notification' in window && Notification.permission === 'default') await Notification.requestPermission();
  const notificationsAllowed = 'Notification' in window && Notification.permission === 'granted';
  els.permissionHelp.textContent = notificationsAllowed ? 'Sound and system notifications are enabled.' : 'Sound is enabled. Browser notifications are not allowed.';
  render();
});
window.addEventListener('beforeinstallprompt', event => { event.preventDefault(); installPrompt=event; els.install.classList.remove('hidden'); });
els.install.addEventListener('click', async () => { if(installPrompt){ installPrompt.prompt(); await installPrompt.userChoice; installPrompt=null; els.install.classList.add('hidden'); } });

if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js');
if (alarmsEnabled) els.permissionHelp.textContent='Alerts were enabled on this device. Tap the button again if sound is blocked.';
poll(); setInterval(poll,5000); setInterval(render,1000);
