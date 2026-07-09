const jwt = require('jsonwebtoken');
const { config } = require('./config');

/** @type {Map<number, Set<string>>} userId → active socket IDs */
const userSockets = new Map();

let ioInstance = null;

const fieldRoom = (fieldId) => `field:${Number(fieldId)}`;
const stadiumRoom = (stadiumId) => `stadium:${Number(stadiumId)}`;

function registerSocket(userId, socketId) {
  const id = Number(userId);
  if (!userSockets.has(id)) userSockets.set(id, new Set());
  userSockets.get(id).add(socketId);
}

function unregisterSocket(userId, socketId) {
  const id = Number(userId);
  const sockets = userSockets.get(id);
  if (!sockets) return;
  sockets.delete(socketId);
  if (sockets.size === 0) userSockets.delete(id);
}

function initSocketHandler(io) {
  ioInstance = io;

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('Authentication required'));

    try {
      socket.user = jwt.verify(token, config.jwtSecret);
      return next();
    } catch {
      return next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = Number(socket.user.id);
    registerSocket(userId, socket.id);

    socket.emit('connected', { userId, socketId: socket.id });

    socket.on('joinField', (fieldId) => {
      const room = fieldRoom(fieldId);
      socket.join(room);
      socket.data.joinedFieldId = Number(fieldId);
    });

    socket.on('leaveField', (fieldId) => {
      socket.leave(fieldRoom(fieldId));
      if (socket.data.joinedFieldId === Number(fieldId)) {
        socket.data.joinedFieldId = null;
      }
    });

    socket.on('joinStadium', (stadiumId) => {
      const room = stadiumRoom(stadiumId);
      socket.join(room);
      socket.data.joinedStadiumId = Number(stadiumId);
    });

    socket.on('leaveStadium', (stadiumId) => {
      socket.leave(stadiumRoom(stadiumId));
      if (socket.data.joinedStadiumId === Number(stadiumId)) {
        socket.data.joinedStadiumId = null;
      }
    });

    socket.on('disconnect', () => {
      unregisterSocket(userId, socket.id);
    });
  });
}

function emitToUser(userId, event, payload) {
  if (!ioInstance) return false;

  const sockets = userSockets.get(Number(userId));
  if (!sockets || sockets.size === 0) return false;

  for (const socketId of sockets) {
    ioInstance.to(socketId).emit(event, payload);
  }
  return true;
}

function emitToRoom(room, event, payload) {
  if (!ioInstance) return false;
  ioInstance.to(room).emit(event, payload);
  return true;
}

function getConnectedUserIds() {
  return [...userSockets.keys()];
}

module.exports = {
  initSocketHandler,
  emitToUser,
  emitToRoom,
  getConnectedUserIds,
  fieldRoom,
  stadiumRoom,
};
