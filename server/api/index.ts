import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { WsAdapter } from '@nestjs/platform-ws';
import express from 'express';
import { createServer } from 'http';
import { AppModule } from '../dist/app.module';

const expressApp = express();
const httpServer = createServer(expressApp);
let isInitialized = false;

async function bootstrap() {
  if (!isInitialized) {
    const adapter = new ExpressAdapter(expressApp);
    adapter.setHttpServer(httpServer);

    const app = await NestFactory.create(AppModule, adapter);
    app.useWebSocketAdapter(new WsAdapter(app));
    app.enableCors();
    await app.init();
    isInitialized = true;
  }
  return httpServer;
}

export default async function handler(req: any, res: any) {
  const server = await bootstrap();
  if (req.headers.upgrade?.toLowerCase() === 'websocket') {
    server.emit('upgrade', req, req.socket, Buffer.alloc(0));
  } else {
    server.emit('request', req, res);
  }
}
