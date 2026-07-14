import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, WebSocket } from 'ws';
import { DeepgramService, DeepgramSession } from './deepgram.service';
import {
  ConversationSession,
  createSession,
  getGreeting,
  processTranscript,
  ConvoState,
} from './conversation.fsm';

interface ClientSession {
  convo: ConversationSession;
  deepgram: DeepgramSession | null;
}

@WebSocketGateway({ path: '/voice/stream', cors: { origin: '*' } })
export class VoiceGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(VoiceGateway.name);
  private clients = new Map<string, ClientSession>();

  constructor(private readonly deepgramService: DeepgramService) {}

  async handleConnection(client: WebSocket, req: any) {
    const clientId = this.generateId();
    (client as any).__clientId = clientId;
    this.logger.log(`Client connected: ${clientId}`);

    const session: ClientSession = {
      convo: createSession(clientId, 'there'),
      deepgram: null,
    };
    this.clients.set(clientId, session);

    // Attach raw message handler for both binary and text frames
    client.on('message', (data: Buffer | string, isBinary: boolean) => {
      if (isBinary) {
        this.handleAudioChunk(client, data as Buffer);
      } else {
        this.handleTextMessage(client, data.toString());
      }
    });

    // Send greeting
    try {
      const greeting = getGreeting(session.convo);
      const audioBuffer = await this.deepgramService.synthesizeSpeech(greeting.text);
      this.sendAudioResponse(client, audioBuffer);
      this.sendJson(client, { type: 'state_change', state: greeting.state });
    } catch (err) {
      this.logger.error('Failed to send greeting', err);
    }
  }

  handleDisconnect(client: WebSocket) {
    const clientId = (client as any).__clientId;
    this.logger.log(`Client disconnected: ${clientId}`);
    const session = this.clients.get(clientId);
    if (session?.deepgram) {
      this.deepgramService.closeSession(session.deepgram);
    }
    this.clients.delete(clientId);
  }

  private handleTextMessage(client: WebSocket, raw: string) {
    let msg: any;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }

    const clientId = (client as any).__clientId;
    const session = this.clients.get(clientId);
    if (!session) return;

    switch (msg.event) {
      case 'set_user':
        if (msg.data?.name) {
          session.convo.userName = msg.data.name;
        }
        break;
      case 'close_stream':
        if (session.deepgram) {
          this.deepgramService.closeSession(session.deepgram);
          session.deepgram = null;
        }
        break;
      case 'cancel':
        if (session.deepgram) {
          this.deepgramService.closeSession(session.deepgram);
          session.deepgram = null;
        }
        this.clients.delete(clientId);
        break;
    }
  }

  private async handleAudioChunk(client: WebSocket, chunk: Buffer) {
    const clientId = (client as any).__clientId;
    const session = this.clients.get(clientId);
    if (!session) return;

    if (!session.deepgram) {
      try {
        session.deepgram = await this.deepgramService.createSttSession(
          (text: string, isFinal: boolean) => {
            this.sendJson(client, { type: 'transcript', text, isFinal });
            if (isFinal) {
              this.handleTranscript(client, text);
            }
          },
          () => {
            this.logger.debug(`Utterance end for client ${clientId}`);
          },
        );
      } catch (err) {
        this.logger.error('Failed to create Deepgram STT session', err);
        return;
      }
    }

    try {
      session.deepgram.socket.sendMedia(chunk);
    } catch (err) {
      this.logger.error('Failed to send audio chunk to Deepgram', err);
    }
  }

  private async handleTranscript(client: WebSocket, transcript: string) {
    const clientId = (client as any).__clientId;
    const session = this.clients.get(clientId);
    if (!session) return;

    const result = processTranscript(session.convo, transcript);
    if (!result) return;

    if (result.state === ConvoState.SAVING) {
      try {
        const audioBuffer = await this.deepgramService.synthesizeSpeech(result.text);
        this.sendAudioResponse(client, audioBuffer);
        this.sendJson(client, {
          type: 'task_created',
          task: {
            title: session.convo.taskTitle,
            dueDate: session.convo.dueDate?.toISOString() ?? null,
            priority: session.convo.priority,
          },
        });
        session.convo.state = ConvoState.DONE;
      } catch (err) {
        this.logger.error('Failed to finalize task', err);
      }
      return;
    }

    try {
      const audioBuffer = await this.deepgramService.synthesizeSpeech(result.text);
      this.sendAudioResponse(client, audioBuffer);
      this.sendJson(client, { type: 'state_change', state: result.state });
    } catch (err) {
      this.logger.error('Failed to synthesize speech', err);
    }
  }

  private sendJson(client: WebSocket, data: any) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  }

  private sendAudioResponse(client: WebSocket, buffer: Buffer) {
    if (client.readyState !== WebSocket.OPEN) return;
    const CHUNK_SIZE = 8192;
    let offset = 0;
    while (offset < buffer.length) {
      const end = Math.min(offset + CHUNK_SIZE, buffer.length);
      const chunk = buffer.slice(offset, end);
      this.sendJson(client, { type: 'audio_chunk', size: chunk.length });
      client.send(chunk);
      offset = end;
    }
    this.sendJson(client, { type: 'audio_end' });
  }

  private generateId(): string {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
  }
}
