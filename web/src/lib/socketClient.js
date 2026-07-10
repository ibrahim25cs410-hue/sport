import { io } from 'socket.io-client';
import { API_BASE, storage } from '../api';

const SOCKET_URL = API_BASE.replace(/\/api\/?$/, '');

let socket = null;
let joinedFieldId = null;
let refCount = 0;

function ensureSocket() {
  const session = storage.getSession();
  if (!session?.token) return null;

  if (socket?.connected || socket?.active) return socket;

  socket = io(SOCKET_URL, {
    auth: { token: session.token },
    transports: ['websocket'],
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 2000,
  });

  socket.on('connect', () => {
    if (joinedFieldId) socket.emit('joinField', joinedFieldId);
  });

  socket.on('connect_error', (err) => {
    console.warn('[Socket] connect failed — polling fallback', err?.message || err);
  });

  return socket;
}

export function acquireSocket() {
  refCount += 1;
  return ensureSocket();
}

export function releaseSocket() {
  refCount = Math.max(0, refCount - 1);
  if (refCount === 0 && socket) {
    socket.disconnect();
    socket = null;
    joinedFieldId = null;
  }
}

export function getSocket() {
  return socket;
}

export function joinField(fieldId) {
  const id = Number(fieldId);
  if (!id) return;
  joinedFieldId = id;
  ensureSocket()?.emit('joinField', id);
}

export function leaveField(fieldId) {
  const id = Number(fieldId);
  if (joinedFieldId === id) joinedFieldId = null;
  socket?.emit('leaveField', id);
}
